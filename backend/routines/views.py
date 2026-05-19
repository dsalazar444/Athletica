from django.db import models
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.utils.dateparse import parse_date
from rest_framework import decorators, status, viewsets
from rest_framework.decorators import api_view, permission_classes
from rest_framework.exceptions import PermissionDenied
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from users.models import AthleteProfile, Follow, Goal, User, WeightLog

from .ai_service import generate_exercise_recommendations
from .models import (
    Comment,
    CommentReaction,
    Exercise,
    Reaction,
    Routine,
    RoutineExercise,
    SetLog,
    TrainingGroup,
    WorkoutSession,
)
from .serializers.serializer_recommendation import RecommendationResponseSerializer
from .serializers.serializer_routine import (
    RoutineCreateSerializer,
    RoutineDetailSerializer,
    RoutineExerciseInputSerializer,
)
from .serializers.serializer_social import CommentSerializer
from .serializers.serializer_workout import (
    SetLogSerializer,
    WorkoutHistorySerializer,
    WorkoutSessionSerializer,
)
from .serializers.serializers_exercise import ExerciseSerializer
from .serializers.serializers_groups import TrainingGroupSerializer


class ExerciseViewSet(viewsets.ViewSet):  # NOSONAR
    """
    Gestiona la búsqueda y creación de ejercicios.
    """

    def list(self, request):
        external_id = request.query_params.get("external_id")
        if not external_id:
            return Response({"detail": "Missing external_id."}, status=status.HTTP_400_BAD_REQUEST)

        exists = Exercise.objects.filter(external_id=external_id).exists()
        return Response({"exists": exists})

    def create(self, request):
        serializer = ExerciseSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({"created": True}, status=status.HTTP_201_CREATED)
        return Response(
            {"created": False, "errors": serializer.errors},
            status=status.HTTP_400_BAD_REQUEST,
        )


class RoutineViewSet(viewsets.ModelViewSet):  # NOSONAR
    """
    ViewSet para gestionar Rutinas: listar, crear, detalle, eliminar y acciones personalizadas.
    """

    permission_classes = [IsAuthenticated]
    queryset = Routine.objects.all().prefetch_related("routine_exercises__exercise")

    def get_serializer_class(self):
        if self.action == "create":
            return RoutineCreateSerializer
        return RoutineDetailSerializer

    def get_queryset(self):
        # El usuario solo ve sus propias rutinas en el listado general
        if self.action == "list":
            return self.queryset.filter(created_by=self.request.user)
        return self.queryset

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        if instance.created_by != request.user:
            return Response(
                {"detail": "No tienes permiso para borrar esta rutina."},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().destroy(request, *args, **kwargs)

    @decorators.action(
        detail=False, methods=["get"], url_path="public", permission_classes=[AllowAny]
    )
    def get_public_routines(self, request):
        """Lista todas las rutinas públicas.

        Ruta: GET /api/routines/public/
        Devuelve la lista de rutinas cuyo campo `is_public` es True.
        """
        routines = (
            self.queryset.filter(is_public=True)
            .select_related("created_by")
            .prefetch_related("assigned_athletes")
        )

        if request.query_params.get("mine") == "true" and request.user.is_authenticated:
            routines = routines.filter(created_by=request.user)

        if request.user.is_authenticated:
            follow_subquery = Follow.objects.filter(
                follower_id=request.user.id, following_id=models.OuterRef("created_by_id")
            )
            routines = routines.annotate(is_followed_by_request_user=models.Exists(follow_subquery))
        else:
            routines = routines.annotate(
                is_followed_by_request_user=models.Value(False, output_field=models.BooleanField())
            )

        serializer = self.get_serializer(routines, many=True)
        return Response(serializer.data)

    @decorators.action(detail=True, methods=["patch"])
    def add_exercises(self, request, pk=None):
        """Action personalizada para añadir ejercicios a una rutina existente."""
        routine = self.get_object()
        if routine.created_by != request.user:
            return Response({"detail": "Permiso denegado."}, status=status.HTTP_403_FORBIDDEN)

        exercises_data = request.data.get("exercises", [])
        serializer = RoutineExerciseInputSerializer(data=exercises_data, many=True)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        current_max_order = (
            routine.routine_exercises.aggregate(models.Max("order"))["order__max"] or 0
        )
        new_exercises = [
            RoutineExercise(
                routine=routine,
                exercise=item["external_id"],
                order=current_max_order + i + 1,
            )
            for i, item in enumerate(serializer.validated_data)
        ]
        RoutineExercise.objects.bulk_create(new_exercises)
        return Response(self.get_serializer(routine).data)

    @decorators.action(detail=True, methods=["post"], url_path="assign")
    def assign_to_athletes(self, request, pk=None):
        """Asigna la rutina a varios atletas."""
        if request.user.role != "coach":
            return Response(
                {"detail": "Solo coaches pueden asignar."},
                status=status.HTTP_403_FORBIDDEN,
            )

        routine = self.get_object()
        if routine.created_by != request.user:
            return Response(
                {"detail": "No tienes permiso para asignar esta rutina."},
                status=status.HTTP_403_FORBIDDEN,
            )

        athlete_ids = set(request.data.get("athlete_ids", []))
        group_ids = request.data.get("group_ids", [])

        # Si se proporcionan grupos, sumar sus miembros a la lista de atletas
        if group_ids:
            members_from_groups = User.objects.filter(
                training_group_memberships__id__in=group_ids, role="athlete"
            ).values_list("id", flat=True)
            athlete_ids.update(members_from_groups)

        if not athlete_ids:
            return Response(
                {"detail": "Proporcione athlete_ids o group_ids con miembros."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Obtener los objetos de usuario finales
        athletes = User.objects.filter(id__in=athlete_ids, role="athlete")

        for athlete in athletes:
            # Regla de negocio: Un atleta solo puede tener una rutina activa a la vez.
            # Quitamos al atleta de cualquier otra rutina donde esté asignado.
            for r in Routine.objects.filter(assigned_athletes=athlete):
                r.assigned_athletes.remove(athlete)

            # Asignar la nueva rutina
            routine.assigned_athletes.add(athlete)

        return Response({"detail": f"Rutina asignada a {athletes.count()} atletas."})

    @decorators.action(
        detail=False, methods=["get"], url_path="athlete/(?P<athlete_id>[^/.]+)/active"
    )
    def active_routine(self, request, athlete_id=None):
        """Obtiene la rutina activa de un atleta específico."""
        routine = Routine.objects.filter(assigned_athletes__id=athlete_id).first()
        if not routine:
            return Response({"detail": "Sin rutina asignada."}, status=status.HTTP_404_NOT_FOUND)
        return Response(self.get_serializer(routine).data)

    @decorators.action(
        detail=True, methods=["delete"], url_path="exercises/(?P<exercise_id>[^/.]+)"
    )
    def remove_exercise(self, request, pk=None, exercise_id=None):
        """Quita un ejercicio de la rutina."""
        routine = self.get_object()
        deleted, _ = RoutineExercise.objects.filter(
            routine=routine, exercise_id=exercise_id
        ).delete()
        if deleted:
            return Response(status=status.HTTP_204_NO_CONTENT)
        return Response({"detail": "No encontrado."}, status=status.HTTP_404_NOT_FOUND)

    @decorators.action(detail=True, methods=["get", "post"], permission_classes=[IsAuthenticated])
    def comments(self, request, pk=None):
        """Lista o crea comentarios en una rutina. GET /api/routines/<id>/comments/"""
        routine = self.get_object()

        if request.method == "GET":
            qs = routine.comments.filter(parent=None).prefetch_related(
                "replies__reactions", "reactions"
            )
            serializer = CommentSerializer(qs, many=True, context={"request": request})
            return Response(serializer.data)

        serializer = CommentSerializer(data=request.data, context={"request": request})
        if serializer.is_valid():
            parent_id = request.data.get("parent")
            parent = None
            if parent_id:
                parent = get_object_or_404(Comment, id=parent_id, routine=routine)
            serializer.save(user=request.user, routine=routine, parent=parent)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @decorators.action(detail=True, methods=["post"], permission_classes=[IsAuthenticated])
    def react(self, request, pk=None):
        """Alterna la reacción (like) del usuario en una rutina. POST /api/routines/<id>/react/"""
        routine = self.get_object()
        reaction_type = request.data.get("reaction_type", Reaction.ReactionType.LIKE)
        reaction, created = Reaction.objects.get_or_create(
            user=request.user, routine=routine, reaction_type=reaction_type
        )
        if not created:
            reaction.delete()
            return Response({"reacted": False, "likes_count": routine.reactions.count()})
        return Response(
            {"reacted": True, "likes_count": routine.reactions.count()},
            status=status.HTTP_201_CREATED,
        )


class WorkoutSessionViewSet(viewsets.ModelViewSet):  # NOSONAR
    """
    Gestiona las sesiones de entrenamiento y el historial.
    """

    permission_classes = [IsAuthenticated]
    serializer_class = WorkoutSessionSerializer

    def get_queryset(self):
        return WorkoutSession.objects.filter(user=self.request.user).order_by("-date")

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            user = request.user
            routine = serializer.validated_data["routine"]
            date = serializer.validated_data.get("date", timezone.now())

            # Reutilizar sesión si es el mismo día
            existing = WorkoutSession.objects.filter(
                user=user, routine=routine, date__date=date.date()
            ).first()
            if existing:
                return Response(self.get_serializer(existing).data)

            return super().create(request, *args, **kwargs)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @decorators.action(detail=False, methods=["get"], url_path="history")
    def history_range(self, request):
        """Filtra historial por rango de fechas."""
        start_param = request.query_params.get("start_date")
        end_param = request.query_params.get("end_date")

        if not (start_param and end_param):
            return Response({"detail": "Params missing."}, status=status.HTTP_400_BAD_REQUEST)

        start_date = parse_date(start_param)
        end_date = parse_date(end_param)

        if not (start_date and end_date):
            return Response({"detail": "Invalid dates."}, status=status.HTTP_400_BAD_REQUEST)

        sessions = (
            self.get_queryset()
            .filter(date__date__range=(start_date, end_date))
            .select_related("routine")
        )

        class CustomPagination(PageNumberPagination):
            page_size_query_param = "page_size"

        paginator = CustomPagination()
        paginator.page_size = 10
        page = paginator.paginate_queryset(sessions, request)
        serializer = WorkoutHistorySerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)


class SetLogViewSet(viewsets.ModelViewSet):  # NOSONAR
    permission_classes = [IsAuthenticated]
    serializer_class = SetLogSerializer
    queryset = SetLog.objects.all()

    @decorators.action(
        detail=False, methods=["get"], url_path="exercise/(?P<exercise_id>[^/.]+)/last"
    )
    def last_for_exercise(self, request, exercise_id=None):
        last_log = SetLog.objects.filter(exercise_id=exercise_id).order_by("-session__date")
        if not last_log.exists():
            return Response({"detail": "No records."}, status=status.HTTP_404_NOT_FOUND)

        last_session_id = last_log.first().session_id
        sets = last_log.filter(session_id=last_session_id)
        return Response(SetLogSerializer(sets, many=True).data)

    @decorators.action(
        detail=False,
        methods=["get"],
        url_path="exercise/(?P<exercise_id>[^/.]+)/history",
    )
    def exercise_history(self, request, exercise_id=None):
        logs = (
            SetLog.objects.filter(exercise_id=exercise_id)
            .select_related("session")
            .order_by("-session__date")
        )
        history = {}
        for log in logs:
            date_str = log.session.date.strftime("%Y-%m-%d")
            if date_str not in history:
                history[date_str] = {"date": date_str, "sets": []}
            history[date_str]["sets"].append(SetLogSerializer(log).data)
        return Response(list(history.values()))


class TrainingGroupViewSet(viewsets.ModelViewSet):  # NOSONAR
    serializer_class = TrainingGroupSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Solo devuelve los grupos del coach autenticado
        return TrainingGroup.objects.filter(coach=self.request.user)

    def perform_create(self, serializer):
        # Asigna automáticamente el coach al crear
        serializer.save(coach=self.request.user)

    def initial(self, request, *args, **kwargs):
        # Verifica que el usuario sea coach antes de cualquier acción
        super().initial(request, *args, **kwargs)
        if request.user.role != "coach":
            raise PermissionDenied("Solo los coaches pueden gestionar grupos.")


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def GroupDashboardView(request, group_id):
    """Tablero de métricas de los atletas de un grupo."""
    if request.user.role != "coach":
        return Response(
            {"detail": "Solo los entrenadores pueden ver este tablero."},
            status=status.HTTP_403_FORBIDDEN,
        )

    group = get_object_or_404(TrainingGroup, id=group_id, coach=request.user)
    print(f">>> group_id={group_id}, grupo={group.name}, miembros={group.members.count()}")

    athletes_data = []
    for member in group.members.all():
        print(f"Procesando: {member.username}")
        try:
            profile = AthleteProfile.objects.get(user=member)
            print(f"  Profile encontrado: {profile}")
        except AthleteProfile.DoesNotExist:
            print(f"  SIN PROFILE - saltando {member.username}")
            continue
        except Exception as e:
            print(f"  ERROR inesperado: {e} para {member.username}")
            continue

        # Último peso y tendencia
        weight_logs = WeightLog.objects.filter(athlete=profile).order_by("-id")[:2]
        latest_weight = None
        weight_trend = "no_data"

        if weight_logs:
            latest_weight = {
                "weight": weight_logs[0].weight,
                "date": weight_logs[0].date,
                "body_fat": weight_logs[0].body_fat,
            }
            if len(weight_logs) == 2:
                diff = weight_logs[0].weight - weight_logs[1].weight
                if diff > 0:
                    weight_trend = "up"
                elif diff < 0:
                    weight_trend = "down"
                else:
                    weight_trend = "stable"

        # Meta activa
        active_goal = (
            Goal.objects.filter(athlete=profile, is_active=True).order_by("-start_date").first()
        )
        goal_data = None
        if active_goal:
            goal_data = {
                "id": active_goal.id,
                "goal_type": active_goal.goal_type,
                "target_value": active_goal.target_value,
                "current_value": active_goal.current_value,
                "deadline": active_goal.deadline,
            }

        athletes_data.append(
            {
                "id": member.id,
                "username": member.username,
                "first_name": member.first_name,
                "email": member.email,
                "age": profile.age,
                "gender": profile.gender,
                "activity_level": profile.activity_level,
                "latest_weight": latest_weight,
                "weight_trend": weight_trend,
                "active_goal": goal_data,
            }
        )

    total_with_goal = sum(1 for a in athletes_data if a["active_goal"] is not None)
    total_with_weight = sum(1 for a in athletes_data if a["latest_weight"] is not None)
    weights = [
        a["latest_weight"]["weight"] for a in athletes_data if a["latest_weight"] is not None
    ]
    avg_weight = round(sum(weights) / len(weights), 1) if weights else None
    total_with_routine = (
        Routine.objects.filter(assigned_athletes__in=group.members.all())
        .values("assigned_athletes")
        .distinct()
        .count()
    )

    return Response(
        {
            "group_id": group.id,
            "group_name": group.name,
            "total_members": len(athletes_data),
            "group_metrics": {
                "total_with_goal": total_with_goal,
                "total_with_routine": total_with_routine,
                "total_with_weight_data": total_with_weight,
                "avg_weight": avg_weight,
            },
            "athletes": athletes_data,
        }
    )


class ExerciseRecommendationView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        try:
            profile = user.athleteprofile
        except AthleteProfile.DoesNotExist:
            return Response(
                {"detail": "User must be an athlete with a profile to get recommendations."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Get history
        history = WorkoutSession.objects.filter(user=user).order_by("-date")[:5]

        # Get all exercises to choose from
        available_exercises = Exercise.objects.all()
        if not available_exercises.exists():
            return Response(
                {"detail": "No exercises available in database."}, status=status.HTTP_404_NOT_FOUND
            )

        # Call AI Service
        ai_recommendations = generate_exercise_recommendations(
            profile, history, available_exercises
        )
        print(f"DEBUG: AI recommendations raw: {ai_recommendations}")

        # Enrich with DB data (IDs, URLs)
        enriched_data = []
        for item in ai_recommendations:
            exercise_name = item.get("exercise_name")
            db_ex = Exercise.objects.filter(name__icontains=exercise_name).first()
            enriched_data.append(
                {
                    "exercise_name": exercise_name,
                    "reason": item.get("reason"),
                    "image_url": db_ex.image_url if db_ex else "",
                    "exercise_id": db_ex.id if db_ex else None,
                    "muscle": db_ex.muscle if db_ex else "General",
                    "sets": item.get("sets", 3),
                    "reps": item.get("reps", "12"),
                    "rest": item.get("rest", 60),
                    "instructions": item.get("instructions", ""),
                    "youtube_id": item.get("youtube_id", ""),
                }
            )

        response_data = {"recommendations": enriched_data, "generated_at": timezone.now()}

        # Usamos el serializador para formatear la salida correctamente
        serializer = RecommendationResponseSerializer(response_data)
        return Response(serializer.data)


@api_view(["DELETE"])
@permission_classes([IsAuthenticated])
def delete_comment(request, comment_id):
    """Elimina un comentario propio. DELETE /api/comments/<id>/"""
    comment = get_object_or_404(Comment, id=comment_id)
    if comment.user != request.user:
        return Response({"detail": "No tienes permiso."}, status=status.HTTP_403_FORBIDDEN)
    comment.delete()
    return Response(status=status.HTTP_204_NO_CONTENT)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def comment_react(request, comment_id):
    """Alterna la reacción (like) del usuario en un comentario. POST /api/comments/<id>/react/"""
    comment = get_object_or_404(Comment, id=comment_id)
    reaction, created = CommentReaction.objects.get_or_create(user=request.user, comment=comment)
    if not created:
        reaction.delete()
        return Response({"reacted": False, "likes_count": comment.reactions.count()})
    return Response(
        {"reacted": True, "likes_count": comment.reactions.count()},
        status=status.HTTP_201_CREATED,
    )

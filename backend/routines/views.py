from django.db import models
from django.utils import timezone
from django.utils.dateparse import parse_date
from rest_framework import decorators, status, viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from users.models import User

from .models import Exercise, Routine, RoutineExercise, SetLog, WorkoutSession
from .serializers.serializer_routine import (
    RoutineCreateSerializer,
    RoutineDetailSerializer,
    RoutineExerciseInputSerializer,
)
from .serializers.serializer_workout import (
    SetLogSerializer,
    WorkoutHistorySerializer,
    WorkoutSessionSerializer,
)
from .serializers.serializers_exercise import ExerciseSerializer


class ExerciseViewSet(viewsets.ViewSet):
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
        print("=== EXERCISE SERIALIZER ERRORS ===")
        print(f"Data: {request.data}")
        print(f"Errors: {serializer.errors}")
        print("===================================")
        return Response(
            {"created": False, "errors": serializer.errors}, status=status.HTTP_400_BAD_REQUEST
        )


class RoutineViewSet(viewsets.ModelViewSet):
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
                routine=routine, exercise=item["external_id"], order=current_max_order + i + 1
            )
            for i, item in enumerate(serializer.validated_data)
        ]
        RoutineExercise.objects.bulk_create(new_exercises)
        return Response(RoutineDetailSerializer(routine).data)

    @decorators.action(detail=True, methods=["post"], url_path="assign")
    def assign_to_athletes(self, request, pk=None):
        """Asigna la rutina a varios atletas."""
        if request.user.role != "coach":
            return Response(
                {"detail": "Solo coaches pueden asignar."}, status=status.HTTP_403_FORBIDDEN
            )

        routine = self.get_object()
        athlete_ids = request.data.get("athlete_ids", [])
        if not athlete_ids:
            return Response(
                {"detail": "Proporcione athlete_ids."}, status=status.HTTP_400_BAD_REQUEST
            )

        athletes = User.objects.filter(id__in=athlete_ids, role="athlete")
        for athlete in athletes:
            # Limpiar asignaciones previas
            Routine.objects.filter(assigned_athletes=athlete).all()  # Evaluation
            for r in Routine.objects.filter(assigned_athletes=athlete):
                r.assigned_athletes.remove(athlete)
            routine.assigned_athletes.add(athlete)

        return Response({"detail": f"Asignada a {athletes.count()} atletas."})

    @decorators.action(
        detail=False, methods=["get"], url_path="athlete/(?P<athlete_id>[^/.]+)/active"
    )
    def active_routine(self, request, athlete_id=None):
        """Obtiene la rutina activa de un atleta específico."""
        routine = Routine.objects.filter(assigned_athletes__id=athlete_id).first()
        if not routine:
            return Response({"detail": "Sin rutina asignada."}, status=status.HTTP_404_NOT_FOUND)
        return Response(RoutineDetailSerializer(routine).data)

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


class WorkoutSessionViewSet(viewsets.ModelViewSet):
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

        from rest_framework.pagination import PageNumberPagination

        class CustomPagination(PageNumberPagination):
            page_size_query_param = "page_size"

        paginator = CustomPagination()
        paginator.page_size = 10
        page = paginator.paginate_queryset(sessions, request)
        serializer = WorkoutHistorySerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)


class SetLogViewSet(viewsets.ModelViewSet):
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
        detail=False, methods=["get"], url_path="exercise/(?P<exercise_id>[^/.]+)/history"
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

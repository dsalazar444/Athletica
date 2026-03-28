from django.utils import timezone
from django.utils.dateparse import parse_date

# from users.models import User
from rest_framework import generics, status
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Exercise, Routine, SetLog, WorkoutSession
from .serializers.serializer_routine import (
    RoutineCreateSerializer,
    RoutineDetailSerializer,
)
from .serializers.serializer_workout import (
    SetLogSerializer,
    WorkoutHistorySerializer,
    WorkoutSessionSerializer,
)
from .serializers.serializers_exercise import ExerciseSerializer


# Endpoint para buscar ejercicios por nombre y crear ejercicios
# cuando usamos clase APIView, se registra la clase para la url, y django REST dirige automaticamente peticion a mentodo correspondiente de la clase:
# Si la petición es GET, llama al método get().
# Si la petición es POST, llama al método post().
# (Y si tuvieras métodos put(), delete(), etc., los llamaría según el verbo HTTP).
class ExerciseListCreateView(APIView):
    """Class to create or search if a Exercise exits in bd"""

    # buscamos ejercicio por external_id
    def get(self, request):
        external_id = request.query_params.get("external_id")
        if not external_id:
            return Response(
                {"detail": "Missing external id parameter."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        exists = Exercise.objects.filter(external_id=external_id).exists()
        return Response({"exists": exists}, status=status.HTTP_200_OK)

    def post(self, request):
        # intentamos convertir json a modelo
        serializer = ExerciseSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()  # si sí se puede, lo guardamos en bd
            return Response({"created": True}, status=status.HTTP_201_CREATED)
        return Response(
            {"created": False, "errors": serializer.errors},
            status=status.HTTP_400_BAD_REQUEST,
        )


class RoutineListCreateView(APIView):
    permission_classes = [IsAuthenticated]
    """
    GET  /api/routines/     → lista todas las rutinas
    POST /api/routines/     → crea una rutina nueva con sus ejercicios
    """

    def get(self, request):
        user = request.user
        routines = (
            Routine.objects.filter(created_by=user)
            .prefetch_related("routine_exercises__exercise")
            .all()
        )  # obtenemos todas las rutinas del usuario y precarga sus ejercicios
        serializer = RoutineDetailSerializer(
            routines, many=True
        )  # convierte la lista de rutinas (y sus ejercicios) a formato JSON usando el serializer RoutineDetailSerializer.

        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        serializer = RoutineCreateSerializer(data=request.data, context={"request": request})

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        routine = serializer.save()

        # Respondemos con el detalle completo de la rutina recién creada
        response_serializer = RoutineDetailSerializer(routine)

        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


class RoutineDetailView(APIView):
    """
    GET    /api/routines/<id>/   → detalle de una rutina
    DELETE /api/routines/<id>/   → elimina una rutina
    """

    def _get_routine_or_404(self, routine_id):
        """gets routine if it exists"""
        try:
            return Routine.objects.prefetch_related("routine_exercises__exercise").get(
                pk=routine_id
            )
        except Routine.DoesNotExist:
            return None

    def get(self, request, routine_id):
        routine = self._get_routine_or_404(routine_id)
        if routine is None:
            return Response({"error": "Rutina no encontrada."}, status=status.HTTP_404_NOT_FOUND)

        serializer = RoutineDetailSerializer(routine)  # convertimos a json y mandamos
        return Response(serializer.data, status=status.HTTP_200_OK)

    def delete(self, request, routine_id):
        routine = self._get_routine_or_404(routine_id)
        if routine is None:
            return Response({"error": "Rutina no encontrada."}, status=status.HTTP_404_NOT_FOUND)

        routine.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class RoutineExerciseDeleteView(APIView):
    """
    DELETE /api/routines/<routine_id>/exercises/<exercise_id>/ → quita un ejercicio de una rutina
    """

    def delete(self, request, routine_id, exercise_id):
        from .models import RoutineExercise

        deleted, _ = RoutineExercise.objects.filter(
            routine_id=routine_id, exercise_id=exercise_id
        ).delete()
        if deleted:
            return Response(status=status.HTTP_204_NO_CONTENT)
        return Response(
            {"error": "Ejercicio no encontrado en esta rutina."},
            status=status.HTTP_404_NOT_FOUND,
        )


class WorkoutSessionListCreateView(APIView):
    """
    POST /api/sessions/         → inicia una sesión de entrenamiento
    GET  /api/sessions/         → lista sesiones pasadas
    """

    def post(self, request):
        serializer = WorkoutSessionSerializer(data=request.data, context={"request": request})
        if serializer.is_valid():
            # Intentamos reutilizar sesión si es el mismo usuario, rutina y el MISMO DÍA.
            user = request.user
            # user = User.objects.get(username="daniela")
            routine = serializer.validated_data["routine"]
            requested_date = serializer.validated_data.get("date", timezone.now())

            # Filtramos por el día exacto (sin importar la hora)
            existing = WorkoutSession.objects.filter(
                user=user, routine=routine, date__date=requested_date.date()
            ).first()

            if existing:
                return Response(WorkoutSessionSerializer(existing).data, status=status.HTTP_200_OK)

            session = serializer.save()
            return Response(WorkoutSessionSerializer(session).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def get(self, request):
        user = request.user
        sessions = WorkoutSession.objects.filter(user=user).order_by("-date")
        serializer = WorkoutSessionSerializer(sessions, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class WorkoutHistoryByDateRangeView(APIView):
    """
    GET /api/sessions/history/?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD&page=1&page_size=10
    → historial de entrenamientos del usuario en un rango de fechas.
    """

    class Pagination(PageNumberPagination):
        page_size = 10
        page_size_query_param = "page_size"
        max_page_size = 50

    def get(self, request):
        start_date_param = request.query_params.get("start_date")
        end_date_param = request.query_params.get("end_date")

        if not start_date_param or not end_date_param:
            return Response(
                {"detail": "Los parámetros start_date y end_date son obligatorios."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        start_date = parse_date(start_date_param)
        end_date = parse_date(end_date_param)

        if not start_date or not end_date:
            return Response(
                {"detail": "Formato de fecha inválido. Usa YYYY-MM-DD en start_date y end_date."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if start_date > end_date:
            return Response(
                {"detail": "start_date no puede ser mayor que end_date."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = request.user
        # try:
        #     user = User.objects.get(username="daniela")
        # except User.DoesNotExist:
        #     return Response(
        #         {"detail": "Usuario de contexto no encontrado."},
        #         status=status.HTTP_404_NOT_FOUND,
        #     )

        sessions = (
            WorkoutSession.objects.filter(
                user=user,
                date__date__range=(start_date, end_date),
            )
            .select_related("routine")
            .order_by("date")
        )

        paginator = self.Pagination()
        page = paginator.paginate_queryset(sessions, request, view=self)
        serializer = WorkoutHistorySerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)


class SetLogCreateView(APIView):
    """
    POST /api/sets/             → registra una serie (set)
    """

    def post(self, request):
        serializer = SetLogSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SetLogDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET /api/sets/<id>/    → obtiene una serie
    PUT /api/sets/<id>/    → actualiza una serie
    DELETE /api/sets/<id>/ → elimina una serie
    """

    queryset = SetLog.objects.all()
    serializer_class = SetLogSerializer


class LastExerciseLogView(APIView):
    """
    GET /api/exercises/<exercise_id>/last/ → obtiene el último registro de un ejercicio
    """

    def get(self, request, exercise_id):
        # Buscar el último SetLog para este ejercicio
        last_log = SetLog.objects.filter(exercise_id=exercise_id).order_by("-session__date")
        if not last_log.exists():
            return Response(
                {"detail": "No hay registros previos."},
                status=status.HTTP_404_NOT_FOUND,
            )

        last_session_id = last_log.first().session_id
        sets = last_log.filter(session_id=last_session_id)
        serializer = SetLogSerializer(sets, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class ExerciseHistoryView(APIView):
    """
    GET /api/exercises/<exercise_id>/history/ → historial completo de un ejercicio
    """

    def get(self, request, exercise_id):
        logs = (
            SetLog.objects.filter(exercise_id=exercise_id)
            .select_related("session")
            .order_by("-session__date")
        )

        # Agrupar por sesión para que el frontend pueda mostrar tarjetas por fecha
        history = {}
        for log in logs:
            session_date = log.session.date.strftime("%Y-%m-%d")
            if session_date not in history:
                history[session_date] = {"date": session_date, "sets": []}
            history[session_date]["sets"].append(SetLogSerializer(log).data)

        return Response(list(history.values()), status=status.HTTP_200_OK)

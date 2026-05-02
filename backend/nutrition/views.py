from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from users.models import User

from .models import MealRecord, NutritionPlan
from .serializers import MealRecordSerializer, NutritionPlanSerializer


class MealRecordViewSet(viewsets.ModelViewSet):  # NOSONAR
    """
    ViewSet para gestionar registros de alimentación.

    Endpoints generados automáticamente:
      GET    /nutrition/meals/              → listar todos los registros
      POST   /nutrition/meals/              → crear registro
      GET    /nutrition/meals/{id}/         → detalle
      PUT    /nutrition/meals/{id}/         → actualizar completo
      PATCH  /nutrition/meals/{id}/         → actualizar parcial
      DELETE /nutrition/meals/{id}/         → eliminar

    Endpoint adicional:
      GET    /nutrition/meals/by_date/?date=YYYY-MM-DD  → filtrar por fecha
    """

    permission_classes = [IsAuthenticated]
    queryset = MealRecord.objects.all()
    serializer_class = MealRecordSerializer

    def get_queryset(self):
        """
        Permite filtrar por athlete_id y/o date como query params.
        Ejemplo: /nutrition/meals/?athlete=1&date=2026-03-23
        """
        user = self.request.user
        queryset = MealRecord.objects.select_related("athlete", "athlete__user")
        athlete_id = self.request.query_params.get("athlete")
        date = self.request.query_params.get("date")
        start_date = self.request.query_params.get("start_date")
        end_date = self.request.query_params.get("end_date")

        # Un atleta solo puede ver sus propios registros.
        if user.role == "athlete":
            queryset = queryset.filter(athlete__user=user)
        elif athlete_id:
            # Coaches pueden consultar por atleta explícito.
            queryset = queryset.filter(athlete__id=athlete_id)

        if date:
            queryset = queryset.filter(date=date)
        if start_date and end_date:
            queryset = queryset.filter(date__range=(start_date, end_date))

        return queryset

    def perform_create(self, serializer):
        user = self.request.user
        athlete = serializer.validated_data.get("athlete")

        # Evita que un atleta cree registros para otro perfil.
        if user.role == "athlete" and athlete.user_id != user.id:
            raise PermissionDenied("No puedes crear registros para otro atleta.")

        serializer.save()

    def perform_update(self, serializer):
        user = self.request.user
        athlete = serializer.validated_data.get("athlete", serializer.instance.athlete)

        if user.role == "athlete" and athlete.user_id != user.id:
            raise PermissionDenied("No puedes editar registros de otro atleta.")

        serializer.save()

    @action(detail=False, methods=["get"], url_path="by_date")
    def by_date(self, request):
        """
        Retorna todos los registros de alimentación de una fecha específica.
        Query param: date (YYYY-MM-DD)
        """
        date = request.query_params.get("date")
        if not date:
            return Response(
                {"error": 'El parámetro "date" es requerido (YYYY-MM-DD).'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        records = self.get_queryset().filter(date=date)
        serializer = self.get_serializer(records, many=True)
        return Response(serializer.data)


class NutritionPlanViewSet(viewsets.ModelViewSet):  # NOSONAR
    """
    ViewSet para planes de nutrición asignados por un coach a un atleta.

    Endpoints:
      GET    /nutrition/plans/              → listar planes
      POST   /nutrition/plans/              → crear plan (solo coaches)
      GET    /nutrition/plans/{id}/         → detalle
      PATCH  /nutrition/plans/{id}/         → actualizar (solo el coach dueño)
      DELETE /nutrition/plans/{id}/         → eliminar (solo el coach dueño)

    Query params para GET /nutrition/plans/:
      ?athlete=<athlete_profile_id>
    """

    permission_classes = [IsAuthenticated]
    serializer_class = NutritionPlanSerializer

    def get_queryset(self):
        user = self.request.user
        queryset = NutritionPlan.objects.select_related("coach")
        if user.role == "athlete":
            queryset = queryset.filter(assigned_athletes=user)
        else:
            queryset = queryset.filter(coach=user)
        return queryset

    def perform_create(self, serializer):
        user = self.request.user
        if user.role != "coach":
            raise PermissionDenied("Solo los coaches pueden crear planes de nutrición.")
        serializer.save(coach=user)

    def perform_update(self, serializer):
        user = self.request.user
        if serializer.instance.coach_id != user.id:
            raise PermissionDenied("Solo el coach que creó este plan puede modificarlo.")
        serializer.save()

    def perform_destroy(self, instance):
        user = self.request.user
        if instance.coach_id != user.id:
            raise PermissionDenied("Solo el coach que creó este plan puede eliminarlo.")
        instance.delete()

    @action(detail=True, methods=["post"])
    def assign(self, request, pk=None):
        plan = self.get_object()
        if plan.coach_id != request.user.id:
            raise PermissionDenied("Solo el coach dueño puede asignar este plan.")

        athlete_ids = set(request.data.get("athlete_ids", []))
        group_ids = request.data.get("group_ids", [])
        if group_ids:
            members_from_groups = User.objects.filter(
                training_group_memberships__id__in=group_ids
            ).values_list("id", flat=True)
            athlete_ids.update(members_from_groups)

        athletes = User.objects.filter(id__in=athlete_ids, role="athlete")
        plan.assigned_athletes.add(*athletes)
        return Response({"detail": "Plan asignado correctamente."}, status=status.HTTP_200_OK)

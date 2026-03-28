from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import MealRecord
from .serializers import MealRecordSerializer


class MealRecordViewSet(viewsets.ModelViewSet):
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

    queryset = MealRecord.objects.all()
    serializer_class = MealRecordSerializer

    def get_queryset(self):
        """
        Permite filtrar por athlete_id y/o date como query params.
        Ejemplo: /nutrition/meals/?athlete=1&date=2026-03-23
        """
        queryset = MealRecord.objects.all()
        athlete_id = self.request.query_params.get("athlete")
        date = self.request.query_params.get("date")

        if athlete_id:
            queryset = queryset.filter(athlete__id=athlete_id)
        if date:
            queryset = queryset.filter(date=date)

        return queryset

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

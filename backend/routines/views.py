from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Routine, Exercise
from .serializers.serializer_routine import RoutineCreateSerializer, RoutineDetailSerializer
from .serializers.serializers_exercise import ExerciseSerializer

# Endpoint para buscar ejercicios por nombre y crear ejercicios
# cuando usamos clase APIView, se registra la clase para la url, y django REST dirige automaticamente peticion a mentodo correspondiente de la clase:
# Si la petición es GET, llama al método get().
# Si la petición es POST, llama al método post().
# (Y si tuvieras métodos put(), delete(), etc., los llamaría según el verbo HTTP).
class ExerciseListCreateView(APIView):
    """ Class to create or search if a Exercise exits in bd"""
    # buscamos ejercicio por external_id
    def get(self, request):
        external_id = request.query_params.get('external_id')
        if not external_id:
            return Response({'detail': 'Missing external id parameter.'}, status=status.HTTP_400_BAD_REQUEST)
    
        exists = Exercise.objects.filter(external_id=external_id).exists()
        return Response({'exists': exists}, status=status.HTTP_200_OK)

    def post(self, request):
        # intentamos convertir json a modelo
        serializer = ExerciseSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save() # si sí se puede, lo guardamos en bd
            return Response({'created': True}, status=status.HTTP_201_CREATED)
        return Response({'created': False, 'errors': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)
    

class RoutineListCreateView(APIView):
    """
    GET  /api/routines/     → lista todas las rutinas
    POST /api/routines/     → crea una rutina nueva con sus ejercicios
    """

    def get(self, request):
        routines = Routine.objects.prefetch_related('routine_exercises__exercise').all() # obtenemos todas las rutinas y precarga sus ejercicios
        serializer = RoutineDetailSerializer(routines, many=True) # convierte la lista de rutinas (y sus ejercicios) a formato JSON usando el serializer RoutineDetailSerializer.
        
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        serializer = RoutineCreateSerializer(data=request.data)

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
        """ gets routine if it exists"""
        try:
            return Routine.objects.prefetch_related(
                'routine_exercises__exercise'
            ).get(pk=routine_id)
        except Routine.DoesNotExist:
            return None

    def get(self, request, routine_id):
        routine = self._get_routine_or_404(routine_id)
        if routine is None:
            return Response({'error': 'Rutina no encontrada.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = RoutineDetailSerializer(routine) # convertimos a json y mandamos
        return Response(serializer.data, status=status.HTTP_200_OK)

    def delete(self, request, routine_id):
        routine = self._get_routine_or_404(routine_id)
        if routine is None:
            return Response({'error': 'Rutina no encontrada.'}, status=status.HTTP_404_NOT_FOUND)

        routine.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
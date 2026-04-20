from django.db import models
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import AthleteProfile, CoachProfile, User
from .serializers import (
    AthleteSearchSerializer,
    MyTokenObtainPairSerializer,
    RegisterSerializer,
    UserSerializer,
)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def protected_test(request):
    return Response(
        {
            "message": f"Hola {request.user.username}, estas autenticado",
            "first_name": request.user.first_name or request.user.username,
        }
    )


@api_view(["POST"])
@permission_classes([AllowAny])
def RegisterView(request):
    serializer = RegisterSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        refresh = RefreshToken.for_user(user)

        athlete_id = None
        if user.role == "athlete":
            try:
                athlete = AthleteProfile.objects.get(user=user)
                athlete_id = athlete.id
            except AthleteProfile.DoesNotExist:
                pass

        return Response(
            {
                "user": UserSerializer(user).data,
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "role": user.role,
                "athlete_id": athlete_id,
                "first_name": user.first_name or user.username,
            },
            status=status.HTTP_201_CREATED,
        )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = MyTokenObtainPairSerializer


class MyTokenObtainPairView(TokenObtainPairView):
    serializer_class = MyTokenObtainPairSerializer


# Vistas para el entrenador (coach)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def AthleteSearchView(request):
    """Búsqueda global de atletas por username, primer nombre o email."""
    if request.user.role != "coach":
        return Response({"detail": "Solo los entrenadores pueden buscar atletas."}, status=status.HTTP_403_FORBIDDEN)

    query = request.query_params.get("q", "")
    if len(query) < 2:
        return Response([])

    athletes = User.objects.filter(role="athlete").filter(
        models.Q(username__icontains=query)
        | models.Q(first_name__icontains=query)
        | models.Q(email__icontains=query)
    )[:10]

    serializer = AthleteSearchSerializer(athletes, many=True)
    return Response(serializer.data)


@api_view(["GET", "POST", "DELETE"])
@permission_classes([IsAuthenticated])
def CoachAthleteManagementView(request, athlete_id=None):
    """Gestiona la lista de atletas vinculados a un coach."""
    if request.user.role != "coach":
        return Response({"detail": "Acceso denegado."}, status=status.HTTP_403_FORBIDDEN)

    try:
        coach_profile = CoachProfile.objects.get(user=request.user)
    except CoachProfile.DoesNotExist:
        return Response({"detail": "Perfil de entrenador no encontrado."}, status=status.HTTP_404_NOT_FOUND)

    if request.method == "GET":
        # Listar mis atletas
        athletes = coach_profile.athletes.all()
        serializer = AthleteSearchSerializer(athletes, many=True)
        return Response(serializer.data)

    if request.method == "POST":
        # Vincular atleta
        try:
            athlete = User.objects.get(id=athlete_id, role="athlete")
            coach_profile.athletes.add(athlete)
            return Response({"detail": "Atleta vinculado correctamente."}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({"detail": "Atleta no encontrado."}, status=status.HTTP_404_NOT_FOUND)

    if request.method == "DELETE":
        # Desvincular atleta
        coach_profile.athletes.remove(athlete_id)
        return Response({"detail": "Atleta desvinculado."}, status=status.HTTP_204_NO_CONTENT)

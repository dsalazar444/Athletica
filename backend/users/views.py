from django.db import models
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import AthleteProfile, CoachProfile, Goal, User, WeightLog
from .serializers import (
    AthleteSearchSerializer,
    GoalSerializer,
    MyTokenObtainPairSerializer,
    ProfileSettingsSerializer,
    RegisterSerializer,
    UserSerializer,
    WeightLogSerializer,
)

PROFILE_NOT_FOUND_MSG = "Perfil no encontrado."

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
def register_view(request):
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
def athlete_search_view(request):
    """Búsqueda global de atletas por username, primer nombre o email."""
    if request.user.role != "coach":
        return Response(
            {"detail": "Solo los entrenadores pueden buscar atletas."},
            status=status.HTTP_403_FORBIDDEN,
        )

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
def coach_athlete_management_view(request, athlete_id=None):
    """Gestiona la lista de atletas vinculados a un coach."""
    if request.user.role != "coach":
        return Response({"detail": "Acceso denegado."}, status=status.HTTP_403_FORBIDDEN)

    try:
        coach_profile = CoachProfile.objects.get(user=request.user)
    except CoachProfile.DoesNotExist:
        return Response(
            {"detail": "Perfil de entrenador no encontrado."}, status=status.HTTP_404_NOT_FOUND
        )

    if request.method == "GET":
        # Listar mis atletas (Solo usuarios con rol 'athlete')
        athletes = coach_profile.athletes.filter(role="athlete")
        serializer = AthleteSearchSerializer(athletes, many=True)
        return Response(serializer.data)

    if request.method == "POST":
        # Vincular atleta
        try:
            athlete = User.objects.get(id=athlete_id, role="athlete")
            coach_profile.athletes.add(athlete)
            return Response(
                {"detail": "Atleta vinculado correctamente."}, status=status.HTTP_200_OK
            )
        except User.DoesNotExist:
            return Response({"detail": "Atleta no encontrado."}, status=status.HTTP_404_NOT_FOUND)

    if request.method == "DELETE":
        # Desvincular atleta
        coach_profile.athletes.remove(athlete_id)
        return Response({"detail": "Atleta desvinculado."}, status=status.HTTP_204_NO_CONTENT)


@api_view(["GET", "PATCH"])
@permission_classes([IsAuthenticated])
def profile_settings_view(request):
    user = request.user

    def build_payload():
        profile_data = {
            "name": user.first_name or user.username,
            "age": user.age,
            "weight": user.weight,
            "height": user.height,
            "training_goal": user.training_goal or None,
            "role": user.role,
        }

        if user.role == "athlete":
            try:
                athlete = AthleteProfile.objects.get(user=user)
                profile_data["age"] = athlete.age
                profile_data["height"] = athlete.height

                latest_weight = athlete.weight.order_by("-date", "-id").first()
                if latest_weight:
                    profile_data["weight"] = latest_weight.weight

                active_goal = athlete.goals.filter(is_active=True).order_by("-id").first()
                if active_goal:
                    profile_data["training_goal"] = active_goal.goal_type
            except AthleteProfile.DoesNotExist:
                pass

        return profile_data

    if request.method == "GET":
        return Response(build_payload(), status=status.HTTP_200_OK)

    serializer = ProfileSettingsSerializer(data=request.data, partial=True)
    serializer.is_valid(raise_exception=True)
    data = serializer.validated_data

    if "name" in data:
        user.first_name = data["name"]

    if "age" in data:
        user.age = data["age"]

    if "height" in data:
        user.height = data["height"]

    if "weight" in data:
        user.weight = data["weight"]

    if "training_goal" in data:
        user.training_goal = data["training_goal"]

    user.save()

    if user.role == "athlete":
        athlete = AthleteProfile.objects.filter(user=user).first()
        if athlete:
            updated_fields = []
            if "age" in data:
                athlete.age = data["age"]
                updated_fields.append("age")
            if "height" in data:
                athlete.height = data["height"]
                updated_fields.append("height")
            if updated_fields:
                athlete.save(update_fields=updated_fields)

            if "weight" in data:
                from .models import WeightLog

                WeightLog.objects.create(athlete=athlete, weight=data["weight"])

            if "training_goal" in data:
                from .models import Goal

                Goal.objects.filter(athlete=athlete, is_active=True).exclude(
                    goal_type=data["training_goal"]
                ).update(is_active=False)
                goal = Goal.objects.filter(athlete=athlete, is_active=True).first()
                if goal:
                    goal.goal_type = data["training_goal"]
                    goal.save(update_fields=["goal_type"])
                else:
                    Goal.objects.create(
                        athlete=athlete,
                        goal_type=data["training_goal"],
                        description="",
                        is_active=True,
                    )

    return Response(build_payload(), status=status.HTTP_200_OK)


# ── Dashboard Atleta ──────────────────────────────────────────────────────────


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def athlete_dashboard_view(request):
    """Devuelve los datos del dashboard del atleta autenticado."""
    try:
        profile = AthleteProfile.objects.get(user=request.user)
    except AthleteProfile.DoesNotExist:
        return Response({"detail": PROFILE_NOT_FOUND_MSG}, status=status.HTTP_404_NOT_FOUND)

    latest_weight = WeightLog.objects.filter(athlete=profile).order_by("-date").first()
    active_goal = Goal.objects.filter(athlete=profile, is_active=True).first()

    return Response(
        {
            "height": profile.height,
            "age": profile.age,
            "gender": profile.gender,
            "activity_level": profile.activity_level,
            "latest_weight": WeightLogSerializer(latest_weight).data if latest_weight else None,
            "goal": GoalSerializer(active_goal).data if active_goal else None,
        }
    )


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def weight_log_view(request):
    """Lista todos los pesos del atleta o agrega uno nuevo."""
    try:
        profile = AthleteProfile.objects.get(user=request.user)
    except AthleteProfile.DoesNotExist:
        return Response({"detail": PROFILE_NOT_FOUND_MSG}, status=status.HTTP_404_NOT_FOUND)

    if request.method == "GET":
        logs = WeightLog.objects.filter(athlete=profile).order_by("-date")
        serializer = WeightLogSerializer(logs, many=True)
        return Response(serializer.data)

    elif request.method == "POST":
        serializer = WeightLogSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(athlete=profile)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ── Dashboard Coach ───────────────────────────────────────────────────────────


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def coach_dashboard_view(request):
    """Devuelve los datos del dashboard del coach autenticado."""
    if request.user.role != "coach":
        return Response({"detail": "Acceso denegado."}, status=status.HTTP_403_FORBIDDEN)

    try:
        profile = CoachProfile.objects.get(user=request.user)
    except CoachProfile.DoesNotExist:
        return Response({"detail": PROFILE_NOT_FOUND_MSG}, status=status.HTTP_404_NOT_FOUND)

    from routines.models import TrainingGroup

    groups = TrainingGroup.objects.filter(coach=request.user).values("id", "name")

    return Response(
        {
            "name": request.user.first_name or request.user.username,
            "speciality": profile.speciality,
            "years_experience": profile.years_experience,
            "groups": list(groups),
        }
    )

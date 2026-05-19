import logging
from datetime import timedelta

from django.conf import settings
from django.contrib.auth.tokens import default_token_generator
from django.core.mail import send_mail
from django.db import models
from django.db.models import Avg
from django.utils import timezone
from django.utils.encoding import force_bytes, force_str
from django.utils.http import urlsafe_base64_decode, urlsafe_base64_encode
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from nutrition.models import MealRecord
from routines.models import SetLog, WorkoutSession

from .models import (
    AthleteProfile,
    Badge,
    CoachProfile,
    Follow,
    Goal,
    Reminder,
    User,
    UserBadge,
    WeightLog,
)
from .serializers import (
    AthleteSearchSerializer,
    BadgeSerializer,
    FollowSerializer,
    GoalSerializer,
    MyTokenObtainPairSerializer,
    ProfileSettingsSerializer,
    RegisterSerializer,
    ReminderSerializer,
    UserBadgeSerializer,
    UserSerializer,
    WeightLogSerializer,
)

logger = logging.getLogger(__name__)


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
def CoachAthleteManagementView(request, athlete_id=None):
    """Gestiona la lista de atletas vinculados a un coach."""
    if request.user.role != "coach":
        return Response({"detail": "Acceso denegado."}, status=status.HTTP_403_FORBIDDEN)

    try:
        coach_profile = CoachProfile.objects.get(user=request.user)
    except CoachProfile.DoesNotExist:
        return Response(
            {"detail": "Perfil de entrenador no encontrado."},
            status=status.HTTP_404_NOT_FOUND,
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
def ProfileSettingsView(request):
    user = request.user

    def build_payload():
        profile_data = {
            "name": user.first_name or user.username,
            "age": user.age,
            "weight": user.weight,
            "height": user.height,
            "training_goal": user.training_goal or None,
            "timezone": user.timezone,
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

    if "timezone" in data:
        user.timezone = data["timezone"]

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
def AthleteDashboardView(request):
    """Devuelve los datos del dashboard del atleta autenticado."""
    try:
        profile = AthleteProfile.objects.get(user=request.user)
    except AthleteProfile.DoesNotExist:
        return Response({"detail": "Perfil no encontrado."}, status=status.HTTP_404_NOT_FOUND)

    latest_weight = WeightLog.objects.filter(athlete=profile).order_by("-date").first()
    active_goal = Goal.objects.filter(athlete=profile, is_active=True).first()

    return Response(
        {
            "height": profile.height,
            "age": profile.age,
            "gender": profile.gender,
            "activity_level": profile.activity_level,
            "latest_weight": (WeightLogSerializer(latest_weight).data if latest_weight else None),
            "goal": GoalSerializer(active_goal).data if active_goal else None,
            "followers_count": request.user.followers.count(),
            "following_count": request.user.following.count(),
        }
    )


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def WeightLogView(request):
    """Lista todos los pesos del atleta o agrega uno nuevo."""
    try:
        profile = AthleteProfile.objects.get(user=request.user)
    except AthleteProfile.DoesNotExist:
        return Response({"detail": "Perfil no encontrado."}, status=status.HTTP_404_NOT_FOUND)

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


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def GoalLogView(request):
    """Lista las metas de los atletas o agrega uno nuevo"""
    try:
        profile = AthleteProfile.objects.get(user=request.user)
    except AthleteProfile.DoesNotExist:
        return Response({"detail": "Perfil no encontrado."}, status=status.HTTP_404_NOT_FOUND)

    if request.method == "GET":
        logs = Goal.objects.filter(athlete=profile).order_by("-start_date")
        serializer = GoalSerializer(logs, many=True)
        return Response(serializer.data)

    elif request.method == "POST":
        serializer = GoalSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(athlete=profile)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(["GET", "PUT", "DELETE"])
@permission_classes([IsAuthenticated])
def GoalDetailView(request, goal_id):
    """Obtiene, edita o elimina una meta específica."""
    try:
        profile = AthleteProfile.objects.get(user=request.user)
    except AthleteProfile.DoesNotExist:
        return Response({"detail": "Perfil no encontrado."}, status=status.HTTP_404_NOT_FOUND)

    try:
        goal = Goal.objects.get(id=goal_id, athlete=profile)
    except Goal.DoesNotExist:
        return Response({"detail": "Meta no encontrada."}, status=status.HTTP_404_NOT_FOUND)

    if request.method == "GET":
        return Response(GoalSerializer(goal).data)

    elif request.method == "PUT":
        serializer = GoalSerializer(goal, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == "DELETE":
        goal.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def ReminderListCreateView(request):
    """Lista y crea recordatorios del usuario autenticado."""
    if request.method == "GET":
        reminders = Reminder.objects.filter(user=request.user).order_by("remind_at")
        serializer = ReminderSerializer(reminders, many=True)
        return Response(serializer.data)

    serializer = ReminderSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save(user=request.user)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(["GET", "PUT", "DELETE"])
@permission_classes([IsAuthenticated])
def ReminderDetailView(request, reminder_id):
    """Obtiene, actualiza o elimina un recordatorio del usuario autenticado."""
    try:
        reminder = Reminder.objects.get(id=reminder_id, user=request.user)
    except Reminder.DoesNotExist:
        return Response({"detail": "Recordatorio no encontrado."}, status=status.HTTP_404_NOT_FOUND)

    if request.method == "GET":
        return Response(ReminderSerializer(reminder).data)

    if request.method == "PUT":
        serializer = ReminderSerializer(reminder, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    reminder.delete()
    return Response(status=status.HTTP_204_NO_CONTENT)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def ReminderDueView(request):
    """Retorna recordatorios vencidos sin notificar y los marca como notificados."""
    now = timezone.now()
    due_reminders = list(
        Reminder.objects.filter(
            user=request.user,
            is_active=True,
            remind_at__lte=now,
            notified_at__isnull=True,
        ).order_by("remind_at")
    )

    # Log for debugging: which reminders are considered due
    if due_reminders:
        logger.info(
            "ReminderDueView: %d due reminders for user %s at %s",
            len(due_reminders),
            request.user.username,
            now,
        )
        for r in due_reminders:
            logger.info(
                " - Reminder id=%s remind_at=%s activity=%s",
                r.id,
                r.remind_at,
                r.activity_type,
            )

    serializer = ReminderSerializer(due_reminders, many=True)
    # Mark as notified AFTER serializing to return the data that triggered the notification
    if due_reminders:
        Reminder.objects.filter(pk__in=[reminder.pk for reminder in due_reminders]).update(
            notified_at=now
        )
    return Response(serializer.data)


# ── Dashboard Coach ───────────────────────────────────────────────────────────


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def CoachDashboardView(request):
    """Devuelve los datos del dashboard del coach autenticado."""
    if request.user.role != "coach":
        return Response({"detail": "Acceso denegado."}, status=status.HTTP_403_FORBIDDEN)

    try:
        profile = CoachProfile.objects.get(user=request.user)
    except CoachProfile.DoesNotExist:
        return Response({"detail": "Perfil no encontrado."}, status=status.HTTP_404_NOT_FOUND)

    from routines.models import TrainingGroup

    groups = TrainingGroup.objects.filter(coach=request.user).values("id", "name")

    return Response(
        {
            "name": request.user.first_name or request.user.username,
            "speciality": profile.speciality,
            "years_experience": profile.years_experience,
            "groups": list(groups),
            "followers_count": request.user.followers.count(),
            "following_count": request.user.following.count(),
        }
    )


# ── Follow/Unfollow ───────────────────────────────────────────────────────────
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def followUser(request, user_id):
    """
    Crear un registro Follow: el usuario logueado sigue a otro usuario.
    user_id = id de User que se quiere seguir
    """
    try:
        user_to_follow = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response({"detail": "Usuario no encontrado."}, status=status.HTTP_404_NOT_FOUND)

    # No puede seguirse a sí mismo
    if request.user.id == user_to_follow.id:
        return Response(
            {"detail": "No puedes seguirte a ti mismo."}, status=status.HTTP_400_BAD_REQUEST
        )

    # Evitar duplicados
    follow, isNew = Follow.objects.get_or_create(follower=request.user, following=user_to_follow)

    if not isNew:
        return Response(
            {"detail": "Ya estás siguiendo a este usuario."}, status=status.HTTP_400_BAD_REQUEST
        )

    serializer = FollowSerializer(follow)
    return Response(serializer.data, status=status.HTTP_201_CREATED)


@api_view(["DELETE"])
@permission_classes([IsAuthenticated])
def unfollowUser(request, user_id):
    """
    Eliminar un registro Follow: el usuario logueado deja de seguir a otro usuario.
    user_id = id de User que se quiere dejar de seguir
    """
    try:
        user_to_unfollow = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response({"detail": "Usuario no encontrado."}, status=status.HTTP_404_NOT_FOUND)

    try:
        follow = Follow.objects.get(follower=request.user, following=user_to_unfollow)
    except Follow.DoesNotExist:
        return Response(
            {"detail": "No estás siguiendo a este usuario."}, status=status.HTTP_400_BAD_REQUEST
        )

    follow.delete()
    return Response(
        {"detail": "Has dejado de seguir al usuario."}, status=status.HTTP_204_NO_CONTENT
    )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def ComparativeStatsView(request):
    try:
        profile = AthleteProfile.objects.get(user=request.user)
    except AthleteProfile.DoesNotExist:
        return Response({"detail": "Perfil no encontrado."}, status=status.HTTP_404_NOT_FOUND)

    period = request.query_params.get("period", "monthly")
    now = timezone.now()

    if period == "monthly":
        current_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        previous_start = (current_start - timedelta(days=1)).replace(day=1)
        previous_end = current_start - timedelta(microseconds=1)
    elif period == "quarterly":
        current_quarter_month = ((now.month - 1) // 3) * 3 + 1
        current_start = now.replace(
            month=current_quarter_month, day=1, hour=0, minute=0, second=0, microsecond=0
        )
        previous_end = current_start - timedelta(microseconds=1)
        previous_quarter_month = ((previous_end.month - 1) // 3) * 3 + 1
        previous_start = previous_end.replace(
            month=previous_quarter_month, day=1, hour=0, minute=0, second=0, microsecond=0
        )
    else:
        return Response({"error": "Periodo no soportado"}, status=status.HTTP_400_BAD_REQUEST)

    def calc_change(curr, prev):
        if prev == 0:
            if curr > 0:
                return 100.0
            elif curr < 0:
                return -100.0
            return 0.0
        return ((curr - prev) / prev) * 100.0

    current_workouts = WorkoutSession.objects.filter(
        user=request.user, date__gte=current_start
    ).count()
    previous_workouts = WorkoutSession.objects.filter(
        user=request.user, date__gte=previous_start, date__lte=previous_end
    ).count()
    workouts_change = calc_change(current_workouts, previous_workouts)

    current_meals = MealRecord.objects.filter(athlete=profile, date__gte=current_start.date())
    current_calories = sum(m.calories for m in current_meals)
    days_current = max(1, (now.date() - current_start.date()).days + 1)
    current_cal_avg = float(current_calories) / days_current

    previous_meals = MealRecord.objects.filter(
        athlete=profile, date__gte=previous_start.date(), date__lte=previous_end.date()
    )
    previous_calories = sum(m.calories for m in previous_meals)
    days_previous = max(1, (previous_end.date() - previous_start.date()).days + 1)
    previous_cal_avg = float(previous_calories) / days_previous
    cal_change = calc_change(current_cal_avg, previous_cal_avg)

    current_weight_avg = (
        WeightLog.objects.filter(athlete=profile, date__gte=current_start).aggregate(Avg("weight"))[
            "weight__avg"
        ]
        or 0.0
    )
    previous_weight_avg = (
        WeightLog.objects.filter(
            athlete=profile, date__gte=previous_start, date__lte=previous_end
        ).aggregate(Avg("weight"))["weight__avg"]
        or 0.0
    )

    if current_weight_avg == 0:
        last = WeightLog.objects.filter(athlete=profile).order_by("-date").first()
        current_weight_avg = float(last.weight) if last else 0.0

    if previous_weight_avg == 0:
        last_prev = (
            WeightLog.objects.filter(athlete=profile, date__lte=previous_end)
            .order_by("-date")
            .first()
        )
        previous_weight_avg = float(last_prev.weight) if last_prev else current_weight_avg

    weight_change = calc_change(current_weight_avg, previous_weight_avg)

    return Response(
        {
            "workouts": {
                "current": current_workouts,
                "previous": previous_workouts,
                "change_percentage": round(workouts_change, 1),
            },
            "calories_daily_avg": {
                "current": round(current_cal_avg, 1),
                "previous": round(previous_cal_avg, 1),
                "change_percentage": round(cal_change, 1),
            },
            "weight_avg": {
                "current": round(current_weight_avg, 1),
                "previous": round(previous_weight_avg, 1),
                "change_percentage": round(weight_change, 1),
            },
        }
    )


@api_view(["POST"])
@permission_classes([AllowAny])
def PasswordResetRequestView(request):
    """
    Solicita un restablecimiento de contraseña.
    En una app real, enviaría un correo. Aquí simulamos el envío por consola.
    """
    email = request.data.get("email")
    if not email:
        return Response({"detail": "El email es requerido."}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        # Por seguridad, no revelamos si el email existe o no.
        return Response(
            {"detail": "Si el email está registrado, recibirás un enlace de recuperación."},
            status=status.HTTP_200_OK,
        )

    token = default_token_generator.make_token(user)
    uidb64 = urlsafe_base64_encode(force_bytes(user.pk))

    # En una app real, aquí enviaríamos el correo
    subject = "Restablece tu contraseña en Athletica"
    message = f"Hola {user.username},\n\nUtiliza los siguientes datos para restablecer tu contraseña en la aplicación:\n\nUID: {uidb64}\nToken: {token}\n\nSi no solicitaste este cambio, ignora este mensaje."

    try:
        print(f"DEBUG: Intentando enviar correo a {email} desde {settings.DEFAULT_FROM_EMAIL}...")
        send_mail(
            subject,
            message,
            settings.DEFAULT_FROM_EMAIL,
            [email],
            fail_silently=False,
        )
        print(f"DEBUG: Correo enviado exitosamente a {email}")
    except Exception as e:
        # Si falla el envío (por falta de config), imprimimos en consola para no perder el token
        print(f"ERROR enviando correo a {email}: {e}")
        print(f"DATOS DE RECUPERACIÓN -> UID: {uidb64} | TOKEN: {token}")

    return Response(
        {
            "detail": "Si el email está registrado, recibirás un código de recuperación.",
            "debug_token": token,
            "debug_uid": uidb64,
        },
        status=status.HTTP_200_OK,
    )


@api_view(["POST"])
@permission_classes([AllowAny])
def PasswordResetConfirmView(request):
    """
    Confirma el restablecimiento de contraseña con el token recibido.
    """
    uidb64 = request.data.get("uid")
    token = request.data.get("token")
    new_password = request.data.get("password")

    print(
        f"DEBUG Confirm: Recibido UID={uidb64}, Token={token}, Password={'***' if new_password else 'VACIO'}"
    )

    if not (uidb64 and token and new_password):
        return Response(
            {"detail": "Faltan datos requeridos (uid, token, password)."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        uid = force_str(urlsafe_base64_decode(uidb64))
        user = User.objects.get(pk=uid)
        print(f"DEBUG Confirm: Usuario encontrado: {user.username}")
    except (TypeError, ValueError, OverflowError, User.DoesNotExist) as e:
        print(f"DEBUG Confirm: Error al decodificar UID o usuario no existe: {e}")
        return Response({"detail": "Enlace o UID inválido."}, status=status.HTTP_400_BAD_REQUEST)

    if default_token_generator.check_token(user, token):
        user.set_password(new_password)
        user.save()
        print(f"DEBUG Confirm: Contraseña de {user.username} actualizada con éxito.")
        return Response(
            {"detail": "Contraseña restablecida correctamente."}, status=status.HTTP_200_OK
        )
    else:
        print(f"DEBUG Confirm: El token '{token}' es inválido para el usuario {user.username}")
        return Response(
            {"detail": "El token es inválido o ha expirado."}, status=status.HTTP_400_BAD_REQUEST
        )


# ============= BADGE ENDPOINTS =============


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def BadgesListView(request):
    """
    Lista todas las insignias disponibles en el sistema.
    """
    badges = Badge.objects.all().order_by("badge_type", "level")
    serializer = BadgeSerializer(badges, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def BadgeDetailView(request, badge_id):
    """
    Obtiene los detalles de una insignia específica.
    """
    try:
        badge = Badge.objects.get(id=badge_id)
    except Badge.DoesNotExist:
        return Response(
            {"detail": "Insignia no encontrada."},
            status=status.HTTP_404_NOT_FOUND,
        )

    serializer = BadgeSerializer(badge)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def UserBadgesView(request):
    """
    Obtiene las insignias desbloqueadas del usuario autenticado.
    Incluye resumen de stats y total de badges.
    """
    from .badge_service import BadgeService

    user = request.user

    # Validar que el usuario tenga AthleteProfile
    try:
        user.athleteprofile
    except AthleteProfile.DoesNotExist:
        return Response(
            {"detail": "Solo los atletas pueden acceder a sus insignias."},
            status=status.HTTP_403_FORBIDDEN,
        )

    # Obtener badges desbloqueados
    user_badges = (
        UserBadge.objects.filter(user=user).select_related("badge").order_by("-unlocked_at")
    )

    # Validar y otorgar nuevos badges si aplica
    new_badges = BadgeService.check_and_award_badges(user)

    # Si se otorgaron nuevos badges, refrescar la lista
    if new_badges:
        user_badges = (
            UserBadge.objects.filter(user=user).select_related("badge").order_by("-unlocked_at")
        )

    # Construir respuesta con información completa
    summary = {
        "total_badges": user_badges.count(),
        "unlocked_badges": UserBadgeSerializer(user_badges, many=True).data,
        "newly_awarded": BadgeSerializer(new_badges, many=True).data,
        "stats": {
            "nutrition_streak": BadgeService.get_nutrition_streak(user),
            "workout_streak": BadgeService.get_workout_streak(user),
            "complete_streak": BadgeService.get_complete_streak(user),
        },
    }

    return Response(summary, status=status.HTTP_200_OK)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def CheckBadgesView(request):
    """
    Valida manualmente las insignias del usuario.
    Otorga automáticamente las insignias que cumplan criterios.
    Retorna las insignias recién otorgadas.
    """
    from .badge_service import BadgeService

    user = request.user

    # Validar que el usuario tenga AthleteProfile
    try:
        user.athleteprofile
    except AthleteProfile.DoesNotExist:
        return Response(
            {"detail": "Solo los atletas pueden acceder a sus insignias."},
            status=status.HTTP_403_FORBIDDEN,
        )

    # Validar y otorgar nuevos badges
    new_badges = BadgeService.check_and_award_badges(user)

    return Response(
        {
            "detail": f"Se validaron las insignias. {len(new_badges)} nuevas insignias otorgadas.",
            "newly_awarded": BadgeSerializer(new_badges, many=True).data,
        },
        status=status.HTTP_200_OK,
    )


UPPER_KEYWORDS = {"chest", "shoulder", "back", "bicep", "tricep", "arm", "pectoral", "delt", "lat"}
LOWER_KEYWORDS = {
    "quad",
    "hamstring",
    "glute",
    "calf",
    "leg",
    "thigh",
    "hip",
    "abductor",
    "adductor",
}


def _classify_muscle(muscle: str) -> str:
    m = muscle.lower()
    if any(k in m for k in UPPER_KEYWORDS):
        return "upper"
    if any(k in m for k in LOWER_KEYWORDS):
        return "lower"
    return "other"


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def AthleteStatsView(request, athlete_id):
    """Retorna estadísticas detalladas de un atleta para su entrenador."""
    # Validar rol de entrenador
    try:
        request.user.coachprofile
    except CoachProfile.DoesNotExist:
        return Response(
            {"detail": "Solo los entrenadores pueden ver estas estadísticas."},
            status=status.HTTP_403_FORBIDDEN,
        )

    # Obtener atleta
    try:
        athlete = User.objects.get(pk=athlete_id)
        athlete_profile = athlete.athleteprofile
    except (User.DoesNotExist, AthleteProfile.DoesNotExist):
        return Response({"detail": "Atleta no encontrado."}, status=status.HTTP_404_NOT_FOUND)

    now = timezone.now()
    current_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    prev_end = current_start - timedelta(seconds=1)
    prev_start = prev_end.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    # Sesiones por período
    current_sessions = WorkoutSession.objects.filter(user=athlete, date__gte=current_start).count()
    prev_sessions = WorkoutSession.objects.filter(
        user=athlete, date__gte=prev_start, date__lte=prev_end
    ).count()
    session_change = (
        round(((current_sessions - prev_sessions) / prev_sessions) * 100)
        if prev_sessions > 0
        else None
    )

    # Volumen por grupo muscular (últimos 30 días)
    thirty_days_ago = now - timedelta(days=30)
    set_logs = SetLog.objects.filter(
        session__user=athlete,
        session__date__gte=thirty_days_ago,
    ).select_related("exercise")

    upper_volume = 0
    lower_volume = 0
    for sl in set_logs:
        try:
            muscle = sl.exercise.muscle or ""
        except Exception:
            muscle = ""
        classification = _classify_muscle(muscle)
        vol = float(sl.weight or 0) * float(sl.reps or 0)
        if classification == "upper":
            upper_volume += vol
        elif classification == "lower":
            lower_volume += vol

    # Sesiones semanales (últimas 8 semanas)
    weekly_sessions = []
    for i in range(7, -1, -1):
        week_start = (now - timedelta(weeks=i)).replace(hour=0, minute=0, second=0, microsecond=0)
        week_start = week_start - timedelta(days=week_start.weekday())
        week_end = week_start + timedelta(days=7)
        count = WorkoutSession.objects.filter(
            user=athlete, date__gte=week_start, date__lt=week_end
        ).count()
        weekly_sessions.append({"week_start": week_start.date().isoformat(), "count": count})

    # Historial de peso (últimas 8 entradas)
    weight_logs = WeightLog.objects.filter(athlete=athlete_profile).order_by("-date")[:8]
    weight_history = [
        {"date": wl.date.isoformat(), "weight": float(wl.weight)}
        for wl in reversed(list(weight_logs))
    ]

    # Meta activa
    active_goal = (
        Goal.objects.filter(athlete=athlete_profile, is_active=True).order_by("-start_date").first()
    )
    goal_data = None
    if active_goal:
        goal_data = {
            "id": active_goal.id,
            "description": active_goal.description or active_goal.goal_type,
            "target_date": active_goal.deadline.isoformat() if active_goal.deadline else None,
        }

    return Response(
        {
            "athlete": {
                "id": athlete.id,
                "username": athlete.username,
                "full_name": f"{athlete.first_name} {athlete.last_name}".strip(),
                "email": athlete.email,
            },
            "summary": {
                "current_month_sessions": current_sessions,
                "prev_month_sessions": prev_sessions,
                "session_change_pct": session_change,
                "upper_body_volume_kg": round(upper_volume, 1),
                "lower_body_volume_kg": round(lower_volume, 1),
            },
            "weekly_sessions": weekly_sessions,
            "weight_history": weight_history,
            "active_goal": goal_data,
        },
        status=status.HTTP_200_OK,
    )

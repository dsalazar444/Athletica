"""
Servicio para manejar la lógica de otorgamiento de insignias.
Valida metas y otorga badges automáticamente según criterios definidos.

NOTA: Este servicio reutiliza las relaciones existentes del modelo:
- MealRecord: athlete → AthleteProfile → user
- WorkoutSession: user → User (directamente)
- Routine: assigned_athletes (ManyToMany con User, related_name="routines")
"""

from datetime import timedelta

from django.utils import timezone

from nutrition.models import MealRecord
from routines.models import WorkoutSession
from users.models import AthleteProfile, Badge, User, UserBadge


class BadgeService:
    """
    Servicio centralizado para manejar la lógica de badges.
    Proporciona métodos para calcular streaks, validar condiciones y otorgar badges.

    Los streaks se calculan basándose en:
    - Nutrición: Registros únicos por día en MealRecord
    - Ejercicio: Sesiones únicas por día en WorkoutSession
    - Completa: Días con AMBAS actividades (intersección)
    """

    # Configuración de qué streaks corresponden a qué badges
    ALIMENTACION_THRESHOLDS = [1, 3]  # Badges en nivel 1 y 3
    EJERCICIO_THRESHOLDS = [1, 3, 7]  # Badges en nivel 1, 3, 7
    COMPLETA_THRESHOLDS = [1, 3]  # Badges en nivel 1 y 3
    LOGROS_THRESHOLDS = [3]  # Badge en nivel 3 (cuando tienes 3+ badges)

    @staticmethod
    def _get_unique_days_from_queryset(queryset, date_field):
        """
        Utility para obtener un set de fechas únicas de un queryset.

        Args:
            queryset: QuerySet con registros que tienen un campo de fecha
            date_field: Nombre del campo DateField o DateTimeField

        Returns:
            Set de objetos date únicos
        """
        return set(queryset.values_list(date_field, flat=True).distinct())

    @staticmethod
    def get_nutrition_streak(user: User, as_of_date=None) -> int:
        """
        Calcula la racha actual de días consecutivos con registros de alimentación.
        Busca hacia atrás desde as_of_date (hoy si no se especifica).

        Reutiliza: MealRecord model que ya contiene la lógica de relación
                   athlete → AthleteProfile → User

        Retorna: Número de días consecutivos, o 0 si no hay racha activa
        """
        if as_of_date is None:
            as_of_date = timezone.now().date()

        try:
            athlete_profile = user.athleteprofile
        except AthleteProfile.DoesNotExist:
            return 0

        # Obtener todos los días únicos con registros de alimentación
        # MealRecord.date es un DateField, no DateTimeField
        days_with_records = BadgeService._get_unique_days_from_queryset(
            MealRecord.objects.filter(athlete=athlete_profile), "date"
        )

        if not days_with_records:
            return 0

        # Empezar desde as_of_date y contar hacia atrás días consecutivos
        streak = 0
        current_date = as_of_date

        while current_date in days_with_records:
            streak += 1
            current_date -= timedelta(days=1)

        return streak

    @staticmethod
    def get_workout_streak(user: User, as_of_date=None) -> int:
        """
        Calcula la racha actual de días consecutivos con sesiones de entrenamiento.
        Busca hacia atrás desde as_of_date (hoy si no se especifica).

        Reutiliza: WorkoutSession model que vincula directamente con User
                   y almacena la fecha en el campo 'date' (DateTimeField)

        Retorna: Número de días consecutivos, o 0 si no hay racha activa
        """
        if as_of_date is None:
            as_of_date = timezone.now().date()

        # WorkoutSession tiene relación directa con User (no a través de AthleteProfile)
        # Obtener todos los días únicos con sesiones de entrenamiento
        # Convertir DateTimeField a date usando __date lookup
        days_with_workouts = set(
            WorkoutSession.objects.filter(user=user).values_list("date__date", flat=True).distinct()
        )

        if not days_with_workouts:
            return 0

        # Empezar desde as_of_date y contar hacia atrás días consecutivos
        streak = 0
        current_date = as_of_date

        while current_date in days_with_workouts:
            streak += 1
            current_date -= timedelta(days=1)

        return streak

    @staticmethod
    def get_complete_streak(user: User, as_of_date=None) -> int:
        """
        Calcula la racha de días con AMBAS actividades: alimentación y ejercicio.

        Reutiliza:
        - get_nutrition_streak() para obtener días con alimentación
        - get_workout_streak() para obtener días con ejercicio

        Retorna: Número de días consecutivos con ambas actividades, o 0
        """
        if as_of_date is None:
            as_of_date = timezone.now().date()

        try:
            athlete_profile = user.athleteprofile
        except AthleteProfile.DoesNotExist:
            return 0

        # Días con registros de alimentación
        nutrition_days = BadgeService._get_unique_days_from_queryset(
            MealRecord.objects.filter(athlete=athlete_profile), "date"
        )

        # Días con sesiones de entrenamiento
        workout_days = set(
            WorkoutSession.objects.filter(user=user).values_list("date__date", flat=True).distinct()
        )

        # Intersección: días con ambas actividades
        complete_days = nutrition_days & workout_days

        if not complete_days:
            return 0

        # Contar días consecutivos hacia atrás desde as_of_date
        streak = 0
        current_date = as_of_date

        while current_date in complete_days:
            streak += 1
            current_date -= timedelta(days=1)

        return streak

    @staticmethod
    def get_total_badges_count(user: User) -> int:
        """Retorna el total de badges desbloqueados por el usuario."""
        return UserBadge.objects.filter(user=user).count()

    @staticmethod
    def check_and_award_badges(user: User) -> list:
        """
        Valida si el usuario ha cumplido condiciones para nuevas insignias.
        Otorga automáticamente las insignias desbloqueadas.
        Retorna lista de insignias recién otorgadas.
        """
        awarded_badges = []

        # Validar badges de alimentación
        nutrition_streak = BadgeService.get_nutrition_streak(user)
        for level in BadgeService.ALIMENTACION_THRESHOLDS:
            if nutrition_streak >= level:
                badge = Badge.objects.filter(badge_type="alimentacion", level=level).first()
                if badge:
                    user_badge, created = UserBadge.objects.get_or_create(user=user, badge=badge)
                    if created:
                        awarded_badges.append(badge)

        # Validar badges de ejercicio
        workout_streak = BadgeService.get_workout_streak(user)
        for level in BadgeService.EJERCICIO_THRESHOLDS:
            if workout_streak >= level:
                badge = Badge.objects.filter(badge_type="ejercicio", level=level).first()
                if badge:
                    user_badge, created = UserBadge.objects.get_or_create(user=user, badge=badge)
                    if created:
                        awarded_badges.append(badge)

        # Validar badges de racha completa
        complete_streak = BadgeService.get_complete_streak(user)
        for level in BadgeService.COMPLETA_THRESHOLDS:
            if complete_streak >= level:
                badge = Badge.objects.filter(badge_type="completa", level=level).first()
                if badge:
                    user_badge, created = UserBadge.objects.get_or_create(user=user, badge=badge)
                    if created:
                        awarded_badges.append(badge)

        # Validar badges de logros (basado en total de badges obtenidos)
        total_badges = BadgeService.get_total_badges_count(user)
        for level in BadgeService.LOGROS_THRESHOLDS:
            if total_badges >= level:
                badge = Badge.objects.filter(badge_type="logros", level=level).first()
                if badge:
                    # Evitar contar el badge de logros en sí mismo
                    existing = UserBadge.objects.filter(user=user, badge=badge).exists()
                    if not existing:
                        UserBadge.objects.create(user=user, badge=badge)
                        awarded_badges.append(badge)

        return awarded_badges

    @staticmethod
    def get_user_badges_summary(user: User) -> dict:
        """
        Retorna un resumen completo de los badges del usuario:
        - Badges obtenidos
        - Badges próximos a obtener
        - Estadísticas de streaks
        """
        unlocked_badges = UserBadge.objects.filter(user=user).select_related("badge")

        return {
            "total_badges": len(unlocked_badges),
            "unlocked_badges": [
                {
                    "id": ub.badge.id,
                    "type": ub.badge.get_badge_type_display(),
                    "level": ub.badge.level,
                    "name": ub.badge.name,
                    "svg_url": ub.badge.get_svg_url(),
                    "unlocked_at": ub.unlocked_at,
                }
                for ub in unlocked_badges
            ],
            "stats": {
                "nutrition_streak": BadgeService.get_nutrition_streak(user),
                "workout_streak": BadgeService.get_workout_streak(user),
                "complete_streak": BadgeService.get_complete_streak(user),
            },
        }

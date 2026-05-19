"""
Signals para otorgar badges automáticamente cuando se cumplen condiciones.

Se disparan cuando:
- Se crea un MealRecord (para racha de alimentación)
- Se crea un WorkoutSession (para racha de ejercicio)
"""

from django.db.models.signals import post_save
from django.dispatch import receiver

from nutrition.models import MealRecord
from routines.models import WorkoutSession

from .badge_service import BadgeService


@receiver(post_save, sender=MealRecord)
def check_badges_on_meal_record(sender, instance, created, **kwargs):
    """
    Se dispara cuando se crea un registro de alimentación.
    Valida y otorga badges si aplica.
    """
    if created and instance.athlete and instance.athlete.user:
        BadgeService.check_and_award_badges(instance.athlete.user)


@receiver(post_save, sender=WorkoutSession)
def check_badges_on_workout_session(sender, instance, created, **kwargs):
    """
    Se dispara cuando se crea una sesión de entrenamiento.
    Valida y otorga badges si aplica.
    """
    if created and instance.user:
        BadgeService.check_and_award_badges(instance.user)

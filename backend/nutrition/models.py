from django.conf import settings
from django.db import models

from users.models import AthleteProfile


class MealRecord(models.Model):
    """
    Registro de una comida diaria de un atleta.
    Almacena tipo de comida, porción, calorías y macronutrientes.
    """

    MEAL_TYPE_CHOICES = (
        ("breakfast", "Breakfast"),
        ("lunch", "Lunch"),
        ("dinner", "Dinner"),
        ("snack", "Snack"),
    )

    athlete = models.ForeignKey(
        AthleteProfile, on_delete=models.CASCADE, related_name="meal_records"
    )

    meal_type = models.CharField(max_length=20, choices=MEAL_TYPE_CHOICES)
    food_name = models.CharField(max_length=255)

    # Porción en gramos
    portion_grams = models.FloatField()

    calories = models.FloatField()

    # Macronutrientes en gramos — opcionales
    protein_g = models.FloatField(null=True, blank=True)
    carbs_g = models.FloatField(null=True, blank=True)
    fat_g = models.FloatField(null=True, blank=True)

    date = models.DateField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-date", "meal_type"]

    def __str__(self):
        return f"{self.athlete.user.username} — {self.meal_type} ({self.date})"


class NutritionPlan(models.Model):
    coach = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="created_nutrition_plans",
    )
    title = models.CharField(max_length=255, default="")
    assigned_athletes = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name="nutrition_plans",
        blank=True,
    )
    target_calories = models.FloatField()
    protein_g = models.FloatField()
    carbs_g = models.FloatField()
    fat_g = models.FloatField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.title} ({self.coach.username})"

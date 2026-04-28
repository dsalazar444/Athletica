from rest_framework import serializers

from .models import MealRecord, NutritionPlan


class MealRecordSerializer(serializers.ModelSerializer):
    athlete_username = serializers.CharField(source="athlete.user.username", read_only=True)

    class Meta:
        model = MealRecord
        fields = [
            "id",
            "athlete",
            "athlete_username",
            "meal_type",
            "food_name",
            "portion_grams",
            "calories",
            "protein_g",
            "carbs_g",
            "fat_g",
            "date",
            "created_at",
        ]
        read_only_fields = ["id", "created_at", "athlete_username"]


class NutritionPlanSerializer(serializers.ModelSerializer):
    coach_username = serializers.CharField(source="coach.username", read_only=True)
    assigned_count = serializers.SerializerMethodField()

    def get_assigned_count(self, obj):
        return obj.assigned_athletes.count()

    class Meta:
        model = NutritionPlan
        fields = [
            "id",
            "coach",
            "coach_username",
            "title",
            "target_calories",
            "protein_g",
            "carbs_g",
            "fat_g",
            "assigned_count",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "coach", "coach_username", "assigned_count", "created_at", "updated_at"]

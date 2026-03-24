from rest_framework import serializers
from .models import MealRecord


class MealRecordSerializer(serializers.ModelSerializer):
    athlete_username = serializers.CharField(
        source='athlete.user.username', read_only=True
    )

    class Meta:
        model = MealRecord
        fields = [
            'id',
            'athlete',
            'athlete_username',
            'meal_type',
            'food_name',
            'portion_grams',
            'calories',
            'protein_g',
            'carbs_g',
            'fat_g',
            'date',
            'created_at',
        ]
        read_only_fields = ['id', 'created_at', 'athlete_username']
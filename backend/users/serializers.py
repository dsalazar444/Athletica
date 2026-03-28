from django.contrib.auth import get_user_model
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from .models import AthleteProfile, CoachProfile, Goal, User, WeightLog


# Serializer para las metas de un atleta.
class GoalSerializer(serializers.ModelSerializer):
    description = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    target_value = serializers.FloatField(required=False, allow_null=True)
    current_value = serializers.FloatField(required=False, allow_null=True)
    deadline = serializers.DateField(required=False, allow_null=True)

    class Meta:
        model = Goal
        fields = [
            "id",
            "goal_type",
            "description",
            "target_value",
            "current_value",
            "start_date",
            "deadline",
            "is_active",
        ]
        read_only_fields = ["start_date"]


# Serializer para los registros de peso de un atleta.
class WeightLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = WeightLog
        fields = ["id", "weight", "body_fat", "date"]
        read_only_fields = ["date"]


# Serializer para el perfil del atleta.
class AthleteProfileSerializer(serializers.ModelSerializer):
    goals = GoalSerializer(many=True, required=False)
    # Cambiamos weight a weight_logs para coincidir con lo que envía el frontend
    weight_logs = WeightLogSerializer(many=True, required=False, source="weight")

    class Meta:
        model = AthleteProfile
        fields = ["id", "height", "age", "gender", "activity_level", "goals", "weight_logs"]


# Serializer para el perfil del coach.
class CoachProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = CoachProfile
        fields = ["id", "gym_name", "business_address"]


# Serializer para mostrar la informacion de un usuario existente.
class UserSerializer(serializers.ModelSerializer):
    athlete_profile = AthleteProfileSerializer(read_only=True)
    coach_profile = CoachProfileSerializer(read_only=True)

    class Meta:
        model = User
        fields = [
            "id",
            "username",
            "email",
            "first_name",
            "role",
            "athlete_profile",
            "coach_profile",
        ]


# Serializer para el registro de nuevos usuarios.
class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    password2 = serializers.CharField(write_only=True)

    athlete_profile = AthleteProfileSerializer(required=False)
    coach_profile = CoachProfileSerializer(required=False)

    class Meta:
        model = get_user_model()
        fields = [
            "username",
            "email",
            "first_name",
            "password",
            "password2",
            "role",
            "athlete_profile",
            "coach_profile",
        ]

    def validate_email(self, value):
        User = get_user_model()
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("Este email ya esta en uso.")
        return value

    def validate(self, data):
        if data.get("password") != data.get("password2"):
            raise serializers.ValidationError("Las contrasenas no coinciden.")
        return data

    def create(self, validated_data):
        User = get_user_model()
        athlete_data = validated_data.pop("athlete_profile", None)
        coach_data = validated_data.pop("coach_profile", None)
        validated_data.pop("password2")

        user = User.objects.create_user(**validated_data)

        if user.role == "athlete" and athlete_data:
            goals_data = athlete_data.pop("goals", [])
            # Debido a source='weight' en AthleteProfileSerializer, la clave es 'weight'
            weight_logs_data = athlete_data.pop("weight", [])

            athlete = AthleteProfile.objects.create(user=user, **athlete_data)

            for goal in goals_data:
                Goal.objects.create(athlete=athlete, **goal)

            for w_log in weight_logs_data:
                WeightLog.objects.create(athlete=athlete, **w_log)

        if user.role == "coach" and coach_data:
            CoachProfile.objects.create(user=user, **coach_data)

        return user


class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)
        data["first_name"] = self.user.first_name or self.user.username
        return data

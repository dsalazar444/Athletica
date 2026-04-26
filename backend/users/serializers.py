import logging

from django.contrib.auth import get_user_model
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from .models import AthleteProfile, CoachProfile, Goal, User, WeightLog

logger = logging.getLogger(__name__)


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
        fields = ["id", "speciality", "years_experience"]


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
        # Allow login using email by resolving it to a username
        username = attrs.get("username")
        if username and "@" in username:
            try:
                user = User.objects.get(email=username)
                attrs["username"] = user.username
            except User.DoesNotExist:
                # Let super().validate handle the non-existent user case normally
                pass

        data = super().validate(attrs)

        # Add extra data safely
        try:
            data["first_name"] = self.user.first_name or self.user.username
            data["role"] = self.user.role
            data["user_id"] = self.user.id

            if self.user.role == "athlete":
                try:
                    athlete = AthleteProfile.objects.get(user=self.user)
                    data["athlete_id"] = athlete.id
                except AthleteProfile.DoesNotExist:
                    data["athlete_id"] = None
            else:
                data["athlete_id"] = None
        except Exception as e:
            # If for some reason extra field logic fails, don't block the login
            logger.error(f"Error adding extra fields to login data: {e}", exc_info=True)
            pass

        return data


# Serializer para búsqueda de atletas
class AthleteSearchSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source="get_full_name")
    active_routine_id = serializers.SerializerMethodField()
    active_routine_title = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            "id",
            "username",
            "email",
            "name",
            "role",
            "active_routine_id",
            "active_routine_title",
        ]

    def get_active_routine_id(self, obj):
        from routines.models import Routine

        routine = Routine.objects.filter(assigned_athletes=obj).first()
        return routine.id if routine else None

    def get_active_routine_title(self, obj):
        from routines.models import Routine

        routine = Routine.objects.filter(assigned_athletes=obj).first()
        return routine.title if routine else None

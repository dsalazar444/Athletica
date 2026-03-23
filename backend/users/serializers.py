from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import User, AthleteProfile, CoachProfile, Goal, WeightLog


# Serializer para las metas de un atleta.
# Se usa como campo anidado dentro de AthleteProfileSerializer.
class GoalSerializer(serializers.ModelSerializer):
    class Meta:
        model = Goal
        fields = [
            'id', 'goal_type', 'description',
            'target_value', 'current_value',
            'start_date', 'deadline', 'is_active',
        ]
        # La fecha de inicio se asigna automaticamente al crear la meta.
        read_only_fields = ['start_date']


# Serializer para los registros de peso de un atleta.
# Se usa como campo anidado dentro de AthleteProfileSerializer.
class WeightLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = WeightLog
        fields = ['id', 'weight', 'body_fat', 'date']
        # La fecha se asigna automaticamente al crear el registro.
        read_only_fields = ['date']


# Serializer para el perfil del atleta.
# Incluye las metas y registros de peso como campos anidados de solo lectura.
class AthleteProfileSerializer(serializers.ModelSerializer):
    goals = GoalSerializer(many=True, read_only=True)
    weight = WeightLogSerializer(many=True, read_only=True)

    class Meta:
        model = AthleteProfile
        fields = ['id', 'height', 'age', 'gender', 'activity_level', 'goals', 'weight']


# Serializer para el perfil del coach.
class CoachProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = CoachProfile
        fields = ['id', 'gym_name', 'business_address']


# Serializer para mostrar la informacion de un usuario existente.
# Incluye el perfil correspondiente segun su rol (atleta o coach).
class UserSerializer(serializers.ModelSerializer):
    athlete_profile = AthleteProfileSerializer(read_only=True)
    coach_profile   = CoachProfileSerializer(read_only=True)

    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'role',
            'athlete_profile', 'coach_profile',
        ]


# Serializer para el registro de nuevos usuarios.
# Maneja la creacion del usuario y su perfil correspondiente en una sola operacion.
class RegisterSerializer(serializers.ModelSerializer):
    # password es solo de escritura — nunca se devuelve en la respuesta.
    password = serializers.CharField(write_only=True, min_length=8)
    password2 = serializers.CharField(write_only=True)

    # Los perfiles son opcionales segun el rol del usuario.
    athlete_profile = AthleteProfileSerializer(required=False)
    coach_profile   = CoachProfileSerializer(required=False)

    class Meta:
        model = get_user_model()
        fields = [
            'username',
            'email',
            'password',
            'password2',
            'role',
            'athlete_profile',
            'coach_profile',
        ]

    # Verifica que el email no este registrado previamente.
    def validate_email(self, value):
        User = get_user_model()
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError('Este email ya esta en uso.')
        return value

    # Verifica que las dos contrasenas coincidan.
    def validate(self, data):
        if data.get('password') != data.get('password2'):
            raise serializers.ValidationError('Las contrasenas no coinciden.')
        return data

    # Crea el usuario y su perfil correspondiente segun el rol.
    def create(self, validated_data):
        User = get_user_model()

        # Extrae los datos del perfil antes de crear el usuario.
        athlete_data = validated_data.pop('athlete_profile', None)
        coach_data   = validated_data.pop('coach_profile', None)

        # password2 no se necesita para crear el usuario.
        validated_data.pop('password2')

        # Crea el usuario con la contrasena encriptada.
        user = User.objects.create_user(**validated_data)

        # Si es atleta, crea el perfil con sus metas y registros de peso.
        if user.role == 'athlete' and athlete_data:
            goals_data = athlete_data.pop('goals', [])
            weight_logs_data = athlete_data.pop('weight_logs', [])

            athlete = AthleteProfile.objects.create(
                user=user,
                **athlete_data
            )

            # Crea cada meta asociada al perfil del atleta.
            for goal in goals_data:
                Goal.objects.create(
                    athlete=athlete,
                    **goal
                )

            # Crea cada registro de peso asociado al perfil del atleta.
            for weight in weight_logs_data:
                WeightLog.objects.create(
                    athlete=athlete,
                    **weight
                )

        # Si es coach, crea el perfil con los datos del gimnasio.
        if user.role == 'coach' and coach_data:
            CoachProfile.objects.create(user=user, **coach_data)

        return user
from rest_framework import serializers

from routines.models import Exercise, Routine, RoutineExercise
from routines.serializers.serializers_exercise import ExerciseSerializer
from users.models import Follow


# exercise_id: Debe ser el id de un Exercise existente.
# order: El orden del ejercicio en la rutina (entero ≥ 1).
class RoutineExerciseInputSerializer(serializers.Serializer):
    """Valida cada ejercicio que llega dentro del request de crear rutina."""

    external_id = serializers.IntegerField()  # campos que se usan en REST en los serializers para validar y tranformar datos, en este caso, enteros
    order = serializers.IntegerField(min_value=1)

    def validate_external_id(self, external_id):
        """validate that each exercise in routine is created in bd"""
        try:
            exercise = Exercise.objects.get(external_id=external_id)
            return exercise
        except Exercise.DoesNotExist:
            raise serializers.ValidationError("Exercise with this external_id does not exist.")


class RoutineCreateSerializer(serializers.ModelSerializer):
    # Lista de ejercicios de una rutina — write_only porque solo se usa al crear
    # le decimos que use RoutineExercise... para cada elemento de la lista
    # a cada elemento, le aplica el validate_ de esa clase, si todos pasan la validación, se pasa al serializer principal que valida los metodos de esta clase, y luego si sí, se llama a create()
    exercises = RoutineExerciseInputSerializer(many=True, write_only=True)

    class Meta:
        model = Routine
        fields = ["id", "title", "description", "category", "difficulty", "is_public", "exercises"]

    def validate_exercises(self, exercises):
        """Verifica que no vengan dos ejercicios con el mismo orden."""
        orders = [e["order"] for e in exercises]
        if len(orders) != len(set(orders)):
            raise serializers.ValidationError(
                "No puede haber dos ejercicios con el mismo número de orden."
            )
        return exercises

    # hay que nombrar metodo asi, porque con base a nombre, attrs toma un valor, y como attrs no puede ser un campo del modelo por la lógica de func, toca así
    def validate(self, attrs):
        """Valida que el usuario autenticado no tenga otra rutina con el mismo título."""
        request = self.context.get("request")
        user = getattr(request, "user", None)
        title = attrs.get("title")
        if user and title:
            qs = Routine.objects.filter(title=title, created_by=user)
            if self.instance:
                qs = qs.exclude(pk=self.instance.pk)
            if qs.exists():
                raise serializers.ValidationError(
                    f"Ya tienes una rutina con el titulo '{title}'. Ponle otro"
                )
        return attrs

    def validate_assigned_athletes(self, value):
        """Validate that all assigned users are athletes"""

        for user in value:
            if getattr(user, "role", None) != "athlete":
                raise serializers.ValidationError(
                    f"Usuario {user.username} no es un atleta. Solo se pueden asignar rutinas a usuarios Atletas"
                )
        return value

    def create(self, validated_data):
        exercises_data = validated_data.pop("exercises")
        request = self.context.get("request")
        user = getattr(request, "user", None)

        if not user:
            raise serializers.ValidationError("Autenticación requerida para crear una rutina.")

        # Pop created_by if it was passed from perform_create to avoid duplicate argument error
        created_by = validated_data.pop("created_by", user)

        # Crea la rutina primero
        routine = Routine.objects.create(created_by=created_by, **validated_data)
        routine.assigned_athletes.add(user)  # para poner como rutina asignada a él mismo

        # Luego crea las relaciones con los ejercicios
        RoutineExercise.objects.bulk_create(
            [
                RoutineExercise(
                    routine=routine,
                    exercise=item["external_id"],
                    order=item["order"],
                )
                for item in exercises_data
            ]
        )

        return routine


class RoutineDetailSerializer(serializers.ModelSerializer):
    """Para leer una rutina con sus ejercicios completos."""

    exercises = serializers.SerializerMethodField()
    assigned_athletes_count = serializers.IntegerField(
        source="assigned_athletes.count", read_only=True
    )
    assigned_athletes_info = serializers.SerializerMethodField()
    creator_name = serializers.CharField(source="created_by.first_name", read_only=True)
    creator_is_following = serializers.SerializerMethodField()
    likes_count = serializers.SerializerMethodField()
    user_liked = serializers.SerializerMethodField()
    comments_count = serializers.SerializerMethodField()

    class Meta:
        model = Routine
        fields = [
            "id",
            "title",
            "description",
            "category",
            "difficulty",
            "is_public",
            "created_by",
            "creator_name",
            "creator_is_following",
            "exercises",
            "assigned_athletes_count",
            "assigned_athletes_info",
            "likes_count",
            "user_liked",
            "comments_count",
        ]

    def get_exercises(self, routine):
        routine_exercises = routine.routine_exercises.select_related("exercise").all()
        return [
            {
                "order": re.order,
                "exercise": ExerciseSerializer(re.exercise).data,
            }
            for re in routine_exercises
        ]

    def get_assigned_athletes_info(self, routine):
        """Devuelve nombres y IDs de los atletas asignados."""
        return [
            {"id": athlete.id, "first_name": athlete.first_name or athlete.username}
            for athlete in routine.assigned_athletes.all()
        ]

    def get_creator_is_following(self, routine):
        """Verifica si el usuario logueado sigue al creador de la rutina."""

        request = self.context.get("request")
        if not request or not request.user.is_authenticated:
            return False

        if request.user.id == routine.created_by_id:
            return None  # El creador no puede seguirse a sí mismo

        annotated_value = getattr(routine, "is_followed_by_request_user", None)
        if annotated_value is not None:
            return bool(annotated_value)

        return Follow.objects.filter(
            follower=request.user,
            following_id=routine.created_by_id,
        ).exists()

    def get_likes_count(self, routine):
        return routine.reactions.filter(reaction_type="like").count()

    def get_user_liked(self, routine):
        request = self.context.get("request")
        if not request or not request.user.is_authenticated:
            return False
        return routine.reactions.filter(user=request.user, reaction_type="like").exists()

    def get_comments_count(self, routine):
        return routine.comments.filter(parent=None).count()

from rest_framework import serializers

from routines.models import Exercise, Routine, RoutineExercise

# from users.models import User
from routines.serializers.serializers_exercise import ExerciseSerializer


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
        fields = ["id", "title", "description", "category", "difficulty", "exercises"]

    def validate_exercises(self, exercises):
        """Verifica que no vengan dos ejercicios con el mismo orden."""
        orders = [e["order"] for e in exercises]
        if len(orders) != len(set(orders)):
            raise serializers.ValidationError(
                "No puede haber dos ejercicios con el mismo número de orden."
            )
        return exercises

    # hay que nombrar metodo asi, porque con base a nombre, data toma un valor, y como data no puede ser un campo del modelo por la lógica de func, toca así
    def validate(self, data):
        """Valida que el usuario autenticado no tenga otra rutina con el mismo título."""
        request = self.context.get("request")
        user = getattr(request, "user", None)
        # user = User.objects.get(username='daniela')
        title = data.get("title")
        if user and title:
            qs = Routine.objects.filter(title=title, created_by=user)
            if self.instance:
                qs = qs.exclude(pk=self.instance.pk)
            if qs.exists():
                raise serializers.ValidationError(
                    f"Ya tienes una rutina con el titulo '{title}'. Ponle otro"
                )
        return data

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
            raise serializers.ValidationError("Authentication required to create a routine.")

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

    class Meta:
        model = Routine
        fields = [
            "id",
            "title",
            "description",
            "category",
            "difficulty",
            "created_by",
            "creator_name",
            "exercises",
            "assigned_athletes_count",
            "assigned_athletes_info",
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

from rest_framework import serializers

from routines.models import SetLog, WorkoutSession


class SetLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = SetLog
        fields = ["id", "session", "exercise", "set_number", "reps", "weight"]

    def validate_weight(self, value):
        if value < 0:
            raise serializers.ValidationError("El peso no puede ser negativo.")
        return value


class WorkoutSessionSerializer(serializers.ModelSerializer):
    set_logs = SetLogSerializer(many=True, read_only=True)

    class Meta:
        model = WorkoutSession
        fields = ["id", "user", "routine", "date", "set_logs"]
        read_only_fields = ["user"]

    def create(self, validated_data):
        request = self.context.get("request")
        user = getattr(request, "user", None)

        if not user:
            raise serializers.ValidationError("Authentication required to start a session.")

        return WorkoutSession.objects.create(user=user, **validated_data)


class WorkoutHistorySerializer(serializers.ModelSerializer):
    routine_title = serializers.CharField(source="routine.title", read_only=True)

    class Meta:
        model = WorkoutSession
        fields = ["id", "routine", "routine_title", "date"]

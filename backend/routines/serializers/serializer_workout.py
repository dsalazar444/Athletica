from rest_framework import serializers
from routines.models import WorkoutSession, SetLog, Exercise, Routine
from users.models import User

class SetLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = SetLog
        fields = ['id', 'session', 'exercise', 'set_number', 'reps', 'weight']

class WorkoutSessionSerializer(serializers.ModelSerializer):
    set_logs = SetLogSerializer(many=True, read_only=True)

    class Meta:
        model = WorkoutSession
        fields = ['id', 'user', 'routine', 'date', 'set_logs']
        read_only_fields = ['user']

    def create(self, validated_data):
        # Using the same hardcoded user 'daniela' as in RoutineCreateSerializer for now.
        # This should later be replaced by the authenticated request.user.
        user = User.objects.get(username='daniela')
        return WorkoutSession.objects.create(user=user, **validated_data)

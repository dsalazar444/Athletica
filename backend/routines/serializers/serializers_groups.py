from rest_framework import serializers

from routines.models import TrainingGroup
from users.serializers import UserSerializer
from users.models import User


class TrainingGroupSerializer(serializers.ModelSerializer):
    members = UserSerializer(many=True, read_only=True)
    member_ids = serializers.PrimaryKeyRelatedField(
        many=True,
        queryset=User.objects.filter(role="athlete"),
        write_only=True,
        source="members",
        required=False,
    )

    class Meta:
        model = TrainingGroup
        fields = ["id", "name", "members", "member_ids", "created_at"]
        read_only_fields = ["created_at"]

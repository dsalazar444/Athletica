from rest_framework import serializers


class AIRecommendationSerializer(serializers.Serializer):
    exercise_name = serializers.CharField(max_length=255)
    reason = serializers.CharField()
    image_url = serializers.CharField(
        required=False, allow_blank=True
    )  # Changed to CharField as it might be a local path or empty
    exercise_id = serializers.IntegerField(required=False, allow_null=True)
    sets = serializers.IntegerField(default=3)
    reps = serializers.CharField(default="12")
    rest = serializers.IntegerField(default=60)
    muscle = serializers.CharField(default="General")
    youtube_id = serializers.CharField(default="")
    instructions = serializers.CharField(default="")


class RecommendationResponseSerializer(serializers.Serializer):
    recommendations = AIRecommendationSerializer(many=True)
    generated_at = serializers.DateTimeField()

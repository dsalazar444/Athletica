from rest_framework import serializers

from routines.models import Comment


class CommentSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source="user.username", read_only=True)
    user_id = serializers.IntegerField(source="user.id", read_only=True)
    likes_count = serializers.SerializerMethodField()
    user_liked = serializers.SerializerMethodField()
    replies = serializers.SerializerMethodField()

    class Meta:
        model = Comment
        fields = [
            "id",
            "user_id",
            "username",
            "text",
            "created_at",
            "parent",
            "likes_count",
            "user_liked",
            "replies",
        ]
        read_only_fields = [
            "id",
            "user_id",
            "username",
            "created_at",
            "likes_count",
            "user_liked",
            "replies",
        ]

    def get_likes_count(self, comment):
        return comment.reactions.count()

    def get_user_liked(self, comment):
        request = self.context.get("request")
        if not request or not request.user.is_authenticated:
            return False
        return comment.reactions.filter(user=request.user).exists()

    def get_replies(self, comment):
        if comment.parent_id is not None:
            return []
        replies = comment.replies.prefetch_related("reactions").all()
        return CommentSerializer(replies, many=True, context=self.context).data

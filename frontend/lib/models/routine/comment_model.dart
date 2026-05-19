class CommentModel {
  final int id;
  final int userId;
  final String username;
  final String text;
  final DateTime createdAt;
  final int? parentId;
  final int likesCount;
  final bool userLiked;
  final List<CommentModel> replies;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.text,
    required this.createdAt,
    this.parentId,
    this.likesCount = 0,
    this.userLiked = false,
    this.replies = const [],
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
    id: json['id'],
    userId: json['user_id'] ?? 0,
    username: json['username'] ?? 'Usuario',
    text: json['text'],
    createdAt: DateTime.parse(json['created_at']),
    parentId: json['parent'],
    likesCount: json['likes_count'] ?? 0,
    userLiked: json['user_liked'] ?? false,
    replies: (json['replies'] as List? ?? [])
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  CommentModel copyWith({
    int? likesCount,
    bool? userLiked,
    List<CommentModel>? replies,
  }) => CommentModel(
    id: id,
    userId: userId,
    username: username,
    text: text,
    createdAt: createdAt,
    parentId: parentId,
    likesCount: likesCount ?? this.likesCount,
    userLiked: userLiked ?? this.userLiked,
    replies: replies ?? this.replies,
  );
}

class MemberModel {
  final int id;
  final String username;
  final String email;
  final String firstName;

  MemberModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'],
      username: json['username'],
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
    );
  }

  String get displayName => firstName.isNotEmpty ? firstName : username;
}

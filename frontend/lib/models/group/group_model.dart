import '../group/member_model.dart';

class GroupModel {
  final int id;
  final String name;
  final List<MemberModel> members;

  GroupModel({required this.id, required this.name, required this.members});

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'],
      name: json['name'],
      members: (json['members'] as List)
          .map((m) => MemberModel.fromJson(m))
          .toList(),
    );
  }
}

class StudyGroup {
  final String? id;
  final String name;
  final String ownerId;
  final String? courseTag;
  final List<String> members;
  final DateTime createdAt;

  StudyGroup({
    this.id,
    required this.name,
    required this.ownerId,
    this.courseTag,
    this.members = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'courseTag': courseTag,
      'members': members,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StudyGroup.fromMap(String id, Map<String, dynamic> map) {
    return StudyGroup(
      id: id,
      name: map['name'] ?? '',
      ownerId: map['ownerId'] ?? '',
      courseTag: map['courseTag'],
      members: List<String>.from(map['members'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}

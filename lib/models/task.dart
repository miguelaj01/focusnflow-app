class Task {
  final String? id;
  final String uid;
  final String title;
  final DateTime dueDate;
  final double effortHours;
  final double courseWeight;
  final String status; // pending, in_progress, completed
  final String? course;
  final DateTime createdAt;

  Task({
    this.id,
    required this.uid,
    required this.title,
    required this.dueDate,
    this.effortHours = 1.0,
    this.courseWeight = 1.0,
    this.status = 'pending',
    this.course,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'dueDate': dueDate.toIso8601String(),
      'effortHours': effortHours,
      'courseWeight': courseWeight,
      'status': status,
      'course': course,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Task.fromMap(String id, Map<String, dynamic> map) {
    return Task(
      id: id,
      uid: map['uid'] ?? '',
      title: map['title'] ?? '',
      dueDate: DateTime.parse(map['dueDate']),
      effortHours: (map['effortHours'] ?? 1.0).toDouble(),
      courseWeight: (map['courseWeight'] ?? 1.0).toDouble(),
      status: map['status'] ?? 'pending',
      course: map['course'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Task copyWith({
    String? id,
    String? uid,
    String? title,
    DateTime? dueDate,
    double? effortHours,
    double? courseWeight,
    String? status,
    String? course,
  }) {
    return Task(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      effortHours: effortHours ?? this.effortHours,
      courseWeight: courseWeight ?? this.courseWeight,
      status: status ?? this.status,
      course: course ?? this.course,
      createdAt: createdAt,
    );
  }
}

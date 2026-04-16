class ScheduleBlock {
  final String? id;
  final String uid;
  final String taskId;
  final String taskTitle;
  final DateTime startTime;
  final DateTime endTime;
  final String dayOfWeek;
  final bool isConflict;

  ScheduleBlock({
    this.id,
    required this.uid,
    required this.taskId,
    required this.taskTitle,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
    this.isConflict = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'dayOfWeek': dayOfWeek,
      'isConflict': isConflict,
    };
  }

  factory ScheduleBlock.fromMap(String id, Map<String, dynamic> map) {
    return ScheduleBlock(
      id: id,
      uid: map['uid'] ?? '',
      taskId: map['taskId'] ?? '',
      taskTitle: map['taskTitle'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      dayOfWeek: map['dayOfWeek'] ?? '',
      isConflict: map['isConflict'] ?? false,
    );
  }

  Duration get duration => endTime.difference(startTime);
}

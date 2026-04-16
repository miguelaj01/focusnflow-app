class StudyRoom {
  final String? id;
  final String building;
  final String name;
  final int capacity;
  final int occupancyCount;
  final String status; // available, full, closed

  StudyRoom({
    this.id,
    required this.building,
    required this.name,
    required this.capacity,
    this.occupancyCount = 0,
    this.status = 'available',
  });

  Map<String, dynamic> toMap() {
    return {
      'building': building,
      'name': name,
      'capacity': capacity,
      'occupancyCount': occupancyCount,
      'status': status,
    };
  }

  factory StudyRoom.fromMap(String id, Map<String, dynamic> map) {
    return StudyRoom(
      id: id,
      building: map['building'] ?? '',
      name: map['name'] ?? '',
      capacity: map['capacity'] ?? 0,
      occupancyCount: map['occupancyCount'] ?? 0,
      status: map['status'] ?? 'available',
    );
  }

  double get occupancyPercent =>
      capacity > 0 ? occupancyCount / capacity : 0.0;

  bool get isFull => occupancyCount >= capacity;
}

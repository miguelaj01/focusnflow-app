import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';
import '../models/room.dart';
import '../models/group.dart';
import '../models/message.dart';
import '../models/schedule_block.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // tasks
  Stream<List<Task>> getTasks(String uid) {
    return _db
        .collection('tasks')
        .where('uid', isEqualTo: uid)
        .orderBy('dueDate')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Task.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> addTask(Task task) async {
    await _db.collection('tasks').add(task.toMap());
  }

  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    await _db.collection('tasks').doc(id).update(data);
  }

  Future<void> deleteTask(String id) async {
    await _db.collection('tasks').doc(id).delete();
  }

  // rooms
  Stream<List<StudyRoom>> getRooms() {
    return _db.collection('rooms').orderBy('building').snapshots().map((snap) =>
        snap.docs.map((doc) => StudyRoom.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> joinRoom(String roomId) async {
    await _db.collection('rooms').doc(roomId).update({
      'occupancyCount': FieldValue.increment(1),
    });
  }

  Future<void> leaveRoom(String roomId) async {
    await _db.collection('rooms').doc(roomId).update({
      'occupancyCount': FieldValue.increment(-1),
    });
  }

  // groups
  Stream<List<StudyGroup>> getGroups(String uid) {
    return _db
        .collection('groups')
        .where('members', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => StudyGroup.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> createGroup(StudyGroup group) async {
    await _db.collection('groups').add(group.toMap());
  }

  Future<void> joinGroup(String groupId, String uid) async {
    await _db.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> leaveGroup(String groupId, String uid) async {
    await _db.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([uid]),
    });
  }

  // chat messages
  Stream<List<ChatMessage>> getMessages(String groupId) {
    return _db
        .collection('messages')
        .where('groupId', isEqualTo: groupId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChatMessage.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> sendMessage(ChatMessage message) async {
    await _db.collection('messages').add(message.toMap());
  }

  // weekly schedule
  Stream<List<ScheduleBlock>> getSchedule(String uid) {
    return _db
        .collection('weeklySchedules')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ScheduleBlock.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> saveScheduleBlock(ScheduleBlock block) async {
    await _db.collection('weeklySchedules').add(block.toMap());
  }

  Future<void> clearSchedule(String uid) async {
    final snap = await _db
        .collection('weeklySchedules')
        .where('uid', isEqualTo: uid)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  // seed rooms if empty
  Future<void> seedRoomsIfEmpty() async {
    final snap = await _db.collection('rooms').limit(1).get();
    if (snap.docs.isEmpty) {
      final rooms = [
        {'building': 'Library', 'name': 'Room 201', 'capacity': 8, 'occupancyCount': 3, 'status': 'available'},
        {'building': 'Library', 'name': 'Room 305', 'capacity': 12, 'occupancyCount': 12, 'status': 'full'},
        {'building': 'Science Center', 'name': 'Lab A', 'capacity': 6, 'occupancyCount': 2, 'status': 'available'},
        {'building': 'Science Center', 'name': 'Lab B', 'capacity': 6, 'occupancyCount': 0, 'status': 'available'},
        {'building': 'Student Union', 'name': 'Lounge 1', 'capacity': 20, 'occupancyCount': 15, 'status': 'available'},
        {'building': 'Student Union', 'name': 'Study Nook', 'capacity': 4, 'occupancyCount': 4, 'status': 'full'},
        {'building': 'Engineering Hall', 'name': 'Room 110', 'capacity': 10, 'occupancyCount': 0, 'status': 'available'},
        {'building': 'Engineering Hall', 'name': 'Room 220', 'capacity': 8, 'occupancyCount': 5, 'status': 'available'},
      ];
      for (final room in rooms) {
        await _db.collection('rooms').add(room);
      }
    }
  }
}

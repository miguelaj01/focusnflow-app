import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/room.dart';

class RoomFinderScreen extends StatelessWidget {
  const RoomFinderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Study Rooms')),
      body: StreamBuilder<List<StudyRoom>>(
        stream: firestoreService.getRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('error: ${snapshot.error}'));
          }

          final rooms = snapshot.data ?? [];
          if (rooms.isEmpty) {
            return const Center(child: Text('no rooms found'));
          }

          // group by building
          final grouped = <String, List<StudyRoom>>{};
          for (final room in rooms) {
            grouped.putIfAbsent(room.building, () => []).add(room);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      entry.key,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  ...entry.value.map((room) => _RoomCard(room: room)),
                  const SizedBox(height: 8),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final StudyRoom room;

  const _RoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final percent = room.occupancyPercent;
    final isFull = room.isFull;

    Color barColor;
    if (percent < 0.5) {
      barColor = Colors.green;
    } else if (percent < 0.85) {
      barColor = Colors.orange;
    } else {
      barColor = cs.error;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isFull ? Icons.door_front_door : Icons.meeting_room_outlined,
                  color: isFull ? cs.error : cs.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${room.occupancyCount}/${room.capacity} spots taken',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.outline),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFull
                        ? cs.error.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isFull ? 'FULL' : 'OPEN',
                    style: TextStyle(
                      color: isFull ? cs.error : Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: cs.surfaceContainerHighest,
                color: barColor,
                minHeight: 6,
              ),
            ),
            if (!isFull) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    if (room.id != null) {
                      FirestoreService().joinRoom(room.id!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('joined ${room.name}')),
                      );
                    }
                  },
                  icon: const Icon(Icons.login, size: 16),
                  label: const Text('Join Room'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

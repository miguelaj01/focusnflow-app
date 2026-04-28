import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/schedule_block.dart';
import '../services/firestore_service.dart';

class ScheduleScreen extends StatefulWidget {
  final String uid;

  const ScheduleScreen({super.key, required this.uid});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _firestoreService = FirestoreService();
  bool _generating = false;

  Future<void> _generateSchedule() async {
    setState(() => _generating = true);

    try {
      // clear old schedule
      await _firestoreService.clearSchedule(widget.uid);

      // get pending tasks
      final tasksSnap = await _firestoreService
          .getTasks(widget.uid)
          .first;
      final pending =
          tasksSnap.where((t) => t.status != 'completed').toList();

      if (pending.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('no pending tasks to schedule')),
          );
        }
        setState(() => _generating = false);
        return;
      }

      // sort by urgency (due date + weight)
      pending.sort((a, b) {
        final urgencyA = a.courseWeight / (a.dueDate.difference(DateTime.now()).inHours.clamp(1, 9999));
        final urgencyB = b.courseWeight / (b.dueDate.difference(DateTime.now()).inHours.clamp(1, 9999));
        return urgencyB.compareTo(urgencyA);
      });

      // assign blocks across the week
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      int dayIndex = 0;
      int hourSlot = 9; // start at 9am

      for (final task in pending) {
        int hoursLeft = task.effortHours.ceil();
        while (hoursLeft > 0 && dayIndex < 7) {
          final dayDate = startOfWeek.add(Duration(days: dayIndex));
          final start = DateTime(dayDate.year, dayDate.month, dayDate.day, hourSlot);
          final end = start.add(const Duration(hours: 1));

          final block = ScheduleBlock(
            uid: widget.uid,
            taskId: task.id ?? '',
            taskTitle: task.title,
            startTime: start,
            endTime: end,
            dayOfWeek: days[dayIndex],
          );
          await _firestoreService.saveScheduleBlock(block);

          hoursLeft--;
          hourSlot++;
          if (hourSlot >= 18) {
            // past 6pm, move to next day
            hourSlot = 9;
            dayIndex++;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('schedule generated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error: $e')),
        );
      }
    }

    setState(() => _generating = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Schedule'),
        actions: [
          _generating
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.auto_fix_high),
                  tooltip: 'Generate Schedule',
                  onPressed: _generateSchedule,
                ),
        ],
      ),
      body: StreamBuilder<List<ScheduleBlock>>(
        stream: _firestoreService.getSchedule(widget.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final blocks = snapshot.data ?? [];
          if (blocks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month, size: 64, color: cs.outline),
                  const SizedBox(height: 12),
                  Text(
                    'no schedule yet',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: cs.outline),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'tap ✨ to generate from your tasks',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.outline),
                  ),
                ],
              ),
            );
          }

          // group by day
          final grouped = <String, List<ScheduleBlock>>{};
          for (final block in blocks) {
            grouped.putIfAbsent(block.dayOfWeek, () => []).add(block);
          }

          // sort each day's blocks by time
          for (final list in grouped.values) {
            list.sort((a, b) => a.startTime.compareTo(b.startTime));
          }

          final dayOrder = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
          final orderedDays = dayOrder.where((d) => grouped.containsKey(d)).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: orderedDays.map((day) {
              final dayBlocks = grouped[day]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      day,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  ...dayBlocks.map((block) {
                    final timeStr =
                        '${DateFormat('h:mm a').format(block.startTime)} – ${DateFormat('h:mm a').format(block.endTime)}';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        leading: Icon(Icons.schedule, color: cs.primary),
                        title: Text(block.taskTitle),
                        subtitle: Text(
                          timeStr,
                          style: TextStyle(color: cs.outline, fontSize: 12),
                        ),
                      ),
                    );
                  }),
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

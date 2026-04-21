import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/task.dart';
import 'task_entry_screen.dart';
import 'schedule_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid ?? '';
    final firestoreService = FirestoreService();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FocusNFlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Weekly Schedule',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ScheduleScreen(uid: uid)),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Task>>(
        stream: firestoreService.getTasks(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('something went wrong: ${snapshot.error}'),
            );
          }

          final tasks = snapshot.data ?? [];

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 64, color: cs.outline),
                  const SizedBox(height: 12),
                  Text(
                    'no tasks yet',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: cs.outline),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'tap + to add your first task',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.outline),
                  ),
                ],
              ),
            );
          }

          // split tasks
          final pending = tasks.where((t) => t.status != 'completed').toList();
          final completed = tasks.where((t) => t.status == 'completed').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // stats row
              Row(
                children: [
                  _StatCard(
                    icon: Icons.pending_actions,
                    label: 'Pending',
                    value: '${pending.length}',
                    color: cs.primary,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.check_circle_outline,
                    label: 'Done',
                    value: '${completed.length}',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.assignment,
                    label: 'Total',
                    value: '${tasks.length}',
                    color: cs.tertiary,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (pending.isNotEmpty) ...[
                Text(
                  'upcoming tasks',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...pending.map((task) => _TaskCard(task: task, uid: uid)),
              ],
              if (completed.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'completed',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...completed.map((task) => _TaskCard(task: task, uid: uid)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final String uid;

  const _TaskCard({required this.task, required this.uid});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final firestoreService = FirestoreService();
    final isCompleted = task.status == 'completed';
    final dateStr = DateFormat('MMM d').format(task.dueDate);
    final isPastDue = task.dueDate.isBefore(DateTime.now()) && !isCompleted;

    return Dismissible(
      key: Key(task.id ?? task.title),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Task'),
            content: Text('delete "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        if (task.id != null) firestoreService.deleteTask(task.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${task.title}" deleted')),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Checkbox(
            value: isCompleted,
            onChanged: (_) {
              if (task.id != null) {
                firestoreService.updateTask(task.id!, {
                  'status': isCompleted ? 'pending' : 'completed',
                });
              }
            },
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? cs.outline : null,
            ),
          ),
          subtitle: Text(
            '${task.course ?? 'no course'} · due $dateStr · ${task.effortHours}h',
            style: TextStyle(
              color: isPastDue ? cs.error : cs.outline,
              fontSize: 12,
            ),
          ),
          trailing: isPastDue
              ? Icon(Icons.warning_amber_rounded, color: cs.error, size: 20)
              : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TaskEntryScreen(uid: uid, existingTask: task),
              ),
            );
          },
        ),
      ),
    );
  }
}

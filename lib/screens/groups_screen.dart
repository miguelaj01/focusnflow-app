import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/group.dart';
import 'group_chat_screen.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid ?? '';
    final firestoreService = FirestoreService();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(context, uid),
          ),
        ],
      ),
      body: StreamBuilder<List<StudyGroup>>(
        stream: firestoreService.getGroups(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('error: ${snapshot.error}'));
          }

          final groups = snapshot.data ?? [];
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups_outlined, size: 64, color: cs.outline),
                  const SizedBox(height: 12),
                  Text(
                    'no groups yet',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: cs.outline),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'tap + to create a study group',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.outline),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                      style: TextStyle(color: cs.onPrimaryContainer),
                    ),
                  ),
                  title: Text(group.name),
                  subtitle: Text(
                    '${group.members.length} member${group.members.length == 1 ? '' : 's'}${group.courseTag != null ? ' · ${group.courseTag}' : ''}',
                    style: TextStyle(color: cs.outline, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chat_bubble_outline, size: 20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupChatScreen(
                          group: group,
                          uid: uid,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, String uid) {
    final nameController = TextEditingController();
    final courseController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Study Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: courseController,
              decoration: const InputDecoration(
                labelText: 'Course Tag (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              final group = StudyGroup(
                name: nameController.text.trim(),
                ownerId: uid,
                courseTag: courseController.text.trim().isEmpty
                    ? null
                    : courseController.text.trim(),
                members: [uid],
              );
              await FirestoreService().createGroup(group);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('create'),
          ),
        ],
      ),
    );
  }
}

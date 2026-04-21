import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/firestore_service.dart';

class TaskEntryScreen extends StatefulWidget {
  final String uid;
  final Task? existingTask;

  const TaskEntryScreen({super.key, required this.uid, this.existingTask});

  @override
  State<TaskEntryScreen> createState() => _TaskEntryScreenState();
}

class _TaskEntryScreenState extends State<TaskEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _courseController = TextEditingController();
  final _effortController = TextEditingController();
  final _firestoreService = FirestoreService();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));
  double _courseWeight = 1.0;
  bool _saving = false;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.existingTask!;
      _titleController.text = t.title;
      _courseController.text = t.course ?? '';
      _effortController.text = t.effortHours.toString();
      _dueDate = t.dueDate;
      _courseWeight = t.courseWeight;
    } else {
      _effortController.text = '1.0';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final task = Task(
        uid: widget.uid,
        title: _titleController.text.trim(),
        dueDate: _dueDate,
        effortHours: double.tryParse(_effortController.text) ?? 1.0,
        courseWeight: _courseWeight,
        course: _courseController.text.trim().isEmpty
            ? null
            : _courseController.text.trim(),
        status: widget.existingTask?.status ?? 'pending',
      );

      if (_isEditing) {
        await _firestoreService.updateTask(widget.existingTask!.id!, task.toMap());
      } else {
        await _firestoreService.addTask(task);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _courseController.dispose();
    _effortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _courseController,
                decoration: const InputDecoration(
                  labelText: 'Course (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
              const SizedBox(height: 16),
              // due date
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                ),
                leading: const Icon(Icons.calendar_today),
                title: const Text('Due Date'),
                subtitle: Text(DateFormat('EEEE, MMM d, yyyy').format(_dueDate)),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _effortController,
                decoration: const InputDecoration(
                  labelText: 'Effort (hours)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'enter effort hours';
                  if (double.tryParse(v) == null) return 'enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // course weight slider
              Text('Course Weight: ${_courseWeight.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.bodyMedium),
              Slider(
                value: _courseWeight,
                min: 0.5,
                max: 5.0,
                divisions: 9,
                label: _courseWeight.toStringAsFixed(1),
                onChanged: (v) => setState(() => _courseWeight = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Save Changes' : 'Add Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

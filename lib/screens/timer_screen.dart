import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group.dart';

class TimerScreen extends StatefulWidget {
  final StudyGroup group;

  const TimerScreen({super.key, required this.group});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  static const int _focusMinutes = 25;
  static const int _breakMinutes = 5;

  final _db = FirebaseFirestore.instance;
  Timer? _localTimer;

  int _secondsRemaining = _focusMinutes * 60;
  bool _isRunning = false;
  bool _isFocusPhase = true;

  DocumentReference get _sessionDoc =>
      _db.collection('sessions').doc(widget.group.id);

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  // create session doc if it doesn't exist
  Future<void> _initSession() async {
    final doc = await _sessionDoc.get();
    if (!doc.exists) {
      await _sessionDoc.set({
        'groupId': widget.group.id,
        'secondsRemaining': _focusMinutes * 60,
        'isRunning': false,
        'isFocusPhase': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  void _startPause() async {
    final doc = await _sessionDoc.get();
    final data = doc.data() as Map<String, dynamic>?;
    final running = data?['isRunning'] ?? false;

    if (running) {
      // pause
      _localTimer?.cancel();
      await _sessionDoc.update({
        'isRunning': false,
        'secondsRemaining': _secondsRemaining,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } else {
      // start
      await _sessionDoc.update({
        'isRunning': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      _startLocalTimer();
    }
  }

  void _startLocalTimer() {
    _localTimer?.cancel();
    _localTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
        // sync to firestore every 5 seconds
        if (_secondsRemaining % 5 == 0) {
          await _sessionDoc.update({
            'secondsRemaining': _secondsRemaining,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      } else {
        _localTimer?.cancel();
        final newPhase = !_isFocusPhase;
        final newSeconds = (newPhase ? _focusMinutes : _breakMinutes) * 60;
        await _sessionDoc.update({
          'isRunning': false,
          'isFocusPhase': newPhase,
          'secondsRemaining': newSeconds,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newPhase ? 'break over! time to focus' : 'nice work! take a break',
              ),
            ),
          );
        }
      }
    });
  }

  void _reset() async {
    _localTimer?.cancel();
    await _sessionDoc.update({
      'isRunning': false,
      'isFocusPhase': true,
      'secondsRemaining': _focusMinutes * 60,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _localTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.group.name} · Timer'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _sessionDoc.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            _isRunning = data['isRunning'] ?? false;
            _isFocusPhase = data['isFocusPhase'] ?? true;

            // sync from firestore if not running locally
            if (!_isRunning || _localTimer == null || !_localTimer!.isActive) {
              _secondsRemaining = data['secondsRemaining'] ?? _focusMinutes * 60;
            }

            // if running remotely but not locally, start local timer
            if (_isRunning && (_localTimer == null || !_localTimer!.isActive)) {
              Future.microtask(() => _startLocalTimer());
            }
          }

          final progress = 1 -
              (_secondsRemaining /
                  ((_isFocusPhase ? _focusMinutes : _breakMinutes) * 60));

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // phase label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isFocusPhase
                        ? cs.primaryContainer
                        : Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isFocusPhase ? '🎯 Focus Time' : '☕ Break Time',
                    style: TextStyle(
                      color: _isFocusPhase ? cs.primary : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // synced indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sync, size: 14, color: cs.outline),
                    const SizedBox(width: 4),
                    Text(
                      'synced across group members',
                      style: TextStyle(fontSize: 11, color: cs.outline),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // circular timer
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CircularProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          strokeWidth: 8,
                          backgroundColor: cs.surfaceContainerHighest,
                          color: _isFocusPhase ? cs.primary : Colors.green,
                        ),
                      ),
                      Text(
                        _formatTime(_secondsRemaining),
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _startPause,
                      icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                      label: Text(_isRunning ? 'Pause' : 'Start'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  '25 min focus · 5 min break',
                  style: TextStyle(color: cs.outline, fontSize: 13),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

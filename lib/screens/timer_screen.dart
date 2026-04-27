import 'dart:async';
import 'package:flutter/material.dart';
import '../models/group.dart';

class TimerScreen extends StatefulWidget {
  final StudyGroup group;

  const TimerScreen({super.key, required this.group});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  // pomodoro defaults
  static const int _focusMinutes = 25;
  static const int _breakMinutes = 5;

  int _secondsRemaining = _focusMinutes * 60;
  bool _isRunning = false;
  bool _isFocusPhase = true;
  Timer? _timer;

  void _startPause() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          _timer?.cancel();
          setState(() {
            _isRunning = false;
            _isFocusPhase = !_isFocusPhase;
            _secondsRemaining =
                (_isFocusPhase ? _focusMinutes : _breakMinutes) * 60;
          });
          // notify
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isFocusPhase ? 'break over! time to focus' : 'nice work! take a break',
              ),
            ),
          );
        }
      });
      setState(() => _isRunning = true);
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isFocusPhase = true;
      _secondsRemaining = _focusMinutes * 60;
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = 1 -
        (_secondsRemaining /
            ((_isFocusPhase ? _focusMinutes : _breakMinutes) * 60));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.group.name} · Timer'),
      ),
      body: Center(
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
            const SizedBox(height: 32),
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
                      value: progress,
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
      ),
    );
  }
}

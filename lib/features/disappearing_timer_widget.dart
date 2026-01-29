import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Виджет для отображения таймера исчезающих сообщений
class DisappearingTimerWidget extends StatefulWidget {
  final DateTime expiresAt;
  final DateTime createdAt;

  const DisappearingTimerWidget({
    super.key,
    required this.expiresAt,
    required this.createdAt,
  });

  @override
  State<DisappearingTimerWidget> createState() => _DisappearingTimerWidgetState();
}

class _DisappearingTimerWidgetState extends State<DisappearingTimerWidget> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateRemaining();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final now = DateTime.now();
    if (now.isAfter(widget.expiresAt)) {
      setState(() {
        _remaining = Duration.zero;
      });
      _timer?.cancel();
      return;
    }
    
    setState(() {
      _remaining = widget.expiresAt.difference(now);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.isNegative || _remaining == Duration.zero) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          CupertinoIcons.timer,
          size: 12,
          color: Colors.white.withOpacity(0.6),
        ),
        const SizedBox(width: 4),
        Text(
          _formatDuration(_remaining),
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}д';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}ч';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}м';
    } else {
      return '${duration.inSeconds}с';
    }
  }
}


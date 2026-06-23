import 'package:flutter/material.dart';

class RecordingControls extends StatelessWidget {
  final bool isRecording;
  final int pointCount;
  final Duration elapsed;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const RecordingControls({
    super.key,
    required this.isRecording,
    required this.pointCount,
    required this.elapsed,
    required this.onStart,
    required this.onStop,
  });

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            // 記録中インジケータ
            _RecordingDot(isRecording: isRecording),
            const SizedBox(width: 12),
            // 統計
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isRecording ? '記録中' : '停止中',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isRecording
                          ? Colors.red.shade700
                          : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatDuration(elapsed)}  /  $pointCount点',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            // ボタン
            FilledButton.icon(
              onPressed: isRecording ? onStop : onStart,
              icon: Icon(isRecording ? Icons.stop : Icons.fiber_manual_record),
              label: Text(isRecording ? '停止' : '開始'),
              style: FilledButton.styleFrom(
                backgroundColor: isRecording
                    ? Colors.grey.shade700
                    : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 記録中の赤い点滅ドット
class _RecordingDot extends StatefulWidget {
  final bool isRecording;
  const _RecordingDot({required this.isRecording});

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.isRecording
          ? Tween(begin: 0.3, end: 1.0).animate(_ctrl)
          : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isRecording ? Colors.red : Colors.grey.shade400,
        ),
      ),
    );
  }
}

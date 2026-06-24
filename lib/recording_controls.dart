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
            _RecordingDot(isRecording: isRecording),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isRecording ? '散歩中' : '停止中',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isRecording
                          ? Colors.green.shade700
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
            _WalkActionButton(
              isRecording: isRecording,
              onStart: onStart,
              onStop: onStop,
            ),
          ],
        ),
      ),
    );
  }
}

/// 散歩開始/終了の切り替えボタン。
///
/// コンパクトな縦長レイアウト(アイコンの下に小さいラベル)で、
/// 横幅を取りすぎないように設計してある。
class _WalkActionButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _WalkActionButton({
    required this.isRecording,
    required this.onStart,
    required this.onStop,
  });

  @override
  State<_WalkActionButton> createState() => _WalkActionButtonState();
}

class _WalkActionButtonState extends State<_WalkActionButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final recording = widget.isRecording;

    // 状態ごとの色と表示内容
    final gradient = recording
        ? const [Color(0xFF9E9E9E), Color(0xFF616161)]
        : const [Color(0xFF66BB6A), Color(0xFF2E7D32)];
    final shadowColor = recording
        ? const Color(0xFF616161)
        : const Color(0xFF2E7D32);
    final icon = recording ? Icons.stop_rounded : Icons.directions_walk_rounded;
    final label = recording ? '散歩終了' : '散歩開始';

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: recording ? widget.onStop : widget.onStart,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: 68,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: _pressed ? 0.2 : 0.4),
                blurRadius: _pressed ? 6 : 12,
                offset: Offset(0, _pressed ? 2 : 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
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
          color: widget.isRecording ? Colors.green : Colors.grey.shade400,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'map_mode.dart';

class ModeSwitcher extends StatelessWidget {
  final MapMode currentMode;
  final ValueChanged<MapMode> onModeChanged;

  const ModeSwitcher({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: SegmentedButton<MapMode>(
        segments: const [
          ButtonSegment(
            value: MapMode.normal,
            label: Text('通常'),
            icon: Icon(Icons.map_outlined),
          ),
          ButtonSegment(
            value: MapMode.fog,
            label: Text('霧'),
            icon: Icon(Icons.cloud_outlined),
          ),
          ButtonSegment(
            value: MapMode.animation,
            label: Text('再生'),
            icon: Icon(Icons.play_arrow_outlined),
          ),
        ],
        selected: {currentMode},
        onSelectionChanged: (s) => onModeChanged(s.first),
        showSelectedIcon: false,
      ),
    );
  }
}

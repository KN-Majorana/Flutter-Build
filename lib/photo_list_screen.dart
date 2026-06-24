import 'dart:io';
import 'package:flutter/material.dart';
import 'collage_module.dart';
import 'color_module.dart';
import 'photo_pin.dart';

/// 撮影した写真をグリッド表示する一覧画面。
/// 代表色によるフィルタリングと、3種類のコラージュ画面起動が可能。
class PhotoListScreen extends StatefulWidget {
  final List<PhotoPin> photoPins;
  const PhotoListScreen({super.key, required this.photoPins});

  @override
  State<PhotoListScreen> createState() => _PhotoListScreenState();
}

class _PhotoListScreenState extends State<PhotoListScreen> {
  int? _selectedColorId;

  List<PhotoPin> get _filteredPins {
    if (_selectedColorId == null) return widget.photoPins;
    return widget.photoPins
        .where((pin) => pin.colorIds.contains(_selectedColorId))
        .toList();
  }

  /// 現在の選択写真からコラージュ画面を開く
  /// type: 0=自動配置, 1=自由配置, 2=テンプレ(自前で写真を選ぶので imagePaths は不要)
  void _openCollage(int type) {
    final paths = _filteredPins.map((p) => p.imagePath).toList();

    if (type != 2 && paths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('対象の写真がありません')),
      );
      return;
    }

    Widget page;
    switch (type) {
      case 0:
        page = AutoCollagePage(imagePaths: paths);
        break;
      case 1:
        page = EditableCollagePage(imagePaths: paths);
        break;
      default:
        page = const GridCollagePage();
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _buildColorFilterBar() {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: const Text('すべて'),
              selected: _selectedColorId == null,
              onSelected: (_) => setState(() => _selectedColorId = null),
            ),
          ),
          for (int i = 0; i < colorPalette24.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildColorChip(i),
            ),
        ],
      ),
    );
  }

  Widget _buildColorChip(int colorId) {
    final c = colorPalette24[colorId];
    final color = Color.fromRGBO(c.r, c.g, c.b, 1.0);
    final isSelected = _selectedColorId == colorId;

    // 明るい色用に文字色を切り替える
    final brightness = (c.r * 299 + c.g * 587 + c.b * 114) / 1000;
    final textColor = brightness > 150 ? Colors.black87 : Colors.white;

    return ChoiceChip(
      label: Text(
        colorNames24[colorId],
        style: TextStyle(
          color: isSelected ? textColor : Colors.black87,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      backgroundColor: color.withValues(alpha: 0.25),
      selectedColor: color,
      side: BorderSide(color: color, width: 1),
      onSelected: (sel) {
        setState(() {
          _selectedColorId = sel ? colorId : null;
        });
      },
    );
  }

  Widget _buildCollageButtons() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openCollage(0),
                icon: const Icon(Icons.auto_awesome_mosaic, size: 18),
                label: const Text('自動'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openCollage(1),
                icon: const Icon(Icons.dashboard_customize, size: 18),
                label: const Text('自由'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openCollage(2),
                icon: const Icon(Icons.grid_view, size: 18),
                label: const Text('テンプレ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPins;

    return Scaffold(
      appBar: AppBar(
        title: const Text('撮影した写真'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildColorFilterBar(),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.camera_alt_outlined,
                          size: 64,
                          color: Colors.black26,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedColorId == null
                              ? 'まだ写真がありません'
                              : 'この色を含む写真はありません',
                          style: const TextStyle(color: Colors.black45),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final pin = filtered[index];
                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(File(pin.imagePath)),
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(pin.imagePath),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          _buildCollageButtons(),
        ],
      ),
    );
  }
}

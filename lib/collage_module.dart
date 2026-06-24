import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

// =====================================================
// 共通：背景色
// =====================================================

Color getCollageBackgroundColorByColorId(int colorId) {
  switch (colorId) {
    case 0:
      return const Color(0xFFD6D6D6);
    case 1:
      return const Color(0xFFCCCCCC);
    case 2:
      return const Color(0xFFE0E0E0);
    case 3:
      return const Color(0xFFF2E8D8);
    case 4:
    case 5:
      return const Color(0xFFFFCFCF);
    case 6:
      return const Color(0xFFFFD6E5);
    case 7:
    case 23:
      return const Color(0xFFFFD9B3);
    case 8:
    case 9:
      return const Color(0xFFFFED99);
    case 10:
    case 11:
      return const Color(0xFFDDF4B5);
    case 12:
    case 13:
      return const Color(0xFFCFE8CF);
    case 14:
      return const Color(0xFFC9F3F3);
    case 15:
      return const Color(0xFFCDEFFF);
    case 16:
    case 17:
      return const Color(0xFFD3E0FF);
    case 18:
      return const Color(0xFFE4D4FF);
    case 19:
      return const Color(0xFFFFD1FF);
    case 20:
    case 21:
      return const Color(0xFFE0C3A3);
    case 22:
      return const Color(0xFFEAD3B0);
    default:
      return const Color(0xFFF0DFC8);
  }
}

// =====================================================
// 共通：Widgetを画像として写真フォルダに保存
// =====================================================

Future<void> saveWidgetToGallery({
  required BuildContext context,
  required GlobalKey repaintKey,
  required String fileNamePrefix,
}) async {
  try {
    final boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) return;

    final ui.Image image = await boundary.toImage(pixelRatio: 2.5);

    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) return;

    final Uint8List pngBytes = byteData.buffer.asUint8List();

    await ImageGallerySaverPlus.saveImage(
      pngBytes,
      quality: 100,
      name: '${fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('コラージュを写真フォルダに保存しました'),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('保存に失敗しました: $e'),
      ),
    );
  }
}

// =====================================================
// 共通：テスト画像生成
// =====================================================

Future<List<String>> createTestImages() async {
  final dir = await getApplicationDocumentsDirectory();
  final testDir = Directory('${dir.path}/test_images');

  if (!await testDir.exists()) {
    await testDir.create(recursive: true);
  }

  final testColors = [
    img.ColorRgb8(0, 0, 0),
    img.ColorRgb8(255, 0, 0),
    img.ColorRgb8(0, 255, 0),
    img.ColorRgb8(0, 0, 255),
    img.ColorRgb8(255, 255, 0),
    img.ColorRgb8(255, 0, 255),
    img.ColorRgb8(0, 255, 255),
    img.ColorRgb8(255, 220, 177),
  ];

  final paths = <String>[];

  for (int i = 0; i < testColors.length; i++) {
    final image = img.Image(width: 300, height: 300);
    img.fill(image, color: testColors[i]);

    final file = File('${testDir.path}/test_$i.jpg');
    await file.writeAsBytes(img.encodeJpg(image));

    paths.add(file.path);
  }

  return paths;
}

// ##########################################################################
// コラージュ1：自動配置コラージュ
// ##########################################################################

class AutoCollageSlot {
  final double x;
  final double y;
  final double w;
  final double h;
  final double angle;

  const AutoCollageSlot({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.angle,
  });
}

List<AutoCollageSlot> createAutoSlots({
  required int imageCount,
  required double canvasWidth,
  required double canvasHeight,
}) {
  if (imageCount <= 0) return [];

  if (imageCount == 1) {
    return [
      const AutoCollageSlot(x: 150, y: 250, w: 600, h: 520, angle: -0.025),
    ];
  }

  if (imageCount == 2) {
    return [
      const AutoCollageSlot(x: 110, y: 210, w: 390, h: 500, angle: -0.055),
      const AutoCollageSlot(x: 410, y: 390, w: 390, h: 500, angle: 0.055),
    ];
  }

  if (imageCount == 3) {
    return [
      const AutoCollageSlot(x: 95, y: 130, w: 500, h: 380, angle: -0.045),
      const AutoCollageSlot(x: 540, y: 500, w: 280, h: 300, angle: 0.06),
      const AutoCollageSlot(x: 120, y: 680, w: 390, h: 300, angle: 0.035),
    ];
  }

  if (imageCount == 4) {
    return [
      const AutoCollageSlot(x: 70, y: 120, w: 410, h: 310, angle: -0.045),
      const AutoCollageSlot(x: 500, y: 160, w: 320, h: 360, angle: 0.045),
      const AutoCollageSlot(x: 100, y: 610, w: 330, h: 340, angle: 0.05),
      const AutoCollageSlot(x: 455, y: 590, w: 380, h: 300, angle: -0.04),
    ];
  }

  if (imageCount == 5) {
    return [
      const AutoCollageSlot(x: 250, y: 260, w: 400, h: 360, angle: -0.02),
      const AutoCollageSlot(x: 65, y: 95, w: 300, h: 240, angle: -0.06),
      const AutoCollageSlot(x: 565, y: 120, w: 270, h: 270, angle: 0.055),
      const AutoCollageSlot(x: 90, y: 700, w: 310, h: 260, angle: 0.04),
      const AutoCollageSlot(x: 520, y: 710, w: 300, h: 250, angle: -0.05),
    ];
  }

  if (imageCount == 6) {
    return [
      const AutoCollageSlot(x: 70, y: 90, w: 390, h: 300, angle: -0.045),
      const AutoCollageSlot(x: 470, y: 120, w: 350, h: 300, angle: 0.04),
      const AutoCollageSlot(x: 90, y: 450, w: 260, h: 270, angle: 0.055),
      const AutoCollageSlot(x: 380, y: 430, w: 330, h: 290, angle: -0.035),
      const AutoCollageSlot(x: 80, y: 780, w: 340, h: 240, angle: -0.03),
      const AutoCollageSlot(x: 475, y: 760, w: 330, h: 260, angle: 0.045),
    ];
  }

  if (imageCount == 7) {
    return [
      const AutoCollageSlot(x: 50, y: 55, w: 340, h: 250, angle: -0.065),
      const AutoCollageSlot(x: 430, y: 80, w: 360, h: 260, angle: 0.055),
      const AutoCollageSlot(x: 95, y: 360, w: 390, h: 280, angle: 0.045),
      const AutoCollageSlot(x: 510, y: 380, w: 300, h: 310, angle: -0.055),
      const AutoCollageSlot(x: 55, y: 730, w: 300, h: 250, angle: 0.04),
      const AutoCollageSlot(x: 365, y: 730, w: 270, h: 270, angle: -0.045),
      const AutoCollageSlot(x: 650, y: 705, w: 220, h: 300, angle: 0.065),
    ];
  }

  if (imageCount == 8) {
    return [
      const AutoCollageSlot(x: 285, y: 340, w: 330, h: 310, angle: -0.015),
      const AutoCollageSlot(x: 55, y: 70, w: 280, h: 230, angle: -0.06),
      const AutoCollageSlot(x: 360, y: 80, w: 260, h: 230, angle: 0.035),
      const AutoCollageSlot(x: 635, y: 95, w: 220, h: 270, angle: 0.06),
      const AutoCollageSlot(x: 60, y: 380, w: 230, h: 290, angle: 0.05),
      const AutoCollageSlot(x: 625, y: 450, w: 240, h: 280, angle: -0.045),
      const AutoCollageSlot(x: 95, y: 760, w: 300, h: 250, angle: -0.035),
      const AutoCollageSlot(x: 470, y: 765, w: 330, h: 245, angle: 0.04),
    ];
  }

  if (imageCount == 9) {
    return [
      const AutoCollageSlot(x: 55, y: 60, w: 250, h: 240, angle: -0.05),
      const AutoCollageSlot(x: 325, y: 85, w: 250, h: 240, angle: 0.035),
      const AutoCollageSlot(x: 595, y: 65, w: 250, h: 240, angle: 0.055),
      const AutoCollageSlot(x: 75, y: 375, w: 250, h: 240, angle: 0.04),
      const AutoCollageSlot(x: 325, y: 365, w: 270, h: 260, angle: -0.025),
      const AutoCollageSlot(x: 615, y: 390, w: 230, h: 250, angle: -0.045),
      const AutoCollageSlot(x: 60, y: 720, w: 260, h: 240, angle: -0.035),
      const AutoCollageSlot(x: 335, y: 740, w: 250, h: 235, angle: 0.05),
      const AutoCollageSlot(x: 610, y: 715, w: 250, h: 250, angle: 0.03),
    ];
  }

  final columns = imageCount <= 12 ? 4 : 5;
  final rows = (imageCount / columns).ceil();

  const margin = 45.0;
  const gap = 24.0;

  final usableWidth = canvasWidth - margin * 2 - gap * (columns - 1);
  final usableHeight = canvasHeight - margin * 2 - gap * (rows - 1);

  final cellWidth = usableWidth / columns;
  final cellHeight = usableHeight / rows;

  final slots = <AutoCollageSlot>[];

  for (int i = 0; i < imageCount; i++) {
    final row = i ~/ columns;
    final col = i % columns;

    final shiftX = [-10.0, 8.0, -6.0, 12.0, -8.0, 5.0][i % 6];
    final shiftY = [6.0, -8.0, 10.0, -5.0, 4.0, -4.0][i % 6];

    final angle = [-0.05, 0.035, -0.03, 0.05, -0.025, 0.03][i % 6];

    slots.add(
      AutoCollageSlot(
        x: margin + col * (cellWidth + gap) + shiftX,
        y: margin + row * (cellHeight + gap) + shiftY,
        w: cellWidth,
        h: cellHeight,
        angle: angle,
      ),
    );
  }

  return slots;
}

class ScrapbookCollage extends StatelessWidget {
  final List<String> imagePaths;
  final int colorId;

  const ScrapbookCollage({
    super.key,
    required this.imagePaths,
    this.colorId = 12,
  });

  @override
  Widget build(BuildContext context) {
    const canvasWidth = 900.0;
    const canvasHeight = 1100.0;

    final slots = createAutoSlots(
      imageCount: imagePaths.length,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
    );

    final count = min(imagePaths.length, slots.length);
    final backgroundColor = getCollageBackgroundColorByColorId(colorId);

    return Container(
      width: canvasWidth,
      height: canvasHeight,
      color: backgroundColor,
      child: Stack(
        children: [
          for (int i = 0; i < count; i++)
            Positioned(
              left: slots[i].x,
              top: slots[i].y,
              child: Transform.rotate(
                angle: slots[i].angle,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFCF7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(6, 6),
                      ),
                    ],
                  ),
                  child: Image.file(
                    File(imagePaths[i]),
                    width: slots[i].w,
                    height: slots[i].h,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AutoCollagePage extends StatelessWidget {
  final List<String> imagePaths;
  final String title;

  AutoCollagePage({
    super.key,
    required this.imagePaths,
    this.title = 'コラージュ1：自動配置',
  });

  final GlobalKey captureKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: 320,
              child: FittedBox(
                fit: BoxFit.contain,
                child: RepaintBoundary(
                  key: captureKey,
                  child: ScrapbookCollage(
                    imagePaths: imagePaths,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                saveWidgetToGallery(
                  context: context,
                  repaintKey: captureKey,
                  fileNamePrefix: 'auto_collage',
                );
              },
              icon: const Icon(Icons.save_alt),
              label: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}

// ##########################################################################
// コラージュ2：自由配置＋トリミングあり
// ##########################################################################

enum FreeCropShape {
  rectangle,
  roundedRectangle,
  circle,
}

class FreeCollagePhoto {
  final String imagePath;

  double x;
  double y;
  double width;
  double height;
  double angle;

  FreeCropShape cropShape;
  Rect cropRectNormalized;
  bool hasCrop;

  // トリミング枠だけの回転角度
  double cropAngle;

  // 回転前の実際のトリミング枠サイズ
  double cropFrameWidth;
  double cropFrameHeight;

  int imagePixelWidth;
  int imagePixelHeight;

  FreeCollagePhoto({
    required this.imagePath,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.angle = 0.0,
    this.cropShape = FreeCropShape.rectangle,
    this.cropRectNormalized = const Rect.fromLTWH(0, 0, 1, 1),
    this.hasCrop = false,
    this.cropAngle = 0.0,
    double? cropFrameWidth,
    double? cropFrameHeight,
    this.imagePixelWidth = 1,
    this.imagePixelHeight = 1,
  })  : cropFrameWidth = cropFrameWidth ?? width,
        cropFrameHeight = cropFrameHeight ?? height;
}

class EditableCollagePage extends StatefulWidget {
  final List<String> imagePaths;

  const EditableCollagePage({
    super.key,
    required this.imagePaths,
  });

  @override
  State<EditableCollagePage> createState() => _EditableCollagePageState();
}

class _EditableCollagePageState extends State<EditableCollagePage> {
  static const double canvasWidth = 900.0;
  static const double canvasHeight = 1100.0;
  static const double displayWidth = 320.0;

  static const double displayScale = displayWidth / canvasWidth;
  static const double touchScale = canvasWidth / displayWidth;

  final GlobalKey captureKey = GlobalKey();

  late List<FreeCollagePhoto> photos;

  int selectedIndex = -1;
  Offset? lastPanGlobalPosition;

  bool isCropOverlayOpen = false;
  bool isLoadingCropImage = false;
  bool isSavingFreeCollage = false;

  FreeCropShape editingCropShape = FreeCropShape.rectangle;
  Rect editingCropRectNormalized = const Rect.fromLTWH(0.15, 0.15, 0.7, 0.7);

  double editingCropAngle = 0.0;

  int editingImagePixelWidth = 1;
  int editingImagePixelHeight = 1;

  double cropEditorWidth = 260.0;
  double cropEditorHeight = 260.0;

  final List<Color> backgroundPalette = const [
    Color(0xFFFFD6E5),
    Color(0xFFFFCFCF),
    Color(0xFFFFD9B3),
    Color(0xFFFFED99),
    Color(0xFFDDF4B5),
    Color(0xFFCFE8CF),
    Color(0xFFC9F3F3),
    Color(0xFFCDEFFF),
    Color(0xFFD3E0FF),
    Color(0xFFE4D4FF),
    Color(0xFFFFD1FF),
    Color(0xFFE0C3A3),
    Color(0xFFEAD3B0),
    Color(0xFFD6D6D6),
    Color(0xFFF2E8D8),
    Color(0xFFF0DFC8),
  ];

  Color backgroundColor = getCollageBackgroundColorByColorId(12);

  @override
  void initState() {
    super.initState();

    final slots = createAutoSlots(
      imageCount: widget.imagePaths.length,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
    );

    photos = [];

    for (int i = 0; i < widget.imagePaths.length; i++) {
      final slot = slots[i];

      photos.add(
        FreeCollagePhoto(
          imagePath: widget.imagePaths[i],
          x: slot.x,
          y: slot.y,
          width: slot.w,
          height: slot.h,
          angle: slot.angle,
        ),
      );
    }

    if (photos.isNotEmpty) {
      selectedIndex = 0;
    }
  }

  FreeCollagePhoto? get selectedPhoto {
    if (selectedIndex < 0 || selectedIndex >= photos.length) {
      return null;
    }
    return photos[selectedIndex];
  }

  void selectPhoto(FreeCollagePhoto photo) {
    setState(() {
      photos.remove(photo);
      photos.add(photo);
      selectedIndex = photos.length - 1;
    });
  }

  Future<void> addPhotos() async {
    final picker = ImagePicker();

    final files = await picker.pickMultiImage(
      imageQuality: 85,
    );

    if (files.isEmpty) return;

    setState(() {
      for (final file in files) {
        final offset = (photos.length % 6) * 35.0;

        photos.add(
          FreeCollagePhoto(
            imagePath: file.path,
            x: 220 + offset,
            y: 260 + offset,
            width: 360,
            height: 300,
            angle: ((photos.length % 5) - 2) * 0.035,
          ),
        );
      }

      selectedIndex = photos.length - 1;
    });
  }

  void deleteSelectedPhoto() {
    if (selectedIndex < 0 || selectedIndex >= photos.length) return;

    setState(() {
      photos.removeAt(selectedIndex);

      if (photos.isEmpty) {
        selectedIndex = -1;
      } else if (selectedIndex >= photos.length) {
        selectedIndex = photos.length - 1;
      }
    });
  }

  Future<void> saveFreeCollageWithoutSelection() async {
    if (isSavingFreeCollage) return;

    final int oldSelectedIndex = selectedIndex;

    setState(() {
      isSavingFreeCollage = true;
      selectedIndex = -1;
    });

    await Future.delayed(const Duration(milliseconds: 80));

    if (!mounted) return;

    await saveWidgetToGallery(
      context: context,
      repaintKey: captureKey,
      fileNamePrefix: 'free_collage',
    );

    if (!mounted) return;

    setState(() {
      selectedIndex = oldSelectedIndex;
      isSavingFreeCollage = false;
    });
  }

  void resizeSelected(double amount) {
    final photo = selectedPhoto;
    if (photo == null) return;

    setState(() {
      photo.width = (photo.width + amount).clamp(100.0, 1100.0).toDouble();
      photo.height = (photo.height + amount).clamp(100.0, 1100.0).toDouble();

      if (!photo.hasCrop) {
        photo.cropFrameWidth = photo.width;
        photo.cropFrameHeight = photo.height;
      }

      if (photo.cropShape == FreeCropShape.circle) {
        final size = min(photo.width, photo.height).toDouble();
        photo.width = size;
        photo.height = size;
        photo.cropFrameWidth = size;
        photo.cropFrameHeight = size;
      }
    });
  }

  void rotateSelected(double amount) {
    final photo = selectedPhoto;
    if (photo == null) return;

    setState(() {
      photo.angle += amount;
    });
  }

  void moveSelected({
    double dx = 0,
    double dy = 0,
  }) {
    final photo = selectedPhoto;
    if (photo == null) return;

    setState(() {
      photo.x += dx;
      photo.y += dy;
    });
  }

  Rect calculateCoverCropNormalized({
    required int imageWidth,
    required int imageHeight,
    required double cardWidth,
    required double cardHeight,
  }) {
    final imageAspect = imageWidth / imageHeight;
    final cardAspect = cardWidth / cardHeight;

    if (imageAspect > cardAspect) {
      final visibleWidth = cardAspect / imageAspect;
      final left = (1.0 - visibleWidth) / 2.0;
      return Rect.fromLTWH(left, 0, visibleWidth, 1);
    } else {
      final visibleHeight = imageAspect / cardAspect;
      final top = (1.0 - visibleHeight) / 2.0;
      return Rect.fromLTWH(0, top, 1, visibleHeight);
    }
  }

  Future<void> openCropOverlay() async {
    final photo = selectedPhoto;
    if (photo == null) return;

    setState(() {
      isLoadingCropImage = true;
      isCropOverlayOpen = true;
      editingCropShape = photo.cropShape;
      editingCropAngle = photo.cropAngle;
    });

    try {
      final bytes = await File(photo.imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        throw Exception('画像を読み込めませんでした');
      }

      final currentCrop = photo.hasCrop
          ? photo.cropRectNormalized
          : calculateCoverCropNormalized(
              imageWidth: decoded.width,
              imageHeight: decoded.height,
              cardWidth: photo.width,
              cardHeight: photo.height,
            );

      final shownCropWidth = photo.hasCrop
          ? photo.cropFrameWidth * displayScale
          : photo.width * displayScale;

      final shownCropHeight = photo.hasCrop
          ? photo.cropFrameHeight * displayScale
          : photo.height * displayScale;

      double fullImageDisplayWidth = shownCropWidth / currentCrop.width;
      double fullImageDisplayHeight = shownCropHeight / currentCrop.height;

      const minSide = 130.0;
      final minCurrentSide =
          min(fullImageDisplayWidth, fullImageDisplayHeight).toDouble();

      if (minCurrentSide < minSide) {
        final scale = minSide / minCurrentSide;
        fullImageDisplayWidth *= scale;
        fullImageDisplayHeight *= scale;
      }

      const maxSide = 520.0;
      final maxCurrentSide =
          max(fullImageDisplayWidth, fullImageDisplayHeight).toDouble();

      if (maxCurrentSide > maxSide) {
        final scale = maxSide / maxCurrentSide;
        fullImageDisplayWidth *= scale;
        fullImageDisplayHeight *= scale;
      }

      if (!mounted) return;

      setState(() {
        editingImagePixelWidth = decoded.width;
        editingImagePixelHeight = decoded.height;

        photo.imagePixelWidth = decoded.width;
        photo.imagePixelHeight = decoded.height;

        editingCropRectNormalized = currentCrop;

        cropEditorWidth = fullImageDisplayWidth;
        cropEditorHeight = fullImageDisplayHeight;

        isLoadingCropImage = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isCropOverlayOpen = false;
        isLoadingCropImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('画像の読み込みに失敗しました: $e'),
        ),
      );
    }
  }

  void closeCropOverlay() {
    setState(() {
      isCropOverlayOpen = false;
      isLoadingCropImage = false;
    });
  }

  Rect keepNormalizedRectInside(Rect rect) {
    double left = rect.left;
    double top = rect.top;
    double width = rect.width;
    double height = rect.height;

    width = width.clamp(0.05, 1.0).toDouble();
    height = height.clamp(0.05, 1.0).toDouble();

    if (left < 0) left = 0;
    if (top < 0) top = 0;

    if (left + width > 1) {
      left = 1 - width;
    }

    if (top + height > 1) {
      top = 1 - height;
    }

    return Rect.fromLTWH(left, top, width, height);
  }

  Rect normalizedToEditorRect({
    required Rect normalized,
    required Rect imageRect,
  }) {
    return Rect.fromLTWH(
      imageRect.left + normalized.left * imageRect.width,
      imageRect.top + normalized.top * imageRect.height,
      normalized.width * imageRect.width,
      normalized.height * imageRect.height,
    );
  }

  Rect editorRectToNormalized({
    required Rect editorRect,
    required Rect imageRect,
  }) {
    final left = ((editorRect.left - imageRect.left) / imageRect.width)
        .clamp(0.0, 1.0)
        .toDouble();

    final top = ((editorRect.top - imageRect.top) / imageRect.height)
        .clamp(0.0, 1.0)
        .toDouble();

    final width =
        (editorRect.width / imageRect.width).clamp(0.02, 1.0).toDouble();

    final height =
        (editorRect.height / imageRect.height).clamp(0.02, 1.0).toDouble();

    return keepNormalizedRectInside(
      Rect.fromLTWH(left, top, width, height),
    );
  }

  Rect getEditorImageRect() {
    return Rect.fromLTWH(0, 0, cropEditorWidth, cropEditorHeight);
  }

  Rect makeCircleNormalized(Rect normalized) {
    final imageRect = getEditorImageRect();

    final editorRect = normalizedToEditorRect(
      normalized: normalized,
      imageRect: imageRect,
    );

    final size = min(editorRect.width, editorRect.height).toDouble();

    final squareEditorRect = Rect.fromCenter(
      center: editorRect.center,
      width: size,
      height: size,
    );

    return editorRectToNormalized(
      editorRect: squareEditorRect,
      imageRect: imageRect,
    );
  }

  void changeEditingCropShape(FreeCropShape shape) {
    setState(() {
      editingCropShape = shape;

      if (shape == FreeCropShape.circle) {
        editingCropAngle = 0.0;

        editingCropRectNormalized = makeCircleNormalized(
          editingCropRectNormalized,
        );

        editingCropRectNormalized =
            keepNormalizedRectInside(editingCropRectNormalized);
      }
    });
  }

  void moveEditingCropRect({
    required Offset deltaOnScreen,
    required Rect imageRect,
  }) {
    final dx = deltaOnScreen.dx / imageRect.width;
    final dy = deltaOnScreen.dy / imageRect.height;

    setState(() {
      editingCropRectNormalized = editingCropRectNormalized.shift(
        Offset(dx, dy),
      );

      editingCropRectNormalized =
          keepNormalizedRectInside(editingCropRectNormalized);
    });
  }

  void resizeEditingCropRect(double amount) {
    setState(() {
      final imageRect = getEditorImageRect();

      final editorRect = normalizedToEditorRect(
        normalized: editingCropRectNormalized,
        imageRect: imageRect,
      );

      final center = editorRect.center;

      if (editingCropShape == FreeCropShape.circle) {
        final maxSize = min(imageRect.width, imageRect.height).toDouble();

        final size = (editorRect.width + amount)
            .clamp(40.0, maxSize)
            .toDouble();

        final newEditorRect = Rect.fromCenter(
          center: center,
          width: size,
          height: size,
        );

        editingCropRectNormalized = editorRectToNormalized(
          editorRect: newEditorRect,
          imageRect: imageRect,
        );
      } else {
        final width =
            (editorRect.width + amount).clamp(40.0, imageRect.width).toDouble();

        final height = (editorRect.height + amount)
            .clamp(40.0, imageRect.height)
            .toDouble();

        final newEditorRect = Rect.fromCenter(
          center: center,
          width: width,
          height: height,
        );

        editingCropRectNormalized = editorRectToNormalized(
          editorRect: newEditorRect,
          imageRect: imageRect,
        );
      }

      editingCropRectNormalized =
          keepNormalizedRectInside(editingCropRectNormalized);
    });
  }

  void stretchEditingCropRect({
    double dw = 0,
    double dh = 0,
  }) {
    if (editingCropShape == FreeCropShape.circle) return;

    setState(() {
      final imageRect = getEditorImageRect();

      final editorRect = normalizedToEditorRect(
        normalized: editingCropRectNormalized,
        imageRect: imageRect,
      );

      final center = editorRect.center;

      final width =
          (editorRect.width + dw).clamp(40.0, imageRect.width).toDouble();

      final height =
          (editorRect.height + dh).clamp(40.0, imageRect.height).toDouble();

      final newEditorRect = Rect.fromCenter(
        center: center,
        width: width,
        height: height,
      );

      editingCropRectNormalized = editorRectToNormalized(
        editorRect: newEditorRect,
        imageRect: imageRect,
      );

      editingCropRectNormalized =
          keepNormalizedRectInside(editingCropRectNormalized);
    });
  }

  void rotateEditingCropRect(double amount) {
    if (editingCropShape == FreeCropShape.circle) return;

    setState(() {
      editingCropAngle += amount;
    });
  }

  void resetEditingCropAngle() {
    setState(() {
      editingCropAngle = 0.0;
    });
  }

  void applyCropOverlay() {
    final photo = selectedPhoto;
    if (photo == null) return;

    final imageRect = getEditorImageRect();

    final editorCropRect = normalizedToEditorRect(
      normalized: editingCropRectNormalized,
      imageRect: imageRect,
    );

    double cropFrameWidth = editorCropRect.width / displayScale;
    double cropFrameHeight = editorCropRect.height / displayScale;

    if (editingCropShape == FreeCropShape.circle) {
      final size = min(cropFrameWidth, cropFrameHeight).toDouble();
      cropFrameWidth = size;
      cropFrameHeight = size;
    }

    final angle =
        editingCropShape == FreeCropShape.circle ? 0.0 : editingCropAngle;

    final cosA = cos(angle).abs();
    final sinA = sin(angle).abs();

    final rotatedBoundingWidth = cropFrameWidth * cosA + cropFrameHeight * sinA;
    final rotatedBoundingHeight =
        cropFrameWidth * sinA + cropFrameHeight * cosA;

    setState(() {
      photo.cropShape = editingCropShape;
      photo.cropRectNormalized = keepNormalizedRectInside(
        editingCropRectNormalized,
      );

      photo.hasCrop = true;
      photo.cropAngle = angle;

      photo.cropFrameWidth = cropFrameWidth.clamp(100.0, 950.0).toDouble();
      photo.cropFrameHeight = cropFrameHeight.clamp(100.0, 950.0).toDouble();

      photo.width = rotatedBoundingWidth.clamp(100.0, 1100.0).toDouble();
      photo.height = rotatedBoundingHeight.clamp(100.0, 1100.0).toDouble();

      photo.imagePixelWidth = editingImagePixelWidth;
      photo.imagePixelHeight = editingImagePixelHeight;

      isCropOverlayOpen = false;
      isLoadingCropImage = false;
    });
  }

  Color cropShapeColor(FreeCropShape shape) {
    switch (shape) {
      case FreeCropShape.rectangle:
        return Colors.blueAccent;
      case FreeCropShape.roundedRectangle:
        return Colors.deepPurpleAccent;
      case FreeCropShape.circle:
        return Colors.green;
    }
  }

  IconData cropShapeIcon(FreeCropShape shape) {
    switch (shape) {
      case FreeCropShape.rectangle:
        return Icons.crop_square;
      case FreeCropShape.roundedRectangle:
        return Icons.rounded_corner;
      case FreeCropShape.circle:
        return Icons.circle_outlined;
    }
  }

  Widget buildCropShapeButton({
    required FreeCropShape shape,
    required String label,
  }) {
    final isSelected = editingCropShape == shape;
    final color = cropShapeColor(shape);

    return OutlinedButton.icon(
      onPressed: () => changeEditingCropShape(shape),
      icon: Icon(cropShapeIcon(shape), size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? color.withOpacity(0.12) : Colors.white,
        foregroundColor: color,
        side: BorderSide(
          color: isSelected ? color : Colors.black26,
          width: isSelected ? 2.5 : 1,
        ),
      ),
    );
  }

  Widget buildCroppedImageContent(FreeCollagePhoto photo) {
    final crop = photo.cropRectNormalized;

    final fullImageDisplayWidth = photo.cropFrameWidth / crop.width;
    final fullImageDisplayHeight = photo.cropFrameHeight / crop.height;

    final cropLeft = (photo.width - photo.cropFrameWidth) / 2;
    final cropTop = (photo.height - photo.cropFrameHeight) / 2;

    return SizedBox(
      width: photo.width,
      height: photo.height,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: cropLeft - crop.left * fullImageDisplayWidth,
            top: cropTop - crop.top * fullImageDisplayHeight,
            width: fullImageDisplayWidth,
            height: fullImageDisplayHeight,
            child: Image.file(
              File(photo.imagePath),
              width: fullImageDisplayWidth,
              height: fullImageDisplayHeight,
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPhotoCard(FreeCollagePhoto photo, bool isSelected) {
    final shapeColor = cropShapeColor(photo.cropShape);
    final borderColor = isSelected ? shapeColor : Colors.transparent;

    if (photo.hasCrop) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          ClipPath(
            clipper: FreePhotoCropClipper(
              shape: photo.cropShape,
              angle: photo.cropAngle,
              cropFrameWidth: photo.cropFrameWidth,
              cropFrameHeight: photo.cropFrameHeight,
              padding: 7,
              radius: 24,
            ),
            child: Container(
              width: photo.width,
              height: photo.height,
              color: const Color(0xFFFFFCF7),
              padding: const EdgeInsets.all(7),
              child: ClipPath(
                clipper: FreePhotoCropClipper(
                  shape: photo.cropShape,
                  angle: photo.cropAngle,
                  cropFrameWidth: photo.cropFrameWidth,
                  cropFrameHeight: photo.cropFrameHeight,
                  padding: 0,
                  radius: 24,
                ),
                child: buildCroppedImageContent(photo),
              ),
            ),
          ),
          if (isSelected)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: FreePhotoCropBorderPainter(
                    shape: photo.cropShape,
                    angle: photo.cropAngle,
                    cropFrameWidth: photo.cropFrameWidth,
                    cropFrameHeight: photo.cropFrameHeight,
                    radius: 24,
                    color: borderColor,
                    strokeWidth: 5,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        border: Border.all(
          color: borderColor,
          width: isSelected ? 5 : 0,
        ),
      ),
      child: SizedBox(
        width: photo.width,
        height: photo.height,
        child: Image.file(
          File(photo.imagePath),
          width: photo.width,
          height: photo.height,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget buildPhoto(FreeCollagePhoto photo, int index) {
    final isSelected = index == selectedIndex;

    return Positioned(
      left: photo.x,
      top: photo.y,
      child: Transform.rotate(
        angle: photo.angle,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => selectPhoto(photo),
          onPanStart: (details) {
            lastPanGlobalPosition = details.globalPosition;
          },
          onPanUpdate: (details) {
            final previous = lastPanGlobalPosition;
            final current = details.globalPosition;

            if (previous == null) {
              lastPanGlobalPosition = current;
              return;
            }

            final delta = current - previous;
            lastPanGlobalPosition = current;

            setState(() {
              photo.x += delta.dx * touchScale;
              photo.y += delta.dy * touchScale;
            });
          },
          onPanEnd: (_) {
            lastPanGlobalPosition = null;
          },
          onPanCancel: () {
            lastPanGlobalPosition = null;
          },
          child: buildPhotoCard(photo, isSelected),
        ),
      ),
    );
  }

  Widget buildBackgroundPalette() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (final color in backgroundPalette)
          GestureDetector(
            onTap: () {
              setState(() {
                backgroundColor = color;
              });
            },
            child: Container(
              width: backgroundColor == color ? 42 : 34,
              height: backgroundColor == color ? 42 : 34,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      backgroundColor == color ? Colors.black : Colors.black26,
                  width: backgroundColor == color ? 3 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget buildEditButtons() {
    return Column(
      children: [
        const Text(
          '背景色',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        buildBackgroundPalette(),
        const SizedBox(height: 16),
        const Text(
          '写真調整',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton(
              onPressed:
                  selectedPhoto == null ? null : () => resizeSelected(-20),
              child: const Text('小さく'),
            ),
            OutlinedButton(
              onPressed:
                  selectedPhoto == null ? null : () => resizeSelected(20),
              child: const Text('大きく'),
            ),
            OutlinedButton(
              onPressed:
                  selectedPhoto == null ? null : () => rotateSelected(-0.08),
              child: const Text('左回転'),
            ),
            OutlinedButton(
              onPressed:
                  selectedPhoto == null ? null : () => rotateSelected(0.08),
              child: const Text('右回転'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton(
              onPressed:
                  selectedPhoto == null ? null : () => moveSelected(dy: -10),
              child: const Text('上へ'),
            ),
            OutlinedButton(
              onPressed:
                  selectedPhoto == null ? null : () => moveSelected(dy: 10),
              child: const Text('下へ'),
            ),
            OutlinedButton(
              onPressed:
                  selectedPhoto == null ? null : () => moveSelected(dx: -10),
              child: const Text('左へ'),
            ),
            OutlinedButton(
              onPressed:
                  selectedPhoto == null ? null : () => moveSelected(dx: 10),
              child: const Text('右へ'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: selectedPhoto == null ? null : openCropOverlay,
          icon: const Icon(Icons.crop),
          label: const Text('トリミング'),
        ),
        const SizedBox(height: 12),
        const Text(
          '写真管理',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: addPhotos,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('写真追加'),
            ),
            OutlinedButton.icon(
              onPressed: selectedPhoto == null ? null : deleteSelectedPhoto,
              icon: const Icon(Icons.delete_outline),
              label: const Text('削除'),
            ),
            ElevatedButton.icon(
              onPressed: saveFreeCollageWithoutSelection,
              icon: const Icon(Icons.save_alt),
              label: const Text('保存'),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildCropOverlay() {
    final photo = selectedPhoto;

    if (photo == null) {
      return const SizedBox.shrink();
    }

    final imageRect = getEditorImageRect();

    final cropRect = normalizedToEditorRect(
      normalized: editingCropRectNormalized,
      imageRect: imageRect,
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final overlayWidth = min(screenWidth - 24, 360).toDouble();

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.42),
        alignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: overlayWidth,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF7),
              borderRadius: BorderRadius.circular(24),
            ),
            child: isLoadingCropImage
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('画像を読み込み中...'),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'トリミング',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: closeCropOverlay,
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          width: cropEditorWidth,
                          height: cropEditorHeight,
                          color: Colors.black,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 0,
                                width: cropEditorWidth,
                                height: cropEditorHeight,
                                child: Image.file(
                                  File(photo.imagePath),
                                  width: cropEditorWidth,
                                  height: cropEditorHeight,
                                  fit: BoxFit.fill,
                                ),
                              ),
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: FreeCropOverlayPainter(
                                    imageRect: imageRect,
                                    cropRect: cropRect,
                                    shape: editingCropShape,
                                    cropAngle: editingCropAngle,
                                  ),
                                ),
                              ),
                              Positioned.fromRect(
                                rect: cropRect,
                                child: Transform.rotate(
                                  angle: editingCropAngle,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onPanUpdate: (details) {
                                      moveEditingCropRect(
                                        deltaOnScreen: details.delta,
                                        imageRect: imageRect,
                                      );
                                    },
                                    child: Container(
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          buildCropShapeButton(
                            shape: FreeCropShape.rectangle,
                            label: '四角',
                          ),
                          buildCropShapeButton(
                            shape: FreeCropShape.roundedRectangle,
                            label: '角丸',
                          ),
                          buildCropShapeButton(
                            shape: FreeCropShape.circle,
                            label: '丸',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () => resizeEditingCropRect(-18),
                            child: const Text('小さく'),
                          ),
                          OutlinedButton(
                            onPressed: () => resizeEditingCropRect(18),
                            child: const Text('大きく'),
                          ),
                        ],
                      ),
                      if (editingCropShape != FreeCropShape.circle) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            OutlinedButton(
                              onPressed: () =>
                                  stretchEditingCropRect(dw: -18),
                              child: const Text('横を短く'),
                            ),
                            OutlinedButton(
                              onPressed: () =>
                                  stretchEditingCropRect(dw: 18),
                              child: const Text('横を長く'),
                            ),
                            OutlinedButton(
                              onPressed: () =>
                                  stretchEditingCropRect(dh: -18),
                              child: const Text('縦を短く'),
                            ),
                            OutlinedButton(
                              onPressed: () =>
                                  stretchEditingCropRect(dh: 18),
                              child: const Text('縦を長く'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            OutlinedButton(
                              onPressed: () => rotateEditingCropRect(-0.08),
                              child: const Text('左回転'),
                            ),
                            OutlinedButton(
                              onPressed: () => rotateEditingCropRect(0.08),
                              child: const Text('右回転'),
                            ),
                            OutlinedButton(
                              onPressed: resetEditingCropAngle,
                              child: const Text('角度リセット'),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: closeCropOverlay,
                            child: const Text('キャンセル'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: applyCropOverlay,
                            child: const Text('完了'),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget buildSavingOverlay() {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: Colors.black.withOpacity(0.35),
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 14),
                Text(
                  '保存中...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('コラージュ2：自由配置'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: displayWidth,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: RepaintBoundary(
                      key: captureKey,
                      child: Container(
                        width: canvasWidth,
                        height: canvasHeight,
                        color: backgroundColor,
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            for (int i = 0; i < photos.length; i++)
                              buildPhoto(photos[i], i),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                buildEditButtons(),
              ],
            ),
          ),
          if (isCropOverlayOpen) buildCropOverlay(),
          if (isSavingFreeCollage) buildSavingOverlay(),
        ],
      ),
    );
  }
}

class FreeCropOverlayPainter extends CustomPainter {
  final Rect imageRect;
  final Rect cropRect;
  final FreeCropShape shape;
  final double cropAngle;

  FreeCropOverlayPainter({
    required this.imageRect,
    required this.cropRect,
    required this.shape,
    this.cropAngle = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outsidePaint = Paint()..color = Colors.black.withOpacity(0.58);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = shapeColor();

    final handlePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = shapeColor();

    final imagePath = Path()..addRect(imageRect);

    final rawCropPath = Path();

    switch (shape) {
      case FreeCropShape.rectangle:
        rawCropPath.addRect(cropRect);
        break;

      case FreeCropShape.roundedRectangle:
        rawCropPath.addRRect(
          RRect.fromRectAndRadius(
            cropRect,
            const Radius.circular(22),
          ),
        );
        break;

      case FreeCropShape.circle:
        rawCropPath.addOval(cropRect);
        break;
    }

    final Matrix4 rotationMatrix = Matrix4.identity()
      ..translate(cropRect.center.dx, cropRect.center.dy)
      ..rotateZ(cropAngle)
      ..translate(-cropRect.center.dx, -cropRect.center.dy);

    final cropPath = rawCropPath.transform(
      rotationMatrix.storage,
    );

    final overlayPath = Path.combine(
      PathOperation.difference,
      imagePath,
      cropPath,
    );

    canvas.drawPath(overlayPath, outsidePaint);
    canvas.drawPath(cropPath, borderPaint);

    Offset rotatePointAroundCenter(
      Offset point,
      Offset center,
      double angle,
    ) {
      final dx = point.dx - center.dx;
      final dy = point.dy - center.dy;

      final cosA = cos(angle);
      final sinA = sin(angle);

      return Offset(
        center.dx + dx * cosA - dy * sinA,
        center.dy + dx * sinA + dy * cosA,
      );
    }

    final center = cropRect.center;

    for (final handle in [
      cropRect.topLeft,
      cropRect.topRight,
      cropRect.bottomLeft,
      cropRect.bottomRight,
    ]) {
      final rotatedHandle = rotatePointAroundCenter(
        handle,
        center,
        cropAngle,
      );

      canvas.drawCircle(rotatedHandle, 5.5, handlePaint);
      canvas.drawCircle(
        rotatedHandle,
        8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white,
      );
    }
  }

  Color shapeColor() {
    switch (shape) {
      case FreeCropShape.rectangle:
        return Colors.blueAccent;
      case FreeCropShape.roundedRectangle:
        return Colors.deepPurpleAccent;
      case FreeCropShape.circle:
        return Colors.green;
    }
  }

  @override
  bool shouldRepaint(covariant FreeCropOverlayPainter oldDelegate) {
    return oldDelegate.imageRect != imageRect ||
        oldDelegate.cropRect != cropRect ||
        oldDelegate.shape != shape ||
        oldDelegate.cropAngle != cropAngle;
  }
}

class FreePhotoCropClipper extends CustomClipper<Path> {
  final FreeCropShape shape;
  final double angle;
  final double cropFrameWidth;
  final double cropFrameHeight;
  final double padding;
  final double radius;

  FreePhotoCropClipper({
    required this.shape,
    required this.angle,
    required this.cropFrameWidth,
    required this.cropFrameHeight,
    this.padding = 0,
    this.radius = 24,
  });

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final rect = Rect.fromCenter(
      center: center,
      width: cropFrameWidth + padding * 2,
      height: cropFrameHeight + padding * 2,
    );

    final rawPath = Path();

    switch (shape) {
      case FreeCropShape.rectangle:
        rawPath.addRect(rect);
        break;

      case FreeCropShape.roundedRectangle:
        rawPath.addRRect(
          RRect.fromRectAndRadius(
            rect,
            Radius.circular(radius),
          ),
        );
        break;

      case FreeCropShape.circle:
        rawPath.addOval(rect);
        break;
    }

    if (shape == FreeCropShape.circle || angle == 0.0) {
      return rawPath;
    }

    final matrix = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..rotateZ(angle)
      ..translate(-center.dx, -center.dy);

    return rawPath.transform(matrix.storage);
  }

  @override
  bool shouldReclip(covariant FreePhotoCropClipper oldClipper) {
    return oldClipper.shape != shape ||
        oldClipper.angle != angle ||
        oldClipper.cropFrameWidth != cropFrameWidth ||
        oldClipper.cropFrameHeight != cropFrameHeight ||
        oldClipper.padding != padding ||
        oldClipper.radius != radius;
  }
}

class FreePhotoCropBorderPainter extends CustomPainter {
  final FreeCropShape shape;
  final double angle;
  final double cropFrameWidth;
  final double cropFrameHeight;
  final double radius;
  final Color color;
  final double strokeWidth;

  FreePhotoCropBorderPainter({
    required this.shape,
    required this.angle,
    required this.cropFrameWidth,
    required this.cropFrameHeight,
    required this.radius,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final rect = Rect.fromCenter(
      center: center,
      width: cropFrameWidth + 14,
      height: cropFrameHeight + 14,
    ).deflate(strokeWidth / 2);

    final rawPath = Path();

    switch (shape) {
      case FreeCropShape.rectangle:
        rawPath.addRect(rect);
        break;

      case FreeCropShape.roundedRectangle:
        rawPath.addRRect(
          RRect.fromRectAndRadius(
            rect,
            Radius.circular(radius),
          ),
        );
        break;

      case FreeCropShape.circle:
        rawPath.addOval(rect);
        break;
    }

    Path path = rawPath;

    if (shape != FreeCropShape.circle && angle != 0.0) {
      final matrix = Matrix4.identity()
        ..translate(center.dx, center.dy)
        ..rotateZ(angle)
        ..translate(-center.dx, -center.dy);

      path = rawPath.transform(matrix.storage);
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant FreePhotoCropBorderPainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.angle != angle ||
        oldDelegate.cropFrameWidth != cropFrameWidth ||
        oldDelegate.cropFrameHeight != cropFrameHeight ||
        oldDelegate.radius != radius ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// ##########################################################################
// コラージュ3：テンプレート型グリッドコラージュ
// ##########################################################################

enum GridSlotShape {
  rectangle,
  rounded,
  circle,
}

class GridTemplate {
  final String name;
  final String description;
  final List<GridSlot> slots;
  final Color backgroundColor;

  const GridTemplate({
    required this.name,
    required this.description,
    required this.slots,
    this.backgroundColor = const Color(0xFFF4E7D3),
  });
}

class GridSlot {
  final Rect rect;
  final GridSlotShape shape;
  final double angle;
  final double radius;

  const GridSlot({
    required this.rect,
    this.shape = GridSlotShape.rectangle,
    this.angle = 0.0,
    this.radius = 28.0,
  });
}

class GridPhotoItem {
  String? imagePath;

  int imagePixelWidth;
  int imagePixelHeight;

  double imageScale;
  double offsetX;
  double offsetY;

  GridPhotoItem({
    this.imagePath,
    this.imagePixelWidth = 1,
    this.imagePixelHeight = 1,
    this.imageScale = 1.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
  });

  bool get hasImage => imagePath != null;
}

List<GridTemplate> collage3Templates = [
  GridTemplate(
    name: 'ベーシック4分割',
    description: '一番シンプル。写真をきれいに並べたい時向け。',
    slots: [
      GridSlot(rect: Rect.fromLTWH(70, 90, 360, 430)),
      GridSlot(rect: Rect.fromLTWH(470, 90, 360, 430)),
      GridSlot(rect: Rect.fromLTWH(70, 570, 360, 430)),
      GridSlot(rect: Rect.fromLTWH(470, 570, 360, 430)),
    ],
  ),
  GridTemplate(
    name: '主役1枚＋小写真4枚',
    description: '1枚を大きく見せて、周りに思い出を添える。',
    slots: [
      GridSlot(
        rect: Rect.fromLTWH(150, 120, 600, 470),
        shape: GridSlotShape.rounded,
        radius: 36,
      ),
      GridSlot(
        rect: Rect.fromLTWH(85, 665, 250, 250),
        shape: GridSlotShape.circle,
      ),
      GridSlot(
        rect: Rect.fromLTWH(365, 640, 220, 300),
        shape: GridSlotShape.rounded,
      ),
      GridSlot(
        rect: Rect.fromLTWH(615, 665, 250, 250),
        shape: GridSlotShape.circle,
      ),
      GridSlot(
        rect: Rect.fromLTWH(260, 925, 380, 120),
        shape: GridSlotShape.rounded,
      ),
    ],
  ),
  GridTemplate(
    name: '縦長ポスター',
    description: '縦写真が多い時に使いやすい。',
    slots: [
      GridSlot(
        rect: Rect.fromLTWH(70, 80, 250, 720),
        shape: GridSlotShape.rounded,
      ),
      GridSlot(rect: Rect.fromLTWH(350, 80, 250, 360)),
      GridSlot(
        rect: Rect.fromLTWH(630, 80, 200, 360),
        shape: GridSlotShape.rounded,
      ),
      GridSlot(rect: Rect.fromLTWH(350, 470, 480, 330)),
      GridSlot(
        rect: Rect.fromLTWH(120, 835, 660, 190),
        shape: GridSlotShape.rounded,
      ),
    ],
  ),
  GridTemplate(
    name: '横長バナー',
    description: '横長写真や景色をまとめたい時向け。',
    slots: [
      GridSlot(
        rect: Rect.fromLTWH(60, 90, 780, 260),
        shape: GridSlotShape.rounded,
      ),
      GridSlot(rect: Rect.fromLTWH(60, 390, 370, 260)),
      GridSlot(rect: Rect.fromLTWH(470, 390, 370, 260)),
      GridSlot(
        rect: Rect.fromLTWH(60, 690, 240, 300),
        shape: GridSlotShape.rounded,
      ),
      GridSlot(
        rect: Rect.fromLTWH(330, 690, 240, 300),
        shape: GridSlotShape.rounded,
      ),
      GridSlot(
        rect: Rect.fromLTWH(600, 690, 240, 300),
        shape: GridSlotShape.rounded,
      ),
    ],
  ),
  GridTemplate(
    name: '丸フォト',
    description: '丸い写真で柔らかい印象にする。',
    slots: [
      GridSlot(
        rect: Rect.fromLTWH(115, 95, 260, 260),
        shape: GridSlotShape.circle,
      ),
      GridSlot(
        rect: Rect.fromLTWH(525, 95, 260, 260),
        shape: GridSlotShape.circle,
      ),
      GridSlot(
        rect: Rect.fromLTWH(320, 360, 260, 260),
        shape: GridSlotShape.circle,
      ),
      GridSlot(
        rect: Rect.fromLTWH(115, 625, 260, 260),
        shape: GridSlotShape.circle,
      ),
      GridSlot(
        rect: Rect.fromLTWH(525, 625, 260, 260),
        shape: GridSlotShape.circle,
      ),
    ],
  ),
  GridTemplate(
    name: '角丸ムードボード',
    description: '余白多めで、Pinterestっぽく見せる。',
    backgroundColor: Color(0xFFF7EFE4),
    slots: [
      GridSlot(
        rect: Rect.fromLTWH(80, 90, 330, 260),
        shape: GridSlotShape.rounded,
      ),
      GridSlot(
        rect: Rect.fromLTWH(490, 90, 330, 360),
        shape: GridSlotShape.rounded,
      ),
      GridSlot(
        rect: Rect.fromLTWH(80, 400, 330, 420),
        shape: GridSlotShape.rounded,
      ),
      GridSlot(
        rect: Rect.fromLTWH(490, 500, 330, 250),
        shape: GridSlotShape.rounded,
      ),
      GridSlot(
        rect: Rect.fromLTWH(230, 850, 440, 170),
        shape: GridSlotShape.rounded,
      ),
    ],
  ),
  GridTemplate(
    name: 'ハート型',
    description: '記念日・好きな写真まとめ向け。',
    backgroundColor: Color(0xFFFFE4EC),
    slots: [
      GridSlot(
        rect: Rect.fromLTWH(250, 105, 190, 190),
        shape: GridSlotShape.circle,
      ),
      GridSlot(
        rect: Rect.fromLTWH(460, 105, 190, 190),
        shape: GridSlotShape.circle,
      ),
      GridSlot(
        rect: Rect.fromLTWH(155, 270, 190, 190),
        shape: GridSlotShape.circle,
      ),
      GridSlot(
        rect: Rect.fromLTWH(355, 285, 190, 190),
        shape: GridSlotShape.circle,
      ),
      GridSlot(
        rect: Rect.fromLTWH(555, 270, 190, 190),
        shape: GridSlotShape.circle,
      ),
      GridSlot(
        rect: Rect.fromLTWH(240, 470, 190, 190),
        shape: GridSlotShape.circle,
      ),
      GridSlot(
        rect: Rect.fromLTWH(470, 470, 190, 190),
        shape: GridSlotShape.circle,
      ),
      GridSlot(
        rect: Rect.fromLTWH(350, 660, 200, 200),
        shape: GridSlotShape.circle,
      ),
    ],
  ),
  GridTemplate(
    name: '雑誌風ミックス',
    description: '大きさ違いでメリハリを出す。',
    slots: [
      GridSlot(
        rect: Rect.fromLTWH(70, 80, 500, 360),
        shape: GridSlotShape.rounded,
        angle: -0.025,
      ),
      GridSlot(
        rect: Rect.fromLTWH(600, 110, 230, 300),
        angle: 0.035,
      ),
      GridSlot(
        rect: Rect.fromLTWH(90, 500, 250, 390),
        angle: 0.025,
      ),
      GridSlot(
        rect: Rect.fromLTWH(380, 480, 450, 250),
        shape: GridSlotShape.rounded,
      ),
      GridSlot(
        rect: Rect.fromLTWH(400, 765, 200, 200),
        shape: GridSlotShape.circle,
      ),
      GridSlot(
        rect: Rect.fromLTWH(630, 760, 200, 250),
        shape: GridSlotShape.rounded,
        angle: -0.035,
      ),
    ],
  ),
  GridTemplate(
    name: '3×3グリッド',
    description: '写真数が多い時の定番。',
    slots: [
      for (int row = 0; row < 3; row++)
        for (int col = 0; col < 3; col++)
          GridSlot(
            rect: Rect.fromLTWH(
              70 + col * 260,
              120 + row * 290,
              230,
              250,
            ),
            shape: GridSlotShape.rounded,
            radius: 24,
          ),
    ],
  ),
  GridTemplate(
    name: 'ダイヤ風アクセント',
    description: '少し個性的。タイル感を出したい時向け。',
    backgroundColor: Color(0xFFEAF2F7),
    slots: [
      GridSlot(rect: Rect.fromLTWH(340, 80, 220, 220), angle: 0.785),
      GridSlot(rect: Rect.fromLTWH(165, 270, 220, 220), angle: 0.785),
      GridSlot(rect: Rect.fromLTWH(515, 270, 220, 220), angle: 0.785),
      GridSlot(rect: Rect.fromLTWH(340, 460, 220, 220), angle: 0.785),
      GridSlot(rect: Rect.fromLTWH(165, 650, 220, 220), angle: 0.785),
      GridSlot(rect: Rect.fromLTWH(515, 650, 220, 220), angle: 0.785),
    ],
  ),
];

class GridCollagePage extends StatefulWidget {
  const GridCollagePage({
    super.key,
  });

  @override
  State<GridCollagePage> createState() => _GridCollagePageState();
}

class _GridCollagePageState extends State<GridCollagePage> {
  static const double canvasWidth = 900.0;
  static const double canvasHeight = 1100.0;
  static const double displayWidth = 320.0;

  final GlobalKey captureKey = GlobalKey();

  int selectedTemplateIndex = 0;
  int selectedSlotIndex = -1;

  late List<GridPhotoItem> photos;

  bool isCropOverlayOpen = false;
  bool isLoadingCropImage = false;

  bool isSavingGridCollage = false;

  int croppingSlotIndex = -1;

  double editingImageScale = 1.0;
  double editingOffsetX = 0.0;
  double editingOffsetY = 0.0;

  int editingImagePixelWidth = 1;
  int editingImagePixelHeight = 1;

  GridTemplate get template => collage3Templates[selectedTemplateIndex];

  @override
  void initState() {
    super.initState();
    photos = createPhotoItemsForTemplate(template);
  }

  List<GridPhotoItem> createPhotoItemsForTemplate(GridTemplate template) {
    return List.generate(
      template.slots.length,
      (_) => GridPhotoItem(),
    );
  }

  void changeTemplate(int index) {
    setState(() {
      selectedTemplateIndex = index;
      selectedSlotIndex = -1;
      photos = createPhotoItemsForTemplate(collage3Templates[index]);
      isCropOverlayOpen = false;
    });
  }

  Future<void> pickPhotoForSlot(int index) async {
    final picker = ImagePicker();

    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (file == null) return;

    final bytes = await File(file.path).readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) return;

    setState(() {
      selectedSlotIndex = index;
      photos[index] = GridPhotoItem(
        imagePath: file.path,
        imagePixelWidth: decoded.width,
        imagePixelHeight: decoded.height,
        imageScale: 1.0,
        offsetX: 0.0,
        offsetY: 0.0,
      );
    });

    openCropOverlay(index);
  }

  void selectSlot(int index) {
    setState(() {
      selectedSlotIndex = index;
    });
  }

  void deleteSelectedSlotPhoto() {
    if (selectedSlotIndex < 0 || selectedSlotIndex >= photos.length) return;

    setState(() {
      photos[selectedSlotIndex] = GridPhotoItem();
    });
  }

  Future<void> saveGridCollageWithoutSelection() async {
    if (isSavingGridCollage) return;

    final int oldSelectedSlotIndex = selectedSlotIndex;

    setState(() {
        isSavingGridCollage = true;
        selectedSlotIndex = -1;
    });

    // 選択枠が消えた状態で再描画されるのを待つ
    await Future.delayed(const Duration(milliseconds: 80));

    if (!mounted) return;

    await saveWidgetToGallery(
        context: context,
        repaintKey: captureKey,
        fileNamePrefix: 'grid_collage',
    );

    if (!mounted) return;

    setState(() {
        selectedSlotIndex = oldSelectedSlotIndex;
        isSavingGridCollage = false;
    });
  }

  Future<void> openCropOverlay(int index) async {
    if (index < 0 || index >= photos.length) return;

    final photo = photos[index];
    if (!photo.hasImage) return;

    setState(() {
      selectedSlotIndex = index;
      croppingSlotIndex = index;
      isCropOverlayOpen = true;
      isLoadingCropImage = true;

      editingImageScale = photo.imageScale;
      editingOffsetX = photo.offsetX;
      editingOffsetY = photo.offsetY;
    });

    try {
      final bytes = await File(photo.imagePath!).readAsBytes();
      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        throw Exception('画像を読み込めませんでした');
      }

      if (!mounted) return;

      setState(() {
        editingImagePixelWidth = decoded.width;
        editingImagePixelHeight = decoded.height;

        photos[index].imagePixelWidth = decoded.width;
        photos[index].imagePixelHeight = decoded.height;

        isLoadingCropImage = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isCropOverlayOpen = false;
        isLoadingCropImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('画像の読み込みに失敗しました: $e'),
        ),
      );
    }
  }

  double getEditFrameWidth(GridSlot slot) {
    final frameWidth = slot.rect.width * displayWidth / canvasWidth;
    final frameHeight = slot.rect.height * displayWidth / canvasWidth;

    double editFrameWidth = frameWidth;
    double editFrameHeight = frameHeight;

    const minSide = 180.0;
    final currentMinSide = min(editFrameWidth, editFrameHeight).toDouble();

    if (currentMinSide < minSide) {
      final scale = minSide / currentMinSide;
      editFrameWidth *= scale;
      editFrameHeight *= scale;
    }

    const maxSide = 310.0;
    final currentMaxSide = max(editFrameWidth, editFrameHeight).toDouble();

    if (currentMaxSide > maxSide) {
      final scale = maxSide / currentMaxSide;
      editFrameWidth *= scale;
      editFrameHeight *= scale;
    }

    return editFrameWidth;
  }

  double getEditFrameHeight(GridSlot slot) {
    final frameWidth = slot.rect.width * displayWidth / canvasWidth;
    final frameHeight = slot.rect.height * displayWidth / canvasWidth;

    double editFrameWidth = frameWidth;
    double editFrameHeight = frameHeight;

    const minSide = 180.0;
    final currentMinSide = min(editFrameWidth, editFrameHeight).toDouble();

    if (currentMinSide < minSide) {
      final scale = minSide / currentMinSide;
      editFrameWidth *= scale;
      editFrameHeight *= scale;
    }

    const maxSide = 310.0;
    final currentMaxSide = max(editFrameWidth, editFrameHeight).toDouble();

    if (currentMaxSide > maxSide) {
      final scale = maxSide / currentMaxSide;
      editFrameWidth *= scale;
      editFrameHeight *= scale;
    }

    return editFrameHeight;
  }

  Size calculateCoverImageSize({
    required double imageAspect,
    required double frameWidth,
    required double frameHeight,
    required double imageScale,
  }) {
    final frameAspect = frameWidth / frameHeight;

    double baseImageWidth;
    double baseImageHeight;

    if (imageAspect > frameAspect) {
      baseImageHeight = frameHeight;
      baseImageWidth = baseImageHeight * imageAspect;
    } else {
      baseImageWidth = frameWidth;
      baseImageHeight = baseImageWidth / imageAspect;
    }

    return Size(
      baseImageWidth * imageScale,
      baseImageHeight * imageScale,
    );
  }

  void clampEditingOffset({
    required double frameWidth,
    required double frameHeight,
  }) {
    final imageAspect = editingImagePixelWidth / editingImagePixelHeight;

    final imageSize = calculateCoverImageSize(
      imageAspect: imageAspect,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
      imageScale: editingImageScale,
    );

    final maxOffsetX = max((imageSize.width - frameWidth) / 2, 0.0).toDouble();
    final maxOffsetY =
        max((imageSize.height - frameHeight) / 2, 0.0).toDouble();

    editingOffsetX = editingOffsetX.clamp(-maxOffsetX, maxOffsetX).toDouble();
    editingOffsetY = editingOffsetY.clamp(-maxOffsetY, maxOffsetY).toDouble();
  }

  void moveEditingImage({
    required Offset deltaOnScreen,
    required double frameWidth,
    required double frameHeight,
  }) {
    setState(() {
      editingOffsetX += deltaOnScreen.dx;
      editingOffsetY += deltaOnScreen.dy;

      clampEditingOffset(
        frameWidth: frameWidth,
        frameHeight: frameHeight,
      );
    });
  }

  void zoomEditingImage(double delta) {
    if (croppingSlotIndex < 0 || croppingSlotIndex >= photos.length) return;

    final slot = template.slots[croppingSlotIndex];
    final frameWidth = getEditFrameWidth(slot);
    final frameHeight = getEditFrameHeight(slot);

    setState(() {
      final oldScale = editingImageScale;

      editingImageScale = (editingImageScale + delta)
          .clamp(1.0, 4.0)
          .toDouble();

      if (editingImageScale == oldScale) return;

      final scaleRatio = editingImageScale / oldScale;

      editingOffsetX *= scaleRatio;
      editingOffsetY *= scaleRatio;

      clampEditingOffset(
        frameWidth: frameWidth,
        frameHeight: frameHeight,
      );
    });
  }

  void applyCropOverlay() {
    if (croppingSlotIndex < 0 || croppingSlotIndex >= photos.length) return;

    setState(() {
      photos[croppingSlotIndex].imageScale = editingImageScale;
      photos[croppingSlotIndex].offsetX = editingOffsetX;
      photos[croppingSlotIndex].offsetY = editingOffsetY;

      isCropOverlayOpen = false;
      isLoadingCropImage = false;
      croppingSlotIndex = -1;
    });
  }

  void closeCropOverlay() {
    setState(() {
      isCropOverlayOpen = false;
      isLoadingCropImage = false;
      croppingSlotIndex = -1;
    });
  }

  Widget buildGridSlot(int index) {
    final slot = template.slots[index];
    final photo = photos[index];
    final isSelected = index == selectedSlotIndex;

    return Positioned(
        left: slot.rect.left,
        top: slot.rect.top,
        width: slot.rect.width,
        height: slot.rect.height,
        child: Transform.rotate(
        angle: slot.angle,
        child: GestureDetector(
            onTap: () {
            if (photo.hasImage) {
                selectSlot(index);
            } else {
                pickPhotoForSlot(index);
            }
            },
            child: Stack(
            clipBehavior: Clip.none,
            children: [
                // 写真本体
                ClipPath(
                clipper: GridSlotClipper(
                    shape: slot.shape,
                    radius: slot.radius,
                ),
                child: Container(
                    width: slot.rect.width,
                    height: slot.rect.height,
                    color: photo.hasImage
                        ? Colors.white
                        : Colors.white.withOpacity(0.55),
                    child: photo.hasImage
                        ? buildSlotImage(
                            photo: photo,
                            slot: slot,
                        )
                        : buildEmptySlot(index),
                ),
                ),

                // 通常時の白い枠
                Positioned.fill(
                child: IgnorePointer(
                    child: CustomPaint(
                    painter: GridSlotBorderPainter(
                        shape: slot.shape,
                        radius: slot.radius,
                        color: Colors.white,
                        strokeWidth: 6,
                    ),
                    ),
                ),
                ),

                // 選択中の青い枠
                if (isSelected)
                Positioned.fill(
                    child: IgnorePointer(
                    child: CustomPaint(
                        painter: GridSlotBorderPainter(
                        shape: slot.shape,
                        radius: slot.radius,
                        color: Colors.blueAccent,
                        strokeWidth: 8,
                        ),
                    ),
                    ),
                ),
            ],
            ),
        ),
        ),
    );
  }

  Widget buildSlotImage({
    required GridPhotoItem photo,
    required GridSlot slot,
  }) {
    final imageAspect = photo.imagePixelWidth / photo.imagePixelHeight;

    final imageSize = calculateCoverImageSize(
      imageAspect: imageAspect,
      frameWidth: slot.rect.width,
      frameHeight: slot.rect.height,
      imageScale: photo.imageScale,
    );

    final editFrameWidth = getEditFrameWidth(slot);
    final editFrameHeight = getEditFrameHeight(slot);

    final scaleX = slot.rect.width / editFrameWidth;
    final scaleY = slot.rect.height / editFrameHeight;

    final imageLeft =
        (slot.rect.width - imageSize.width) / 2 + photo.offsetX * scaleX;

    final imageTop =
        (slot.rect.height - imageSize.height) / 2 + photo.offsetY * scaleY;

    return SizedBox(
      width: slot.rect.width,
      height: slot.rect.height,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: imageLeft,
            top: imageTop,
            width: imageSize.width,
            height: imageSize.height,
            child: Image.file(
              File(photo.imagePath!),
              width: imageSize.width,
              height: imageSize.height,
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptySlot(int index) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.add_photo_alternate_outlined,
            size: 54,
            color: Colors.black38,
          ),
          const SizedBox(height: 8),
          Text(
            '${index + 1}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black26,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSlotActions() {
    final hasSelection =
        selectedSlotIndex >= 0 && selectedSlotIndex < photos.length;

    return Column(
        children: [
        if (isSavingGridCollage)
            const Text(
            '保存中...',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
            ),
            )
        else if (!hasSelection)
            const Text(
            'マスをタップして写真を選択',
            style: TextStyle(fontSize: 12),
            ),
        if (hasSelection) ...[
          Text(
            '選択中：${selectedSlotIndex + 1}番目のマス',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => pickPhotoForSlot(selectedSlotIndex),
                icon: const Icon(Icons.photo_library),
                label: Text(
                  photos[selectedSlotIndex].hasImage ? '写真変更' : '写真選択',
                ),
              ),
              OutlinedButton.icon(
                onPressed: photos[selectedSlotIndex].hasImage
                    ? () => openCropOverlay(selectedSlotIndex)
                    : null,
                icon: const Icon(Icons.crop),
                label: const Text('トリミング'),
              ),
              OutlinedButton.icon(
                onPressed: photos[selectedSlotIndex].hasImage
                    ? deleteSelectedSlotPhoto
                    : null,
                icon: const Icon(Icons.delete_outline),
                label: const Text('削除'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: saveGridCollageWithoutSelection,
          icon: const Icon(Icons.save_alt),
          label: const Text('保存'),
        ),
      ],
    );
  }

  Widget buildCropOverlay() {
    if (croppingSlotIndex < 0 || croppingSlotIndex >= photos.length) {
      return const SizedBox.shrink();
    }

    final photo = photos[croppingSlotIndex];
    if (!photo.hasImage) return const SizedBox.shrink();

    final slot = template.slots[croppingSlotIndex];

    final editFrameWidth = getEditFrameWidth(slot);
    final editFrameHeight = getEditFrameHeight(slot);

    final imageAspect = editingImagePixelWidth / editingImagePixelHeight;

    final imageSize = calculateCoverImageSize(
      imageAspect: imageAspect,
      frameWidth: editFrameWidth,
      frameHeight: editFrameHeight,
      imageScale: editingImageScale,
    );

    final imageLeft =
        (editFrameWidth - imageSize.width) / 2 + editingOffsetX;

    final imageTop =
        (editFrameHeight - imageSize.height) / 2 + editingOffsetY;

    final screenWidth = MediaQuery.of(context).size.width;
    final overlayWidth = min(screenWidth - 24, 360).toDouble();

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.42),
        alignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: overlayWidth,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF7),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: isLoadingCropImage
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('画像を読み込み中...'),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'トリミング',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: closeCropOverlay,
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: editFrameWidth,
                          height: editFrameHeight,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(4, 4),
                              ),
                            ],
                          ),
                          child: ClipPath(
                            clipper: GridSlotClipper(
                              shape: slot.shape,
                              radius:
                                  slot.radius * editFrameWidth / slot.rect.width,
                            ),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate: (details) {
                                moveEditingImage(
                                  deltaOnScreen: details.delta,
                                  frameWidth: editFrameWidth,
                                  frameHeight: editFrameHeight,
                                );
                              },
                              child: Stack(
                                clipBehavior: Clip.hardEdge,
                                children: [
                                  Positioned(
                                    left: imageLeft,
                                    top: imageTop,
                                    width: imageSize.width,
                                    height: imageSize.height,
                                    child: Image.file(
                                      File(photo.imagePath!),
                                      width: imageSize.width,
                                      height: imageSize.height,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () => zoomEditingImage(0.08),
                            child: const Text('画像を拡大'),
                          ),
                          OutlinedButton(
                            onPressed: () => zoomEditingImage(-0.08),
                            child: const Text('画像を縮小'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '画像をドラッグして位置を調整',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: closeCropOverlay,
                            child: const Text('キャンセル'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: applyCropOverlay,
                            child: const Text('完了'),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget buildSavingOverlay() {
    return Positioned.fill(
        child: AbsorbPointer(
        absorbing: true,
        child: Container(
            color: Colors.black.withOpacity(0.35),
            alignment: Alignment.center,
            child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
            ),
            decoration: BoxDecoration(
                color: const Color(0xFFFFFCF7),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                ),
                ],
            ),
            child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                CircularProgressIndicator(),
                SizedBox(height: 14),
                Text(
                    '保存中...',
                    style: TextStyle(
                    fontWeight: FontWeight.bold,
                    ),
                ),
                ],
            ),
            ),
        ),
        ),
    );
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('コラージュ3：テンプレート'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'グリッドを選ぶ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 94,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: collage3Templates.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final currentTemplate = collage3Templates[index];
                      final isSelected = index == selectedTemplateIndex;

                      return GestureDetector(
                        onTap: () => changeTemplate(index),
                        child: Container(
                          width: 140,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.black87 : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.black87
                                  : Colors.black26,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentTemplate.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${currentTemplate.slots.length}枚',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  template.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: displayWidth,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: RepaintBoundary(
                      key: captureKey,
                      child: Container(
                        width: canvasWidth,
                        height: canvasHeight,
                        color: template.backgroundColor,
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            for (int i = 0; i < template.slots.length; i++)
                              buildGridSlot(i),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                buildSlotActions(),
              ],
            ),
          ),
          if (isCropOverlayOpen) buildCropOverlay(),
          if (isSavingGridCollage) buildSavingOverlay(),
        ],
      ),
    );
  }
}

class GridSlotClipper extends CustomClipper<Path> {
  final GridSlotShape shape;
  final double radius;

  GridSlotClipper({
    required this.shape,
    required this.radius,
  });

  @override
  Path getClip(Size size) {
    final rect = Offset.zero & size;

    switch (shape) {
      case GridSlotShape.rectangle:
        return Path()..addRect(rect);
      case GridSlotShape.rounded:
        return Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              rect,
              Radius.circular(radius),
            ),
          );
      case GridSlotShape.circle:
        return Path()..addOval(rect);
    }
  }

  @override
  bool shouldReclip(covariant GridSlotClipper oldClipper) {
    return oldClipper.shape != shape || oldClipper.radius != radius;
  }
}

class GridSlotBorderPainter extends CustomPainter {
  final GridSlotShape shape;
  final double radius;
  final Color color;
  final double strokeWidth;

  GridSlotBorderPainter({
    required this.shape,
    required this.radius,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;

    switch (shape) {
      case GridSlotShape.rectangle:
        canvas.drawRect(rect.deflate(strokeWidth / 2), paint);
        break;

      case GridSlotShape.rounded:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.deflate(strokeWidth / 2),
            Radius.circular(radius),
          ),
          paint,
        );
        break;

      case GridSlotShape.circle:
        canvas.drawOval(
          rect.deflate(strokeWidth / 2),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant GridSlotBorderPainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.radius != radius ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
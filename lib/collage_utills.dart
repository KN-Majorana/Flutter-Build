import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// 複数画像をグリッド状に並べた1枚のコラージュ JPEG を作成する。
/// （`ScrapbookCollage` widget とは別の、画像ファイルとして書き出したい場合に使う）
Future<File> createCollageImage({
  required List<String> imagePaths,
  int cellSize = 300,
  int columns = 3,
}) async {
  final rows = (imagePaths.length / columns).ceil();

  final collage = img.Image(width: cellSize * columns, height: cellSize * rows);

  for (int i = 0; i < imagePaths.length; i++) {
    final file = File(imagePaths[i]);
    final bytes = await file.readAsBytes();

    final decoded = img.decodeImage(bytes);
    if (decoded == null) continue;

    final cropped = img.copyResizeCropSquare(decoded, size: cellSize);

    final x = (i % columns) * cellSize;
    final y = (i ~/ columns) * cellSize;

    img.compositeImage(collage, cropped, dstX: x, dstY: y);
  }

  final dir = await getApplicationDocumentsDirectory();
  final outputFile = File(
    '${dir.path}/collage_${DateTime.now().millisecondsSinceEpoch}.jpg',
  );

  await outputFile.writeAsBytes(
    Uint8List.fromList(img.encodeJpg(collage, quality: 90)),
  );

  return outputFile;
}

/// コラージュ表示の動作確認用に、8 色の単色画像を一時ディレクトリに作って
/// そのパス一覧を返すテストヘルパー。
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

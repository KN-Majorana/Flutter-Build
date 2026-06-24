import 'dart:math';
import 'dart:io';
import 'dart:typed_data';

import 'package:opencv_dart/opencv.dart' as cv;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class ColorRGB {
  final int r;
  final int g;
  final int b;

  const ColorRGB(this.r, this.g, this.b);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorRGB &&
          r == other.r &&
          g == other.g &&
          b == other.b;

  @override
  int get hashCode => Object.hash(r, g, b);
}

class ObjectResult {
  final List<ColorRGB> colors;

  const ObjectResult({
    required this.colors,
  });
}

// 最重要：代表色を抽出するための関数
ObjectResult extractMainColors(cv.Mat src) {
  final colorSrc = resizeShortSide(src, 128);
  final blurredForColor = cv.blur(colorSrc, (7, 7));

  final dominantColors = computeDominantColors(
    blurredForColor,
    binSize: 16,
    topK: 3,
  );

  final correctedColors = dominantColors
      .map((c) => correctColorSaturation(c, colorSrc, 16))
      .toList();

  final paletteColors = correctedColors
      .map((c) => findNearestPaletteColorLab(c))
      .toList();

  final uniquePaletteColors = paletteColors.toSet().toList();

  colorSrc.dispose();
  blurredForColor.dispose();

  return ObjectResult(colors: uniquePaletteColors);
}

cv.Mat resizeShortSide(cv.Mat src, int targetShortSide) {
  final w = src.cols;
  final h = src.rows;

  late int newW;
  late int newH;

  if (w <= h) {
    newW = targetShortSide;
    newH = (h * targetShortSide / w).round();
  } else {
    newH = targetShortSide;
    newW = (w * targetShortSide / h).round();
  }

  return cv.resize(src, (newW, newH), interpolation: cv.INTER_LINEAR);
}

List<ColorRGB> computeDominantColors(
  cv.Mat image, {
  int binSize = 16,
  double sigma = 0.15,
  int topK = 3,
}) {
  final Map<int, double> binScore = {};

  final width = image.cols;
  final height = image.rows;

  final cx = (width - 1) / 2.0;
  final cy = (height - 1) / 2.0;
  final sx = cx * sigma * 2;
  final sy = cy * sigma * 2;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final p = image.at<cv.Vec3b>(y, x);

      final b = p.val1.toInt();
      final g = p.val2.toInt();
      final r = p.val3.toInt();

      final dx = (x - cx) / sx;
      final dy = (y - cy) / sy;
      final weight = exp(-(dx * dx + dy * dy) / 2.0);

      final key =
          (r ~/ binSize) * 65536 +
          (g ~/ binSize) * 256 +
          (b ~/ binSize);

      binScore[key] = (binScore[key] ?? 0.0) + weight;
    }
  }

  if (binScore.isEmpty) {
    return [const ColorRGB(0, 0, 0)];
  }

  final sortedBins = binScore.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final result = <ColorRGB>[];

  for (int k = 0; k < min(topK, sortedBins.length); k++) {
    final topKey = sortedBins[k].key;

    final rBin = topKey ~/ 65536;
    final gBin = (topKey % 65536) ~/ 256;
    final bBin = topKey % 256;

    int sumR = 0;
    int sumG = 0;
    int sumB = 0;
    int count = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final p = image.at<cv.Vec3b>(y, x);

        final b = p.val1.toInt();
        final g = p.val2.toInt();
        final r = p.val3.toInt();

        if (r ~/ binSize == rBin &&
            g ~/ binSize == gBin &&
            b ~/ binSize == bBin) {
          sumR += r;
          sumG += g;
          sumB += b;
          count++;
        }
      }
    }

    if (count > 0) {
      result.add(ColorRGB(sumR ~/ count, sumG ~/ count, sumB ~/ count));
    }
  }

  return result;
}

ColorRGB correctColorSaturation(
  ColorRGB blurredColor,
  cv.Mat original,
  int binSize,
) {
  final br = blurredColor.r;
  final bg = blurredColor.g;
  final bb = blurredColor.b;

  final blurredHsv = rgbToHsv(br, bg, bb);
  final hue = blurredHsv[0];

  double sumS = 0;
  double sumV = 0;
  int count = 0;

  final rBin = br ~/ binSize;
  final gBin = bg ~/ binSize;
  final bBin = bb ~/ binSize;

  for (int y = 0; y < original.rows; y++) {
    for (int x = 0; x < original.cols; x++) {
      final p = original.at<cv.Vec3b>(y, x);

      final b = p.val1.toInt();
      final g = p.val2.toInt();
      final r = p.val3.toInt();

      if (r ~/ binSize == rBin &&
          g ~/ binSize == gBin &&
          b ~/ binSize == bBin) {
        final hsv = rgbToHsv(r, g, b);
        sumS += hsv[1];
        sumV += hsv[2];
        count++;
      }
    }
  }

  if (count == 0) return blurredColor;

  final corrected = hsvToRgb(hue, sumS / count, sumV / count);
  return ColorRGB(corrected[0], corrected[1], corrected[2]);
}

List<double> rgbToHsv(int r, int g, int b) {
  final rf = r / 255.0;
  final gf = g / 255.0;
  final bf = b / 255.0;
  final maxC = [rf, gf, bf].reduce(max);
  final minC = [rf, gf, bf].reduce(min);
  final delta = maxC - minC;

  double h = 0;
  if (delta != 0) {
    if (maxC == rf) {
      h = 60 * (((gf - bf) / delta) % 6);
    } else if (maxC == gf) {
      h = 60 * (((bf - rf) / delta) + 2);
    } else {
      h = 60 * (((rf - gf) / delta) + 4);
    }
  }
  if (h < 0) h += 360;

  final s = maxC == 0 ? 0.0 : delta / maxC;
  return [h, s, maxC];
}

List<int> hsvToRgb(double h, double s, double v) {
  final c = v * s;
  final x = c * (1 - ((h / 60) % 2 - 1).abs());
  final m = v - c;

  double rf, gf, bf;
  if (h < 60) {
    rf = c;
    gf = x;
    bf = 0;
  } else if (h < 120) {
    rf = x;
    gf = c;
    bf = 0;
  } else if (h < 180) {
    rf = 0;
    gf = c;
    bf = x;
  } else if (h < 240) {
    rf = 0;
    gf = x;
    bf = c;
  } else if (h < 300) {
    rf = x;
    gf = 0;
    bf = c;
  } else {
    rf = c;
    gf = 0;
    bf = x;
  }

  return [
    ((rf + m) * 255).round().clamp(0, 255),
    ((gf + m) * 255).round().clamp(0, 255),
    ((bf + m) * 255).round().clamp(0, 255),
  ];
}

final List<ColorRGB> colorPalette24 = [
  const ColorRGB(0, 0, 0),
  const ColorRGB(85, 85, 85),
  const ColorRGB(170, 170, 170),
  const ColorRGB(255, 255, 255),
  const ColorRGB(255, 0, 0),
  const ColorRGB(192, 0, 0),
  const ColorRGB(255, 192, 203),
  const ColorRGB(255, 128, 0),
  const ColorRGB(255, 192, 0),
  const ColorRGB(255, 255, 0),
  const ColorRGB(192, 255, 0),
  const ColorRGB(128, 255, 0),
  const ColorRGB(0, 200, 0),
  const ColorRGB(0, 100, 0),
  const ColorRGB(0, 255, 255),
  const ColorRGB(0, 192, 255),
  const ColorRGB(0, 0, 255),
  const ColorRGB(0, 0, 128),
  const ColorRGB(128, 0, 255),
  const ColorRGB(255, 0, 255),
  const ColorRGB(139, 69, 19),
  const ColorRGB(101, 67, 33),
  const ColorRGB(210, 180, 140),
  const ColorRGB(255, 220, 177),
];

final List<String> colorNames24 = [
  'Black',
  'DarkGray',
  'LightGray',
  'White',
  'Red',
  'DarkRed',
  'Pink',
  'Orange',
  'Amber',
  'Yellow',
  'YellowGreen',
  'Lime',
  'Green',
  'DarkGreen',
  'Cyan',
  'SkyBlue',
  'Blue',
  'Navy',
  'Purple',
  'Magenta',
  'Brown',
  'DarkBrown',
  'Tan',
  'LightOrange',
];

ColorRGB findNearestPaletteColorLab(ColorRGB color) {
  final inputLab = rgbToLabColor(color);

  ColorRGB nearest = colorPalette24.first;
  double minDist = double.infinity;

  for (final p in colorPalette24) {
    final paletteLab = rgbToLabColor(p);

    final dL = inputLab[0] - paletteLab[0];
    final da = inputLab[1] - paletteLab[1];
    final db = inputLab[2] - paletteLab[2];

    final dist = dL * dL + da * da + db * db;

    if (dist < minDist) {
      minDist = dist;
      nearest = p;
    }
  }

  return nearest;
}

List<double> rgbToLabColor(ColorRGB color) {
  final mat = cv.Mat.fromList(
    1,
    1,
    cv.MatType.CV_8UC3,
    [color.b, color.g, color.r],
  );

  final lab = cv.cvtColor(mat, cv.COLOR_BGR2Lab);
  final p = lab.at<cv.Vec3b>(0, 0);

  final l = p.val1.toDouble();
  final a = p.val2.toDouble();
  final b = p.val3.toDouble();

  mat.dispose();
  lab.dispose();

  return [l, a, b];
}

// ====================================================
// 永続化 (sqflite)
// ====================================================

class SavedImageInfo {
  final String id;
  final String imagePath;
  final List<int> colorIds;
  final double latitude;
  final double longitude;
  final String timestamp;

  const SavedImageInfo({
    required this.id,
    required this.imagePath,
    required this.colorIds,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'colorIds': colorIds,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
    };
  }
}

Database? _db;

Future<Database> getAppDatabase() async {
  if (_db != null) return _db!;

  final dir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, 'color_app.db');

  _db = await openDatabase(
    dbPath,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE images (
          id TEXT PRIMARY KEY,
          imagePath TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          timestamp TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE image_colors (
          imageId TEXT NOT NULL,
          colorId INTEGER NOT NULL,
          PRIMARY KEY (imageId, colorId),
          FOREIGN KEY (imageId) REFERENCES images(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_image_colors_colorId
        ON image_colors(colorId)
      ''');
    },
  );

  return _db!;
}

/// 写真バイト列を /images/{id}.jpg に保存し、代表色とともに DB に登録する。
Future<SavedImageInfo> saveImageInfoByColorIdsSql({
  required Uint8List imageBytes,
  required List<int> colorIds,
  required double latitude,
  required double longitude,
}) async {
  final dir = await getApplicationDocumentsDirectory();
  final imagesDir = Directory('${dir.path}/images');
  if (!await imagesDir.exists()) {
    await imagesDir.create(recursive: true);
  }

  final now = DateTime.now();
  final id = now.millisecondsSinceEpoch.toString();
  final timestamp = now.toIso8601String();

  final imageFile = File('${imagesDir.path}/$id.jpg');
  await imageFile.writeAsBytes(imageBytes);

  final info = SavedImageInfo(
    id: id,
    imagePath: imageFile.path,
    colorIds: colorIds,
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp,
  );

  final db = await getAppDatabase();

  await db.transaction((txn) async {
    await txn.insert(
      'images',
      {
        'id': info.id,
        'imagePath': info.imagePath,
        'latitude': info.latitude,
        'longitude': info.longitude,
        'timestamp': info.timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    for (final colorId in colorIds) {
      await txn.insert(
        'image_colors',
        {
          'imageId': info.id,
          'colorId': colorId,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  });

  return info;
}

/// 撮影バイト列から代表色抽出 → DB保存までを一気に行うヘルパー。
/// PhotoService から呼ばれる想定。
Future<SavedImageInfo> extractAndSavePhoto({
  required Uint8List imageBytes,
  required double latitude,
  required double longitude,
}) async {
  final src = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
  final result = extractMainColors(src);
  src.dispose();

  final colorIds = result.colors
      .map((c) => colorPalette24.indexOf(c))
      .where((idx) => idx >= 0)
      .toList();

  return await saveImageInfoByColorIdsSql(
    imageBytes: imageBytes,
    colorIds: colorIds,
    latitude: latitude,
    longitude: longitude,
  );
}

/// 保存済みの全画像を新しい順で取得する。
Future<List<SavedImageInfo>> loadAllSavedImagesSql() async {
  final db = await getAppDatabase();

  final rows = await db.query('images', orderBy: 'timestamp DESC');

  final results = <SavedImageInfo>[];

  for (final row in rows) {
    final imageId = row['id'] as String;

    final colorRows = await db.query(
      'image_colors',
      where: 'imageId = ?',
      whereArgs: [imageId],
    );

    final ids = colorRows.map((r) => r['colorId'] as int).toList();

    results.add(
      SavedImageInfo(
        id: imageId,
        imagePath: row['imagePath'] as String,
        colorIds: ids,
        latitude: row['latitude'] as double,
        longitude: row['longitude'] as double,
        timestamp: row['timestamp'] as String,
      ),
    );
  }

  return results;
}

Future<List<SavedImageInfo>> getImagesByColorIdSql(int colorId) async {
  final db = await getAppDatabase();

  final rows = await db.rawQuery(
    '''
    SELECT images.*
    FROM images
    JOIN image_colors
      ON images.id = image_colors.imageId
    WHERE image_colors.colorId = ?
    ORDER BY images.timestamp DESC
    ''',
    [colorId],
  );

  final results = <SavedImageInfo>[];

  for (final row in rows) {
    final imageId = row['id'] as String;

    final colorRows = await db.query(
      'image_colors',
      where: 'imageId = ?',
      whereArgs: [imageId],
    );

    final ids = colorRows.map((r) => r['colorId'] as int).toList();

    results.add(
      SavedImageInfo(
        id: imageId,
        imagePath: row['imagePath'] as String,
        colorIds: ids,
        latitude: row['latitude'] as double,
        longitude: row['longitude'] as double,
        timestamp: row['timestamp'] as String,
      ),
    );
  }

  return results;
}

import 'dart:io';
import 'package:opencv_dart/opencv.dart' as cv;

import 'color_extractor.dart';
import 'color_palette.dart';
import 'image_info_storage.dart';

/// 撮影済み写真ファイルから代表色を抽出し、色IDごとのJSONに登録する。
///
/// `PhotoService.takeAndSavePhoto()` で得た保存パスをそのまま渡せばよい。
/// 抽出した色がパレット 24 色に1つも含まれなかった場合は colorIds は空配列で登録される。
Future<SavedImageInfo> processAndRegisterPhoto({
  required String imagePath,
  required double latitude,
  required double longitude,
}) async {
  final bytes = await File(imagePath).readAsBytes();
  final src = cv.imdecode(bytes, cv.IMREAD_COLOR);

  try {
    final result = extractMainColors(src);

    final colorIds = result.colors
        .map((c) => colorPalette24.indexOf(c))
        .where((idx) => idx >= 0)
        .toList();

    return await saveImageInfoByColorIds(
      imageBytes: bytes,
      colorIds: colorIds,
      latitude: latitude,
      longitude: longitude,
    );
  } finally {
    src.dispose();
  }
}

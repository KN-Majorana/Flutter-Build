import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'color_module.dart';
import 'photo_pin.dart';

/// 写真撮影と永続化を担うサービス。
/// 撮影後、代表色を抽出して sqflite に保存し、完成形の PhotoPin を返す。
class PhotoService {
  static final ImagePicker _picker = ImagePicker();

  /// カメラを起動して写真を撮影し、代表色とともに DB に登録する。
  /// 成功時は PhotoPin を返す。キャンセル時や失敗時は null を返す。
  static Future<PhotoPin?> takeAndSavePhoto({
    required LatLng position,
  }) async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo == null) return null;

    final bytes = await File(photo.path).readAsBytes();

    final info = await extractAndSavePhoto(
      imageBytes: bytes,
      latitude: position.latitude,
      longitude: position.longitude,
    );

    return PhotoPin(
      id: info.id,
      imagePath: info.imagePath,
      position: LatLng(info.latitude, info.longitude),
      takenAt: DateTime.parse(info.timestamp),
      colorIds: info.colorIds,
    );
  }

  /// 起動時などに、保存済みの全写真を PhotoPin の形で取得する。
  static Future<List<PhotoPin>> loadAllPhotoPins() async {
    final infos = await loadAllSavedImagesSql();
    return infos
        .map(
          (info) => PhotoPin(
            id: info.id,
            imagePath: info.imagePath,
            position: LatLng(info.latitude, info.longitude),
            takenAt: DateTime.parse(info.timestamp),
            colorIds: info.colorIds,
          ),
        )
        .toList();
  }
}

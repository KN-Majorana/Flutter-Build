import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  /// 現在地を1回だけ取得する
  static Future<LatLng> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('位置情報サービスが無効です');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('位置情報の権限が拒否されました');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('位置情報の権限が永久に拒否されています');
    }

    final position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  /// 現在地を継続的に取得するStream(記録モード用)
  /// [distanceFilter] メートル単位。指定距離移動するごとに値が流れる
  static Stream<LatLng> watchPosition({int distanceFilter = 5}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    ).map((p) => LatLng(p.latitude, p.longitude));
  }
}

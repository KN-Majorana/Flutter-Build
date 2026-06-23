import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'current_location_marker.dart';
import 'fog_clearing_service.dart';
import 'fog_overlay.dart';
import 'ghost_track.dart';
import 'location_service.dart';
import 'map_mode.dart';
import 'mode_switcher.dart';
import 'recording_controls.dart';
import 'track_storage_service.dart';
import 'walk_track.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(35.1815, 136.9066);
  bool _hasLocation = false;

  // モード状態
  MapMode _mode = MapMode.normal;

  // 霧モードの晴れ範囲(メートル)
  static const double _fogClearRadius = 30;

  // 再生モードの速度倍率
  static const double _ghostSpeed = 4.0;

  // 記録状態
  WalkTrack? _currentTrack;
  StreamSubscription<LatLng>? _positionSub;
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  // 過去の散歩記録(起動時に永続ストレージから読み込む)
  final List<WalkTrack> _savedTracks = [];

  // 再生モード関連
  GhostTrack? _ghost;
  Timer? _ghostTimer;
  DateTime? _ghostStartedAt;
  LatLng? _ghostPosition;

  bool get _isRecording => _currentTrack != null && _currentTrack!.isActive;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
    _loadSavedTracks();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _elapsedTimer?.cancel();
    _ghostTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
        _hasLocation = true;
      });
      _mapController.move(_currentPosition, 15.0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('位置情報取得失敗: $e')));
    }
  }

  Future<void> _loadSavedTracks() async {
    try {
      final tracks = await TrackStorageService.loadAll();
      if (!mounted) return;
      setState(() {
        _savedTracks
          ..clear()
          ..addAll(tracks);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('過去の記録の読み込みに失敗: $e')));
    }
  }

  // ─── 記録開始 ───
  void _startRecording() {
    final now = DateTime.now();
    setState(() {
      _currentTrack = WalkTrack(
        id: now.millisecondsSinceEpoch.toString(),
        startedAt: now,
        points: _hasLocation
            ? [TrackPoint(position: _currentPosition, timestamp: now)]
            : [],
      );
      _elapsed = Duration.zero;
    });

    // 位置情報の継続取得
    _positionSub = LocationService.watchPosition().listen((pos) {
      if (!mounted || !_isRecording) return;
      setState(() {
        _currentPosition = pos;
        _hasLocation = true;
        _currentTrack = _currentTrack!.copyWith(
          points: [
            ..._currentTrack!.points,
            TrackPoint(position: pos, timestamp: DateTime.now()),
          ],
        );
      });
    });

    // 経過時間タイマー(1秒ごと)
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isRecording) return;
      setState(() {
        _elapsed = DateTime.now().difference(_currentTrack!.startedAt);
      });
    });
  }

  // ─── 記録停止 ───
  Future<void> _stopRecording() async {
    _positionSub?.cancel();
    _positionSub = null;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;

    final count = _currentTrack?.points.length ?? 0;
    final finished = _currentTrack?.copyWith(endedAt: DateTime.now());
    setState(() {
      _currentTrack = finished;
      if (finished != null && finished.points.isNotEmpty) {
        _savedTracks.add(finished);
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('記録を停止しました($count点)')));
    }

    // 永続化
    if (finished != null && finished.points.isNotEmpty) {
      try {
        await TrackStorageService.save(finished);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('記録の保存に失敗: $e')));
      }
    }
  }

  /// 霧を晴らすために使う、全軌跡の座標リストを作る。
  List<LatLng> _clearedPointsForFog() {
    final tracks = <WalkTrack>[
      ..._savedTracks,
      if (_currentTrack != null && _currentTrack!.points.isNotEmpty)
        _currentTrack!,
    ];
    return FogClearingService.clearedPointsFromTracks(tracks);
  }

  // ─── モード切替時のフック ───
  void _onModeChanged(MapMode mode) {
    setState(() => _mode = mode);
    if (mode == MapMode.animation) {
      _startGhostPlayback();
    } else {
      _stopGhostPlayback();
    }
  }

  // ─── 再生開始 ───
  void _startGhostPlayback() {
    _stopGhostPlayback();

    // 再生対象は最新の保存済み軌跡。2点未満なら再生できない。
    final target = _savedTracks.isNotEmpty ? _savedTracks.last : null;
    if (target == null || target.points.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('再生できる記録がありません')));
      }
      return;
    }

    final ghost = GhostTrack(target, speed: _ghostSpeed);
    setState(() {
      _ghost = ghost;
      _ghostStartedAt = DateTime.now();
      _ghostPosition = target.points.first.position;
    });

    // 軌跡の先頭にカメラを寄せる
    _mapController.move(target.points.first.position, 16.0);

    _ghostTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _ghost == null || _ghostStartedAt == null) return;
      var elapsed = DateTime.now().difference(_ghostStartedAt!);

      // 終端まで行ったらループ再生する
      if (_ghost!.isFinished(elapsed)) {
        _ghostStartedAt = DateTime.now();
        elapsed = Duration.zero;
      }

      final pos = _ghost!.positionAt(elapsed);
      if (pos != null) {
        setState(() => _ghostPosition = pos);
      }
    });
  }

  // ─── 再生停止 ───
  void _stopGhostPlayback() {
    _ghostTimer?.cancel();
    _ghostTimer = null;
    setState(() {
      _ghost = null;
      _ghostStartedAt = null;
      _ghostPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final trackPoints =
        _currentTrack?.points.map((p) => p.position).toList() ?? [];
    final clearedPoints = _mode == MapMode.fog ? _clearedPointsForFog() : null;

    // 再生モード時にゴーストが辿っている軌跡の全座標
    final ghostFullPath = _mode == MapMode.animation && _ghost != null
        ? _ghost!.track.points.map((p) => p.position).toList()
        : const <LatLng>[];

    return Scaffold(
      body: Stack(
        children: [
          // ── 地図本体 ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 13.0,
              minZoom: 3.0,
              maxZoom: 19.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
                maxZoom: 19,
              ),
              // 通常モード: 記録中の軌跡を青線で表示
              if (_mode == MapMode.normal && trackPoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: trackPoints,
                      strokeWidth: 5,
                      color: Colors.blue,
                    ),
                  ],
                ),
              // 再生モード: 再生対象の軌跡全体を緑で薄く表示
              if (_mode == MapMode.animation && ghostFullPath.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: ghostFullPath,
                      strokeWidth: 4,
                      color: Colors.green.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              // 霧オーバーレイ
              if (clearedPoints != null)
                FogOverlay(
                  clearedPoints: clearedPoints,
                  clearRadius: _fogClearRadius,
                ),
              // 現在地マーカー(再生モード以外)
              if (_hasLocation && _mode != MapMode.animation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition,
                      width: 30,
                      height: 30,
                      child: const CurrentLocationMarker(),
                    ),
                  ],
                ),
              // ゴーストマーカー(再生モード時)
              if (_mode == MapMode.animation && _ghostPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _ghostPosition!,
                      width: 28,
                      height: 28,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── 上部:モード切替 ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ModeSwitcher(
                    currentMode: _mode,
                    onModeChanged: _onModeChanged,
                  ),
                ),
              ),
            ),
          ),

          // ── 下部:記録コントロール(通常モード時のみ) ──
          if (_mode == MapMode.normal)
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: RecordingControls(
                    isRecording: _isRecording,
                    pointCount: _currentTrack?.points.length ?? 0,
                    elapsed: _elapsed,
                    onStart: _startRecording,
                    onStop: _stopRecording,
                  ),
                ),
              ),
            ),
        ],
      ),

      // 現在地に戻るボタン
      floatingActionButton: FloatingActionButton.small(
        onPressed: _hasLocation
            ? () => _mapController.move(_currentPosition, 16.0)
            : null,
        heroTag: 'recenter',
        child: const Icon(Icons.my_location),
      ),
    );
  }
}

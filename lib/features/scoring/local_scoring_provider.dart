import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/services/local_scoring_service.dart';
import '../../data/models/local_scoring_models.dart';
import 'scoring_provider.dart';

class LocalScoringProvider extends ChangeNotifier {
  final LocalScoringService _service = LocalScoringService();
  LocalSyncRole _role = LocalSyncRole.none;
  ScoringProvider? _attachedScoringProv;

  LocalScoringProvider() {
    _service.onHostViewersChanged = (_) {
      notifyListeners();
    };

    _service.onViewerStatusChanged = (status, error) {
      notifyListeners();
    };

    _service.onSnapshotReceived = (_) {
      notifyListeners();
    };

    _service.onDiscoveredMatchesChanged = (_) {
      notifyListeners();
    };
  }

  // Getters
  LocalSyncRole get role => _role;
  bool get isHosting => _service.isHosting;
  String? get pinCode => _service.pinCode;
  String? get hostIp => _service.hostIp;
  int get actualPort => _service.actualPort;
  List<ViewerDevice> get viewers => _service.viewers;
  ViewerConnectionStatus get viewerStatus => _service.viewerStatus;
  String? get viewerError => _service.viewerError;
  LiveMatchSnapshot? get liveSnapshot => _service.latestSnapshot;
  List<DiscoveredMatchBeacon> get discoveredMatches => _service.discoveredMatches;

  Future<String?> startHosting(ScoringProvider scoringProv, {String? customPin}) async {
    final snap = scoringProv.createLiveSnapshot();
    if (snap == null) return null;

    _attachedScoringProv = scoringProv;
    scoringProv.onSnapshotUpdated = (updatedSnap) {
      if (isHosting) {
        _service.broadcastSnapshot(updatedSnap);
      }
    };

    final pin = await _service.startHosting(snap, customPin: customPin);
    if (pin != null) {
      _role = LocalSyncRole.host;
    }
    notifyListeners();
    return pin;
  }

  Future<void> stopHosting() async {
    if (_attachedScoringProv != null) {
      _attachedScoringProv!.onSnapshotUpdated = null;
      _attachedScoringProv = null;
    }
    await _service.stopHosting();
    _role = LocalSyncRole.none;
    notifyListeners();
  }

  void disconnectViewer(String viewerId) {
    _service.disconnectViewer(viewerId);
    notifyListeners();
  }

  Future<void> startDiscovery() async {
    await _service.startBeaconDiscovery();
    notifyListeners();
  }

  void stopDiscovery() {
    _service.stopBeaconDiscovery();
    notifyListeners();
  }

  Future<bool> joinAsViewer(
    String pin, {
    String? directHostIp,
    int? directPort,
    String? deviceName,
  }) async {
    _role = LocalSyncRole.viewer;
    notifyListeners();

    final ok = await _service.connectAsViewer(
      pin,
      directHostIp: directHostIp,
      directPort: directPort,
      deviceName: deviceName,
    );
    notifyListeners();
    return ok;
  }

  void leaveViewerSession() {
    _service.disconnectViewerSession();
    _role = LocalSyncRole.none;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_attachedScoringProv != null) {
      _attachedScoringProv!.onSnapshotUpdated = null;
    }
    _service.dispose();
    super.dispose();
  }
}

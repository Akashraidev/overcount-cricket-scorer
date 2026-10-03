import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../data/models/local_scoring_models.dart';

class LocalScoringService {
  static const int defaultHttpPort = 40404;
  static const int defaultBeaconPort = 40405;

  // --- Host State ---
  HttpServer? _server;
  RawDatagramSocket? _beaconSocket;
  Timer? _beaconTimer;
  String? _pinCode;
  String? _hostIp;
  int _actualPort = defaultHttpPort;
  final Map<String, ({WebSocket socket, ViewerDevice device})> _viewers = {};
  LiveMatchSnapshot? _latestSnapshot;

  // --- Viewer State ---
  WebSocket? _viewerSocket;
  Timer? _reconnectTimer;
  String? _targetPin;
  String? _targetHostIp;
  int _targetPort = defaultHttpPort;
  String? _deviceId;
  String? _deviceName;
  bool _isManualDisconnect = false;
  ViewerConnectionStatus _viewerStatus = ViewerConnectionStatus.disconnected;
  String? _viewerError;

  // --- UDP Discovery State ---
  RawDatagramSocket? _discoverySocket;
  final Map<String, DiscoveredMatchBeacon> _discoveredMatches = {};
  Timer? _beaconPruneTimer;

  // Callbacks / Streams
  void Function(List<ViewerDevice>)? onHostViewersChanged;
  void Function(ViewerConnectionStatus status, String? error)? onViewerStatusChanged;
  void Function(LiveMatchSnapshot snapshot)? onSnapshotReceived;
  void Function(List<DiscoveredMatchBeacon> matches)? onDiscoveredMatchesChanged;

  // Getters
  bool get isHosting => _server != null;
  String? get pinCode => _pinCode;
  String? get hostIp => _hostIp;
  int get actualPort => _actualPort;
  List<ViewerDevice> get viewers => _viewers.values.map((v) => v.device).toList();
  ViewerConnectionStatus get viewerStatus => _viewerStatus;
  String? get viewerError => _viewerError;
  LiveMatchSnapshot? get latestSnapshot => _latestSnapshot;
  List<DiscoveredMatchBeacon> get discoveredMatches => _discoveredMatches.values.toList();

  String? get qrPayload {
    if (!isHosting || _hostIp == null || _pinCode == null) return null;
    return 'scorecard://live?host=$_hostIp&port=$_actualPort&pin=$_pinCode';
  }

  static ({String host, int port, String pin})? parseQrPayload(String raw) {
    try {
      final uri = Uri.parse(raw.trim());
      if (uri.scheme == 'scorecard' && uri.host == 'live') {
        final host = uri.queryParameters['host'];
        final port = int.tryParse(uri.queryParameters['port'] ?? '') ?? defaultHttpPort;
        final pin = uri.queryParameters['pin'];
        if (host != null && host.isNotEmpty && pin != null && pin.isNotEmpty) {
          return (host: host, port: port, pin: pin);
        }
      }
    } catch (_) {}
    return null;
  }

  // -------------------------------------------------------------
  // IP UTILITIES
  // -------------------------------------------------------------
  static Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      final candidates = <({String ip, int score})>[];

      for (final iface in interfaces) {
        final name = iface.name.toLowerCase();
        for (final addr in iface.addresses) {
          if (addr.isLoopback) continue;
          final ip = addr.address;

          int score = 50;

          // Priority 1: Direct Mobile Hotspot Gateway IP (Android 192.168.43.1 or iOS 172.20.10.1)
          if (ip == '192.168.43.1' || ip == '172.20.10.1') {
            score = 100;
          }
          // Priority 2: Hotspot/Tethering interface names (ap, swlan, rndis, tether, softap, hotspot)
          else if (name.contains('ap') ||
              name.contains('swlan') ||
              name.contains('tether') ||
              name.contains('rndis') ||
              name.contains('softap') ||
              name.contains('hotspot') ||
              name.contains('p2p')) {
            score = 90;
          }
          // Priority 3: Standard hotspot subnets (192.168.43.x or 172.20.10.x)
          else if (ip.startsWith('192.168.43.') || ip.startsWith('172.20.10.')) {
            score = 85;
          }
          // Priority 4: Standard Wi-Fi / LAN client interfaces (wlan, eth, en, wifi)
          else if (name.contains('wlan') ||
              name.contains('eth') ||
              name.contains('en') ||
              name.contains('wifi') ||
              name.contains('wi-fi')) {
            score = 75;
          }
          // Priority 5: Common private LAN subnets (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
          else if (ip.startsWith('192.168.') || ip.startsWith('10.') || ip.startsWith('172.')) {
            score = 60;
          }

          // Deprioritize Cellular / Mobile carrier interfaces (rmnet, ccmni, pdp, wwan)
          if (name.contains('rmnet') ||
              name.contains('ccmni') ||
              name.contains('pdp') ||
              name.contains('wwan') ||
              name.contains('mobile') ||
              name.contains('cellular')) {
            score = 10;
          }

          candidates.add((ip: ip, score: score));
        }
      }

      if (candidates.isNotEmpty) {
        candidates.sort((a, b) => b.score.compareTo(a.score));
        return candidates.first.ip;
      }
    } catch (e) {
      debugPrint('[LocalScoring] Error getting local IP: $e');
    }
    return null;
  }

  // -------------------------------------------------------------
  // HOST METHODS
  // -------------------------------------------------------------
  Future<String?> startHosting(LiveMatchSnapshot initialSnapshot, {String? customPin}) async {
    await stopHosting();
    _latestSnapshot = initialSnapshot;
    _hostIp = await getLocalIpAddress() ?? '127.0.0.1';

    // Generate memorable 6-digit PIN
    _pinCode = customPin ?? (100000 + Random().nextInt(900000)).toString();

    try {
      try {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, defaultHttpPort);
        _actualPort = defaultHttpPort;
      } catch (e) {
        // Fallback to random port if default is occupied
        _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
        _actualPort = _server!.port;
      }

      debugPrint('[LocalScoring] Host server running on $_hostIp:$_actualPort, PIN: $_pinCode');

      _server!.listen(_handleHttpRequest);
      _startBeaconBroadcaster();
      return _pinCode;
    } catch (e) {
      debugPrint('[LocalScoring] Failed to start host: $e');
      await stopHosting();
      return null;
    }
  }

  void _handleHttpRequest(HttpRequest request) async {
    if (request.uri.path == '/ping') {
      final responseMap = {
        'status': 'ok',
        'pin': _pinCode,
        'matchTitle': _latestSnapshot?.match.title ?? 'Live Match',
        'battingTeam': _latestSnapshot?.battingTeam.name,
        'bowlingTeam': _latestSnapshot?.bowlingTeam.name,
        'runs': _latestSnapshot?.currentInnings.totalRuns ?? 0,
        'wickets': _latestSnapshot?.currentInnings.totalWickets ?? 0,
        'overs': _latestSnapshot?.currentInnings.oversDisplay ?? '0.0',
      };
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(responseMap))
        ..close();
      return;
    }

    if (request.uri.path == '/live-score') {
      try {
        final socket = await WebSocketTransformer.upgrade(request);
        _handleIncomingViewerSocket(socket, request.connectionInfo?.remoteAddress.address ?? 'Unknown');
      } catch (e) {
        debugPrint('[LocalScoring] WebSocket upgrade failed: $e');
      }
      return;
    }

    request.response
      ..statusCode = HttpStatus.notFound
      ..write('Cricket Live Score Server')
      ..close();
  }

  void _handleIncomingViewerSocket(WebSocket socket, String clientIp) {
    String? assignedViewerId;

    socket.listen(
      (data) {
        try {
          final msg = jsonDecode(data.toString()) as Map<String, dynamic>;
          final type = msg['type']?.toString();

          if (type == 'join') {
            final pin = msg['pin']?.toString().replaceAll(' ', '').trim();
            final deviceId = msg['deviceId']?.toString() ?? 'device_${Random().nextInt(9999)}';
            final deviceName = msg['deviceName']?.toString() ?? 'Viewer Phone';

            if (pin != _pinCode) {
              socket.add(jsonEncode({
                'type': 'rejected',
                'message': 'Invalid 6-digit connection code. Please check and try again.',
              }));
              socket.close(WebSocketStatus.normalClosure, 'PIN mismatch');
              return;
            }

            // Valid PIN: Register viewer
            assignedViewerId = deviceId;
            final viewerDevice = ViewerDevice(
              id: deviceId,
              ip: clientIp,
              deviceName: deviceName,
              connectedAt: DateTime.now().millisecondsSinceEpoch,
            );

            _viewers[deviceId] = (socket: socket, device: viewerDevice);
            onHostViewersChanged?.call(viewers);

            // Send welcome confirmation
            socket.add(jsonEncode({
              'type': 'welcome',
              'viewerId': deviceId,
            }));

            // Immediately send current live match state
            if (_latestSnapshot != null) {
              socket.add(jsonEncode({
                'type': 'match_state',
                'data': _latestSnapshot!.toMap(),
              }));
            }
          } else if (type == 'leave') {
            if (assignedViewerId != null) {
              _viewers.remove(assignedViewerId);
              onHostViewersChanged?.call(viewers);
            }
            socket.close(WebSocketStatus.normalClosure, 'Viewer left');
          } else if (type == 'ping') {
            socket.add(jsonEncode({'type': 'pong'}));
          }
        } catch (e) {
          debugPrint('[LocalScoring] Error parsing client message: $e');
        }
      },
      onDone: () {
        if (assignedViewerId != null) {
          _viewers.remove(assignedViewerId);
          onHostViewersChanged?.call(viewers);
        }
      },
      onError: (err) {
        if (assignedViewerId != null) {
          _viewers.remove(assignedViewerId);
          onHostViewersChanged?.call(viewers);
        }
      },
      cancelOnError: true,
    );
  }

  void _startBeaconBroadcaster() async {
    try {
      _beaconSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _beaconSocket!.broadcastEnabled = true;

      _beaconTimer?.cancel();
      _beaconTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
        if (_beaconSocket == null || _pinCode == null || _server == null) return;
        try {
          final payload = jsonEncode({
            'pin': _pinCode,
            'hostIp': _hostIp,
            'port': _actualPort,
            'matchTitle': _latestSnapshot?.match.title ?? 'Cricket Match',
            'battingTeamName': _latestSnapshot?.battingTeam.name,
            'bowlingTeamName': _latestSnapshot?.bowlingTeam.name,
            'scoreRuns': _latestSnapshot?.currentInnings.totalRuns ?? 0,
            'scoreWickets': _latestSnapshot?.currentInnings.totalWickets ?? 0,
            'oversDisplay': _latestSnapshot?.currentInnings.oversDisplay ?? '0.0',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });

          final bytes = utf8.encode(payload);
          _beaconSocket?.send(bytes, InternetAddress('255.255.255.255'), defaultBeaconPort);
        } catch (e) {
          // Ignore transient socket broadcast errors
        }
      });
    } catch (e) {
      debugPrint('[LocalScoring] Failed to start UDP beacon broadcaster: $e');
    }
  }

  void broadcastSnapshot(LiveMatchSnapshot snapshot) {
    _latestSnapshot = snapshot;
    if (_viewers.isEmpty) return;

    final payload = jsonEncode({
      'type': 'match_state',
      'data': snapshot.toMap(),
    });

    final disconnectedKeys = <String>[];
    for (final entry in _viewers.entries) {
      try {
        entry.value.socket.add(payload);
      } catch (e) {
        disconnectedKeys.add(entry.key);
      }
    }

    if (disconnectedKeys.isNotEmpty) {
      for (final k in disconnectedKeys) {
        _viewers.remove(k);
      }
      onHostViewersChanged?.call(viewers);
    }
  }

  void disconnectViewer(String viewerId) {
    final entry = _viewers[viewerId];
    if (entry != null) {
      try {
        entry.socket.add(jsonEncode({
          'type': 'disconnected',
          'reason': 'Disconnected by host',
        }));
        entry.socket.close(WebSocketStatus.normalClosure, 'Disconnected by host');
      } catch (_) {}
      _viewers.remove(viewerId);
      onHostViewersChanged?.call(viewers);
    }
  }

  Future<void> stopHosting() async {
    _beaconTimer?.cancel();
    _beaconTimer = null;
    _beaconSocket?.close();
    _beaconSocket = null;

    for (final entry in _viewers.values) {
      try {
        entry.socket.add(jsonEncode({
          'type': 'stopped',
          'reason': 'Host stopped live sharing',
        }));
        entry.socket.close(WebSocketStatus.normalClosure, 'Host stopped session');
      } catch (_) {}
    }
    _viewers.clear();
    onHostViewersChanged?.call([]);

    await _server?.close(force: true);
    _server = null;
    _pinCode = null;
    _hostIp = null;
  }

  // -------------------------------------------------------------
  // BEACON DISCOVERY (VIEWER SIDE)
  // -------------------------------------------------------------
  Future<void> startBeaconDiscovery() async {
    if (_discoverySocket != null) return;
    try {
      _discoverySocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        defaultBeaconPort,
        reuseAddress: true,
        reusePort: true,
      );

      _discoverySocket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _discoverySocket?.receive();
          if (datagram != null) {
            try {
              final raw = utf8.decode(datagram.data);
              final map = jsonDecode(raw) as Map<String, dynamic>;
              final beacon = DiscoveredMatchBeacon.fromMap(map);
              _discoveredMatches[beacon.pin] = beacon;
              onDiscoveredMatchesChanged?.call(discoveredMatches);
            } catch (_) {}
          }
        }
      });

      // Periodically prune stale beacons older than 6 seconds
      _beaconPruneTimer?.cancel();
      _beaconPruneTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final stale = <String>[];
        for (final entry in _discoveredMatches.entries) {
          if (now - entry.value.timestamp > 6000) {
            stale.add(entry.key);
          }
        }
        if (stale.isNotEmpty) {
          for (final key in stale) {
            _discoveredMatches.remove(key);
          }
          onDiscoveredMatchesChanged?.call(discoveredMatches);
        }
      });
    } catch (e) {
      debugPrint('[LocalScoring] Error binding discovery socket: $e');
    }
  }

  void stopBeaconDiscovery() {
    _beaconPruneTimer?.cancel();
    _beaconPruneTimer = null;
    _discoverySocket?.close();
    _discoverySocket = null;
    _discoveredMatches.clear();
  }

  // -------------------------------------------------------------
  // VIEWER METHODS
  // -------------------------------------------------------------
  Future<bool> connectAsViewer(
    String pin, {
    String? directHostIp,
    int? directPort,
    String? deviceId,
    String? deviceName,
  }) async {
    _isManualDisconnect = false;
    _targetPin = pin.replaceAll(' ', '').trim();
    _deviceId = deviceId ?? 'viewer_${Random().nextInt(99999)}';
    _deviceName = deviceName ?? 'Viewer Device';

    _setViewerStatus(ViewerConnectionStatus.connecting);

    // 1. Resolve Host IP and Port
    String? resolvedHostIp = directHostIp?.trim();
    int resolvedPort = directPort ?? defaultHttpPort;

    if (resolvedHostIp == null || resolvedHostIp.isEmpty) {
      // Check already discovered beacons
      final cached = _discoveredMatches[_targetPin];
      if (cached != null) {
        resolvedHostIp = cached.hostIp;
        resolvedPort = cached.port;
      }
    }

    // 2. Fast-Path for Mobile Hotspot: Check common Hotspot Gateway IPs first (< 15ms)
    if (resolvedHostIp == null || resolvedHostIp.isEmpty) {
      resolvedHostIp = await _checkHotspotGateways(_targetPin!);
    }

    // 3. If not found, wait up to 1.5 seconds on discovery socket
    if (resolvedHostIp == null || resolvedHostIp.isEmpty) {
      await startBeaconDiscovery();
      for (int i = 0; i < 15; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        final match = _discoveredMatches[_targetPin];
        if (match != null) {
          resolvedHostIp = match.hostIp;
          resolvedPort = match.port;
          break;
        }
      }
    }

    // 4. Fallback: Subnet Fast Scan on local Wi-Fi
    if (resolvedHostIp == null || resolvedHostIp.isEmpty) {
      resolvedHostIp = await _scanSubnetForPin(_targetPin!);
    }

    if (resolvedHostIp == null || resolvedHostIp.isEmpty) {
      _setViewerStatus(
        ViewerConnectionStatus.disconnected,
        error: 'Host match not found on Wi-Fi/Hotspot. Ensure both devices are connected to the same network or host hotspot, and the 6-digit code is correct.',
      );
      return false;
    }

    _targetHostIp = resolvedHostIp;
    _targetPort = resolvedPort;

    return await _performWebSocketConnect();
  }

  Future<String?> _checkHotspotGateways(String pin) async {
    try {
      final myIp = await getLocalIpAddress();
      final candidates = <String>{
        '192.168.43.1', // Android Hotspot default gateway
        '172.20.10.1',  // iOS Hotspot default gateway
      };

      if (myIp != null && myIp.contains('.')) {
        final parts = myIp.split('.');
        if (parts.length == 4) {
          candidates.add('${parts[0]}.${parts[1]}.${parts[2]}.1'); // Subnet default router/AP
        }
      }

      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 600);
      for (final ip in candidates) {
        try {
          final req = await client.getUrl(Uri.parse('http://$ip:$defaultHttpPort/ping'));
          final res = await req.close();
          if (res.statusCode == 200) {
            final body = await res.transform(utf8.decoder).join();
            final map = jsonDecode(body) as Map<String, dynamic>;
            if (map['pin']?.toString() == pin) {
              client.close(force: true);
              return ip;
            }
          }
        } catch (_) {}
      }
      client.close(force: true);
    } catch (_) {}
    return null;
  }

  Future<String?> _scanSubnetForPin(String pin) async {
    try {
      final myIp = await getLocalIpAddress();
      if (myIp == null || !myIp.contains('.')) return null;

      final parts = myIp.split('.');
      if (parts.length != 4) return null;
      final subnetPrefix = '${parts[0]}.${parts[1]}.${parts[2]}.';

      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 900);
      final completer = Completer<String?>();

      // Scan gateway (.1) first, then nearby IPs within +/- 30 of current IP
      final myLast = int.tryParse(parts[3]) ?? 100;
      final priorities = <int>[1]; // Hotspot router gateway is index 1
      for (int delta = 1; delta <= 30; delta++) {
        if (myLast - delta > 1) priorities.add(myLast - delta);
        if (myLast + delta < 254) priorities.add(myLast + delta);
      }
      for (int i = 2; i < 254; i++) {
        if (!priorities.contains(i)) priorities.add(i);
      }

      // Check in concurrent batches of 25
      const batchSize = 25;
      for (int i = 0; i < priorities.length; i += batchSize) {
        if (completer.isCompleted) break;
        final batch = priorities.sublist(i, min(i + batchSize, priorities.length));

        await Future.wait(batch.map((lastOctet) async {
          if (completer.isCompleted) return;
          final testIp = '$subnetPrefix$lastOctet';
          try {
            final req = await client.getUrl(Uri.parse('http://$testIp:$defaultHttpPort/ping'));
            final res = await req.close();
            if (res.statusCode == 200) {
              final body = await res.transform(utf8.decoder).join();
              final map = jsonDecode(body) as Map<String, dynamic>;
              if (map['pin']?.toString() == pin) {
                if (!completer.isCompleted) {
                  completer.complete(testIp);
                }
              }
            }
          } catch (_) {}
        }));
      }

      client.close(force: true);
      if (completer.isCompleted) {
        return await completer.future;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> _performWebSocketConnect() async {
    final handshakeCompleter = Completer<bool>();
    try {
      final wsUri = Uri.parse('ws://$_targetHostIp:$_targetPort/live-score');
      debugPrint('[LocalScoring] Connecting to $wsUri...');

      final socket = await WebSocket.connect(wsUri.toString())
          .timeout(const Duration(seconds: 4));

      _viewerSocket = socket;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;

      // Send join message
      socket.add(jsonEncode({
        'type': 'join',
        'pin': _targetPin,
        'deviceId': _deviceId,
        'deviceName': _deviceName,
      }));

      socket.listen(
        (data) {
          try {
            final msg = jsonDecode(data.toString()) as Map<String, dynamic>;
            final type = msg['type']?.toString();

            if (type == 'welcome') {
              _setViewerStatus(ViewerConnectionStatus.connected);
              if (!handshakeCompleter.isCompleted) {
                handshakeCompleter.complete(true);
              }
            } else if (type == 'match_state') {
              final snapshotMap = Map<String, dynamic>.from(msg['data'] as Map);
              final snapshot = LiveMatchSnapshot.fromMap(snapshotMap);
              _latestSnapshot = snapshot;
              onSnapshotReceived?.call(snapshot);
            } else if (type == 'rejected') {
              final reason = msg['message']?.toString() ?? 'Connection rejected by host';
              _setViewerStatus(ViewerConnectionStatus.rejected, error: reason);
              if (!handshakeCompleter.isCompleted) {
                handshakeCompleter.complete(false);
              }
              disconnectViewerSession(keepRejectedStatus: true);
            } else if (type == 'disconnected') {
              final reason = msg['reason']?.toString() ?? 'Disconnected by host';
              _setViewerStatus(ViewerConnectionStatus.disconnected, error: reason);
              disconnectViewerSession();
            } else if (type == 'stopped') {
              _setViewerStatus(ViewerConnectionStatus.disconnected, error: 'Host stopped live sharing');
              disconnectViewerSession();
            }
          } catch (e) {
            debugPrint('[LocalScoring] Error handling viewer message: $e');
          }
        },
        onDone: () {
          if (!handshakeCompleter.isCompleted) {
            handshakeCompleter.complete(false);
          }
          _handleViewerConnectionLoss();
        },
        onError: (err) {
          if (!handshakeCompleter.isCompleted) {
            handshakeCompleter.complete(false);
          }
          _handleViewerConnectionLoss(error: err.toString());
        },
        cancelOnError: true,
      );

      return await handshakeCompleter.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () => false,
      );
    } catch (e) {
      debugPrint('[LocalScoring] Failed to connect WebSocket: $e');
      if (!handshakeCompleter.isCompleted) {
        handshakeCompleter.complete(false);
      }
      _handleViewerConnectionLoss(error: e.toString());
      return false;
    }
  }

  void _handleViewerConnectionLoss({String? error}) {
    if (_viewerStatus == ViewerConnectionStatus.rejected) {
      return;
    }

    if (_isManualDisconnect) {
      _setViewerStatus(ViewerConnectionStatus.disconnected);
      return;
    }

    _setViewerStatus(ViewerConnectionStatus.reconnecting, error: error);

    // Schedule auto-reconnection
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) async {
      if (_isManualDisconnect || _viewerStatus == ViewerConnectionStatus.connected) {
        _reconnectTimer?.cancel();
        return;
      }
      debugPrint('[LocalScoring] Attempting to reconnect to Host...');
      final ok = await _performWebSocketConnect();
      if (ok) {
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
      }
    });
  }

  void disconnectViewerSession({bool keepRejectedStatus = false}) {
    _isManualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    try {
      _viewerSocket?.add(jsonEncode({'type': 'leave'}));
      _viewerSocket?.close(WebSocketStatus.normalClosure, 'Viewer leaving');
    } catch (_) {}
    _viewerSocket = null;
    if (!keepRejectedStatus) {
      _setViewerStatus(ViewerConnectionStatus.disconnected);
    }
  }

  void _setViewerStatus(ViewerConnectionStatus status, {String? error}) {
    _viewerStatus = status;
    _viewerError = error;
    onViewerStatusChanged?.call(status, error);
  }

  void dispose() {
    stopHosting();
    stopBeaconDiscovery();
    disconnectViewerSession();
  }
}

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/core/services/local_scoring_service.dart';
import 'package:scorecard/data/models/ball.dart';
import 'package:scorecard/data/models/batting_stat.dart';
import 'package:scorecard/data/models/bowling_stat.dart';
import 'package:scorecard/data/models/innings.dart';
import 'package:scorecard/data/models/local_scoring_models.dart';
import 'package:scorecard/data/models/match.dart';
import 'package:scorecard/data/models/player.dart';
import 'package:scorecard/data/models/team.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Local Network Live Scoring Models Test', () {
    final testMatch = CricketMatch(
      id: 'm1',
      title: 'T20 Championship Final',
      venue: 'Wankhede Stadium',
      matchDate: 1700000000,
      format: 'T20',
      totalOvers: 20,
      teamAId: 't1',
      teamBId: 't2',
      createdAt: 1700000000,
    );

    final testInnings = Innings(
      id: 'inn1',
      matchId: 'm1',
      inningsNumber: 1,
      battingTeamId: 't1',
      bowlingTeamId: 't2',
      totalRuns: 65,
      totalWickets: 2,
      totalLegalBalls: 30,
      createdAt: 1700000000,
    );

    final teamA = Team(
      id: 't1',
      name: 'Mumbai Strikers',
      shortName: 'MUM',
      colorValue: 0xFF2563EB,
      createdAt: 1000,
    );

    final teamB = Team(
      id: 't2',
      name: 'Chennai Kings',
      shortName: 'CHE',
      colorValue: 0xFFF59E0B,
      createdAt: 1000,
    );

    final striker = Player(
      id: 'p1',
      teamId: 't1',
      name: 'Rohit',
      role: 'Batter',
      createdAt: 1000,
    );

    final bowler = Player(
      id: 'p2',
      teamId: 't2',
      name: 'Bumrah',
      role: 'Bowler',
      createdAt: 1000,
    );

    test('LiveMatchSnapshot serialization and deserialization', () {
      final snapshot = LiveMatchSnapshot(
        match: testMatch,
        currentInnings: testInnings,
        battingTeam: teamA,
        bowlingTeam: teamB,
        striker: striker,
        currentBowler: bowler,
        battingStats: [
          BattingStat(
            id: 'bs1',
            inningsId: 'inn1',
            playerId: 'p1',
            playerName: 'Rohit',
            runs: 35,
            balls: 18,
            fours: 4,
            sixes: 2,
          ),
        ],
        bowlingStats: [
          BowlingStat(
            id: 'bw1',
            inningsId: 'inn1',
            playerId: 'p2',
            playerName: 'Bumrah',
            totalLegalBalls: 12,
            maidens: 1,
            runsConceded: 8,
            wickets: 1,
          ),
        ],
        recentBalls: [
          Ball(
            id: 'b1',
            matchId: 'm1',
            inningsId: 'inn1',
            overNumber: 0,
            ballNumber: 1,
            legalBallNumber: 1,
            bowlerId: 'p2',
            batsmanId: 'p1',
            nonStrikerId: 'p3',
            runsBat: 4,
            timestamp: 1000,
          ),
        ],
        timestamp: 1700000050,
      );

      final map = snapshot.toMap();
      final reconstructed = LiveMatchSnapshot.fromMap(map);

      expect(reconstructed.match.title, 'T20 Championship Final');
      expect(reconstructed.battingTeam.name, 'Mumbai Strikers');
      expect(reconstructed.bowlingTeam.name, 'Chennai Kings');
      expect(reconstructed.currentInnings.totalRuns, 65);
      expect(reconstructed.currentInnings.totalWickets, 2);
      expect(reconstructed.striker?.name, 'Rohit');
      expect(reconstructed.currentBowler?.name, 'Bumrah');
      expect(reconstructed.battingStats.length, 1);
      expect(reconstructed.battingStats.first.runs, 35);
      expect(reconstructed.bowlingStats.length, 1);
      expect(reconstructed.bowlingStats.first.wickets, 1);
      expect(reconstructed.recentBalls.length, 1);
      expect(reconstructed.recentBalls.first.runsBat, 4);
    });

    test('DiscoveredMatchBeacon serialization', () {
      const beacon = DiscoveredMatchBeacon(
        pin: '123456',
        hostIp: '192.168.1.50',
        port: 40404,
        matchTitle: 'India vs Australia',
        battingTeamName: 'India',
        bowlingTeamName: 'Australia',
        scoreRuns: 180,
        scoreWickets: 4,
        oversDisplay: '19.2',
        timestamp: 1700000000,
      );

      final map = beacon.toMap();
      final fromMap = DiscoveredMatchBeacon.fromMap(map);

      expect(fromMap.pin, '123456');
      expect(fromMap.hostIp, '192.168.1.50');
      expect(fromMap.matchTitle, 'India vs Australia');
      expect(fromMap.scoreRuns, 180);
      expect(fromMap.oversDisplay, '19.2');
    });

    test('ViewerDevice serialization', () {
      const device = ViewerDevice(
        id: 'dev_123',
        ip: '192.168.1.88',
        deviceName: 'Pixel 8',
        connectedAt: 1700000000,
      );

      final map = device.toMap();
      final fromMap = ViewerDevice.fromMap(map);

      expect(fromMap.id, 'dev_123');
      expect(fromMap.ip, '192.168.1.88');
      expect(fromMap.deviceName, 'Pixel 8');
    });
  });

  group('LocalScoringService Host & Viewer Integration Test', () {
    late LocalScoringService hostService;
    late LocalScoringService viewerService;

    final testSnapshot = LiveMatchSnapshot(
      match: const CricketMatch(
        id: 'm1',
        title: 'Derby Clash',
        venue: 'Eden Gardens',
        matchDate: 1700000000,
        format: 'T20',
        totalOvers: 20,
        teamAId: 't1',
        teamBId: 't2',
        createdAt: 1700000000,
      ),
      currentInnings: const Innings(
        id: 'inn1',
        matchId: 'm1',
        inningsNumber: 1,
        battingTeamId: 't1',
        bowlingTeamId: 't2',
        totalRuns: 42,
        totalWickets: 1,
        totalLegalBalls: 24,
        createdAt: 1700000000,
      ),
      battingTeam: const Team(
        id: 't1',
        name: 'Team Alpha',
        shortName: 'ALP',
        colorValue: 0xFF2563EB,
        createdAt: 1000,
      ),
      bowlingTeam: const Team(
        id: 't2',
        name: 'Team Beta',
        shortName: 'BET',
        colorValue: 0xFFF59E0B,
        createdAt: 1000,
      ),
      timestamp: 1700000000,
    );

    setUp(() {
      hostService = LocalScoringService();
      viewerService = LocalScoringService();
    });

    tearDown(() async {
      await hostService.stopHosting();
      viewerService.disconnectViewerSession();
    });

    test('Host starts server and Viewer connects with valid 6-digit code', () async {
      const testPin = '654321';
      final pin = await hostService.startHosting(testSnapshot, customPin: testPin);
      expect(pin, testPin);
      expect(hostService.isHosting, true);

      final snapshotCompleter = Completer<LiveMatchSnapshot>();
      viewerService.onSnapshotReceived = (snap) {
        if (!snapshotCompleter.isCompleted) {
          snapshotCompleter.complete(snap);
        }
      };

      // Connect viewer directly using 127.0.0.1 and port
      final connected = await viewerService.connectAsViewer(
        testPin,
        directHostIp: '127.0.0.1',
        directPort: hostService.actualPort,
        deviceName: 'Spectator Phone',
      );

      expect(connected, true);
      expect(viewerService.viewerStatus, ViewerConnectionStatus.connected);

      // Verify viewer received the initial snapshot
      final receivedSnapshot = await snapshotCompleter.future.timeout(const Duration(seconds: 3));
      expect(receivedSnapshot.match.title, 'Derby Clash');
      expect(receivedSnapshot.currentInnings.totalRuns, 42);
      expect(hostService.viewers.length, 1);
      expect(hostService.viewers.first.deviceName, 'Spectator Phone');
    });

    test('Viewer rejected with invalid 6-digit code', () async {
      const correctPin = '112233';
      await hostService.startHosting(testSnapshot, customPin: correctPin);

      final connected = await viewerService.connectAsViewer(
        '999999', // Wrong PIN
        directHostIp: '127.0.0.1',
        directPort: hostService.actualPort,
      );
      expect(connected, false);

      // Wait a moment for handshake rejection
      await Future.delayed(const Duration(milliseconds: 300));
      expect(viewerService.viewerStatus, ViewerConnectionStatus.rejected);
      expect(viewerService.viewerError?.toLowerCase().contains('invalid'), true);
      expect(hostService.viewers.isEmpty, true);
    });

    test('Host broadcasts updated score snapshot to connected viewer in real-time', () async {
      const testPin = '888888';
      await hostService.startHosting(testSnapshot, customPin: testPin);

      final secondSnapshotCompleter = Completer<LiveMatchSnapshot>();
      int snapshotCount = 0;

      viewerService.onSnapshotReceived = (snap) {
        snapshotCount++;
        if (snapshotCount == 2 && !secondSnapshotCompleter.isCompleted) {
          secondSnapshotCompleter.complete(snap);
        }
      };

      await viewerService.connectAsViewer(
        testPin,
        directHostIp: '127.0.0.1',
        directPort: hostService.actualPort,
      );

      // Wait for initial handshake
      await Future.delayed(const Duration(milliseconds: 200));

      // Host updates score (e.g. Six hit -> 48 runs)
      final updatedSnapshot = LiveMatchSnapshot(
        match: testSnapshot.match,
        currentInnings: const Innings(
          id: 'inn1',
          matchId: 'm1',
          inningsNumber: 1,
          battingTeamId: 't1',
          bowlingTeamId: 't2',
          totalRuns: 48,
          totalWickets: 1,
          totalLegalBalls: 25,
          createdAt: 1700000000,
        ),
        battingTeam: testSnapshot.battingTeam,
        bowlingTeam: testSnapshot.bowlingTeam,
        timestamp: 1700000010,
      );

      hostService.broadcastSnapshot(updatedSnapshot);

      final liveUpdate = await secondSnapshotCompleter.future.timeout(const Duration(seconds: 3));
      expect(liveUpdate.currentInnings.totalRuns, 48);
      expect(liveUpdate.currentInnings.totalLegalBalls, 25);
    });

    test('Host can disconnect a specific viewer', () async {
      const testPin = '445566';
      await hostService.startHosting(testSnapshot, customPin: testPin);

      await viewerService.connectAsViewer(
        testPin,
        directHostIp: '127.0.0.1',
        directPort: hostService.actualPort,
        deviceId: 'viewer_to_kick',
      );

      await Future.delayed(const Duration(milliseconds: 200));
      expect(hostService.viewers.length, 1);

      // Host kicks viewer
      hostService.disconnectViewer('viewer_to_kick');

      await Future.delayed(const Duration(milliseconds: 200));
      expect(hostService.viewers.isEmpty, true);
      expect(viewerService.viewerStatus, ViewerConnectionStatus.disconnected);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/player.dart';
import '../../data/repositories/player_repository.dart';

class PlayerProvider extends ChangeNotifier {
  final PlayerRepository _playerRepo = PlayerRepository();
  final _uuid = const Uuid();

  List<Player> _players = [];
  Player? _selectedPlayer;
  PlayerCareerStats? _selectedPlayerStats;
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedRoleFilter = 'All';
  String? _selectedTeamFilter;

  List<Player> get players {
    return _players.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.jerseyNumber.toString() == _searchQuery;
      final matchesRole = _selectedRoleFilter == 'All' || p.role == _selectedRoleFilter;
      final matchesTeam = _selectedTeamFilter == null || p.teamId == _selectedTeamFilter;
      return matchesSearch && matchesRole && matchesTeam;
    }).toList();
  }

  Player? get selectedPlayer => _selectedPlayer;
  PlayerCareerStats? get selectedPlayerStats => _selectedPlayerStats;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedRoleFilter => _selectedRoleFilter;
  String? get selectedTeamFilter => _selectedTeamFilter;

  PlayerProvider() {
    loadPlayers();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setRoleFilter(String role) {
    _selectedRoleFilter = role;
    notifyListeners();
  }

  void setTeamFilter(String? teamId) {
    _selectedTeamFilter = teamId;
    notifyListeners();
  }

  Future<void> loadPlayers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _players = await _playerRepo.getAllPlayers();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPlayerProfile(String playerId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _selectedPlayer = await _playerRepo.getPlayerById(playerId);
      _selectedPlayerStats = await _playerRepo.getPlayerCareerStats(playerId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Player> createPlayer({
    required String teamId,
    required String name,
    required int jerseyNumber,
    required String role,
    required String battingStyle,
    required String bowlingStyle,
    bool isCaptain = false,
    bool isWicketKeeper = false,
    String? photoUrl,
  }) async {
    final player = Player(
      id: _uuid.v4(),
      teamId: teamId,
      name: name.trim(),
      jerseyNumber: jerseyNumber,
      role: role,
      battingStyle: battingStyle,
      bowlingStyle: bowlingStyle,
      isCaptain: isCaptain,
      isWicketKeeper: isWicketKeeper,
      photoUrl: photoUrl,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _playerRepo.insertPlayer(player);
    await loadPlayers();
    return player;
  }

  Future<void> updatePlayer(Player player) async {
    await _playerRepo.updatePlayer(player);
    await loadPlayers();
    if (_selectedPlayer?.id == player.id) {
      _selectedPlayer = player;
      _selectedPlayerStats = await _playerRepo.getPlayerCareerStats(player.id);
      notifyListeners();
    }
  }

  Future<void> updatePlayerPhoto(String playerId, String? photoUrl) async {
    final player = _selectedPlayer?.id == playerId
        ? _selectedPlayer!
        : _players.firstWhere((p) => p.id == playerId);
    final updated = player.copyWith(photoUrl: photoUrl);
    await updatePlayer(updated);
  }

  int generateRandomJerseyNumber(String teamId, {String? excludePlayerId}) {
    final used = _players
        .where((p) => p.teamId == teamId && p.id != excludePlayerId)
        .map((p) => p.jerseyNumber)
        .toSet();
    final available = <int>[];
    for (int i = 1; i <= 100; i++) {
      if (!used.contains(i)) {
        available.add(i);
      }
    }
    if (available.isEmpty) return 1;
    available.shuffle();
    return available.first;
  }

  bool isJerseyNumberTaken(String teamId, int jerseyNumber, {String? excludePlayerId}) {
    if (jerseyNumber < 1 || jerseyNumber > 100) return false;
    return _players.any((p) =>
        p.teamId == teamId &&
        p.jerseyNumber == jerseyNumber &&
        p.id != excludePlayerId);
  }

  bool isPlayerNameTaken(String teamId, String name, {String? excludePlayerId}) {
    final cleanName = name.trim().toLowerCase();
    if (cleanName.isEmpty) return false;
    return _players.any((p) =>
        p.teamId == teamId &&
        p.id != excludePlayerId &&
        p.name.trim().toLowerCase() == cleanName);
  }

  Future<Player?> changePlayerTeam(String playerId, String newTeamId) async {
    final player = _players.cast<Player?>().firstWhere(
          (p) => p?.id == playerId,
          orElse: () => _selectedPlayer,
        );
    if (player == null || player.teamId == newTeamId) return player;

    int jersey = player.jerseyNumber;
    // If jersey is taken in the destination team or outside 1..100, assign new unique random jersey (1-100)
    if (jersey < 1 || jersey > 100 || isJerseyNumberTaken(newTeamId, jersey, excludePlayerId: playerId)) {
      jersey = generateRandomJerseyNumber(newTeamId, excludePlayerId: playerId);
    }

    final updated = player.copyWith(
      teamId: newTeamId,
      jerseyNumber: jersey,
    );
    await updatePlayer(updated);
    return updated;
  }

  Future<void> deletePlayer(String id) async {
    await _playerRepo.deletePlayer(id);
    await loadPlayers();
  }
}

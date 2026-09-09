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

  Future<void> deletePlayer(String id) async {
    await _playerRepo.deletePlayer(id);
    await loadPlayers();
  }
}

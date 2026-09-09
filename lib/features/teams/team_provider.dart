import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/player.dart';
import '../../data/models/team.dart';
import '../../data/repositories/team_repository.dart';

class TeamProvider extends ChangeNotifier {
  final TeamRepository _teamRepo = TeamRepository();
  final _uuid = const Uuid();

  List<Team> _teams = [];
  Team? _selectedTeam;
  List<Player> _selectedTeamPlayers = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Team> get teams {
    if (_searchQuery.isEmpty) return _teams;
    return _teams
        .where((t) =>
            t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.shortName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Team? get selectedTeam => _selectedTeam;
  List<Player> get selectedTeamPlayers => _selectedTeamPlayers;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  TeamProvider() {
    loadTeams();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadTeams() async {
    _isLoading = true;
    notifyListeners();
    try {
      _teams = await _teamRepo.getAllTeams();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTeamDetails(String teamId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _selectedTeam = await _teamRepo.getTeamById(teamId);
      _selectedTeamPlayers = await _teamRepo.getPlayersForTeam(teamId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Team> createTeam({
    required String name,
    required String shortName,
    int colorValue = 0xFF0F9D58,
  }) async {
    final team = Team(
      id: _uuid.v4(),
      name: name.trim(),
      shortName: shortName.trim().toUpperCase(),
      colorValue: colorValue,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _teamRepo.insertTeam(team);
    await loadTeams();
    return team;
  }

  Future<void> updateTeam(Team team) async {
    await _teamRepo.updateTeam(team);
    await loadTeams();
    if (_selectedTeam?.id == team.id) {
      _selectedTeam = team;
      notifyListeners();
    }
  }

  Future<void> deleteTeam(String id) async {
    await _teamRepo.deleteTeam(id);
    await loadTeams();
  }

  Future<int> getPlayerCount(String teamId) async {
    return await _teamRepo.getPlayerCountForTeam(teamId);
  }

  Future<List<Player>> getPlayersForTeam(String teamId) async {
    return await _teamRepo.getPlayersForTeam(teamId);
  }
}

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/match.dart';
import '../../data/models/team.dart';
import '../../data/models/tournament.dart';
import '../../data/repositories/match_repository.dart';
import '../../data/repositories/tournament_repository.dart';

class TournamentProvider extends ChangeNotifier {
  final TournamentRepository _tourneyRepo = TournamentRepository();
  final MatchRepository _matchRepo = MatchRepository();
  final _uuid = const Uuid();

  List<Tournament> _tournaments = [];
  Tournament? _selectedTournament;
  List<Team> _selectedTournamentTeams = [];
  List<TournamentStanding> _selectedTournamentStandings = [];
  List<CricketMatch> _selectedTournamentMatches = [];
  bool _isLoading = false;

  List<Tournament> get tournaments => _tournaments;
  Tournament? get selectedTournament => _selectedTournament;
  List<Team> get selectedTournamentTeams => _selectedTournamentTeams;
  List<TournamentStanding> get selectedTournamentStandings => _selectedTournamentStandings;
  List<CricketMatch> get selectedTournamentMatches => _selectedTournamentMatches;
  bool get isLoading => _isLoading;

  TournamentProvider() {
    loadTournaments();
  }

  Future<void> loadTournaments() async {
    _isLoading = true;
    notifyListeners();
    try {
      _tournaments = await _tourneyRepo.getAllTournaments();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTournamentDetails(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _selectedTournament = await _tourneyRepo.getTournamentById(id);
      _selectedTournamentTeams = await _tourneyRepo.getTeamsForTournament(id);
      _selectedTournamentStandings = await _tourneyRepo.getStandings(id);
      _selectedTournamentMatches = await _matchRepo.getMatchesByTournament(id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Tournament> createTournament({
    required String name,
    required String format,
    required DateTime startDate,
    DateTime? endDate,
    List<String> teamIds = const [],
  }) async {
    final tourney = Tournament(
      id: _uuid.v4(),
      name: name.trim(),
      format: format,
      startDate: startDate.millisecondsSinceEpoch,
      endDate: endDate?.millisecondsSinceEpoch,
      status: 'active',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _tourneyRepo.insertTournament(tourney);
    for (final tId in teamIds) {
      await _tourneyRepo.addTeamToTournament(tourney.id, tId);
    }
    await loadTournaments();
    return tourney;
  }

  Future<void> updateTournament(Tournament tournament) async {
    await _tourneyRepo.updateTournament(tournament);
    await loadTournaments();
    if (_selectedTournament?.id == tournament.id) {
      await loadTournamentDetails(tournament.id);
    }
  }

  Future<void> deleteTournament(String id) async {
    await _tourneyRepo.deleteTournament(id);
    await loadTournaments();
  }

  Future<void> addTeam(String tournamentId, String teamId) async {
    await _tourneyRepo.addTeamToTournament(tournamentId, teamId);
    await loadTournamentDetails(tournamentId);
  }

  Future<void> removeTeam(String tournamentId, String teamId) async {
    await _tourneyRepo.removeTeamFromTournament(tournamentId, teamId);
    await loadTournamentDetails(tournamentId);
  }
}

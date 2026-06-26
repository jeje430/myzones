import '../data/repositories/tournament_catalog_repository.dart';
import '../models/tournament.dart';

/// Tournament cache backed by Laravel GET /api/tournaments.
class TournamentDataStore {
  TournamentDataStore._();
  static final TournamentDataStore instance = TournamentDataStore._();

  final TournamentCatalogRepository _repository =
      TournamentCatalogRepository.instance;

  final Map<String, Tournament> _tournaments = {};
  bool _isLoaded = false;
  Future<void>? _loadFuture;

  Future<void> ensureLoaded({bool forceRefresh = false}) {
    if (_isLoaded && !forceRefresh) {
      return Future.value();
    }

    return _loadFuture ??= _loadFromApi(forceRefresh: forceRefresh);
  }

  Future<void> _loadFromApi({required bool forceRefresh}) async {
    try {
      final tournaments =
          await _repository.fetchAll(forceRefresh: forceRefresh);
      _tournaments
        ..clear()
        ..addEntries(tournaments.map((t) => MapEntry(t.id, t)));
      _isLoaded = true;
    } catch (_) {
      if (forceRefresh) {
        _tournaments.clear();
      }
      rethrow;
    } finally {
      _loadFuture = null;
    }
  }

  List<String> loungeIdsWithTournaments() {
    return _tournaments.values.map((t) => t.loungeId).toSet().toList();
  }

  List<Tournament> allTournaments() => _tournaments.values.toList();

  List<String> allGameNames() {
    return allTournaments()
        .map((t) => t.gameName)
        .toSet()
        .toList()
      ..sort();
  }

  bool loungeHasTournamentMatchingGame(String loungeId, String gameQuery) {
    if (gameQuery.isEmpty) return true;
    final q = gameQuery.toLowerCase();
    return tournamentsForLounge(loungeId)
        .any((t) => t.gameName.toLowerCase().contains(q));
  }

  List<Tournament> tournamentsForLounge(String loungeId) {
    return _tournaments.values
        .where((t) => t.loungeId == loungeId)
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  List<Tournament> currentTournamentsForLounge(String loungeId) {
    return tournamentsForLounge(loungeId).where((t) => t.isCurrent).toList();
  }

  List<Tournament> pastTournamentsForLounge(String loungeId) {
    return tournamentsForLounge(loungeId).where((t) => t.isPast).toList();
  }

  Tournament? getTournament(String id) => _tournaments[id];

  void updateTournament(Tournament tournament) {
    _tournaments[tournament.id] = tournament;
  }

  Future<TournamentRegisterResult> addParticipantViaApi({
    required String tournamentId,
    required String playerName,
  }) async {
    final result = await _repository.register(
      tournamentId: tournamentId,
      playerName: playerName,
    );
    _tournaments[tournamentId] = result.tournament;
    return result;
  }

  Future<Tournament?> withdrawViaApi({required String tournamentId}) async {
    final updated = await _repository.unregister(tournamentId: tournamentId);
    if (updated != null) {
      _tournaments[tournamentId] = updated;
    }
    return updated;
  }
}

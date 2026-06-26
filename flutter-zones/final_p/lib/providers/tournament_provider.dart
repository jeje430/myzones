import 'package:flutter/material.dart';

import '../core/http/api_client.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/tournament_catalog_repository.dart';
import '../models/booking.dart';
import '../models/notification_model.dart';
import '../models/tournament.dart';
import '../services/tournament_data_store.dart';
import '../utils/date_format_utils.dart';
import 'app_state_provider.dart';

class TournamentProvider extends ChangeNotifier {
  final TournamentDataStore _store = TournamentDataStore.instance;
  final TournamentCatalogRepository _repository =
      TournamentCatalogRepository.instance;

  final List<TournamentRegistration> _registrations = [];
  List<TournamentSubscription> _mySubscriptions = [];
  List<TournamentSubscription> _activeRegistrations = [];
  List<TournamentSubscription> _participationHistory = [];
  bool _isLoading = false;
  bool _isRegistering = false;
  bool _subscriptionsLoading = false;
  bool _activeRegistrationsLoading = false;
  bool _participationHistoryLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isRegistering => _isRegistering;
  bool get subscriptionsLoading => _subscriptionsLoading;
  bool get activeRegistrationsLoading => _activeRegistrationsLoading;
  bool get participationHistoryLoading => _participationHistoryLoading;
  String? get error => _error;
  List<TournamentRegistration> get registrations =>
      List.unmodifiable(_registrations);

  List<TournamentSubscription> get myActiveSubscriptions =>
      _activeRegistrations.isNotEmpty
          ? List.unmodifiable(_activeRegistrations)
          : _mySubscriptions.where((s) => s.isActive).toList(growable: false);

  List<TournamentSubscription> get participationHistory =>
      List.unmodifiable(_participationHistory);

  TournamentProvider() {
    loadTournaments();
  }

  Future<void> loadTournaments({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _store.ensureLoaded(forceRefresh: forceRefresh);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMySubscriptions({bool forceRefresh = false}) async {
    if (_subscriptionsLoading && !forceRefresh) return;

    _subscriptionsLoading = true;
    notifyListeners();

    try {
      final rows = await _repository.fetchMyRegistrations();
      _mySubscriptions = rows.map(TournamentSubscription.fromApi).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _subscriptionsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadActiveRegistrations({bool forceRefresh = false}) async {
    if (_activeRegistrationsLoading && !forceRefresh) return;

    _activeRegistrationsLoading = true;
    notifyListeners();

    try {
      final rows = await _repository.fetchMyActiveRegistrations();
      _activeRegistrations = rows.map(TournamentSubscription.fromApi).toList();
      for (final row in _activeRegistrations) {
        _syncRegistrationCounts(row);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _activeRegistrationsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadParticipationHistory({bool forceRefresh = false}) async {
    if (_participationHistoryLoading && !forceRefresh) return;

    _participationHistoryLoading = true;
    notifyListeners();

    try {
      final rows = await _repository.fetchMyParticipationHistory();
      _participationHistory = rows.map(TournamentSubscription.fromApi).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _participationHistoryLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncCustomerParticipation({bool forceRefresh = true}) async {
    await Future.wait([
      loadTournaments(forceRefresh: forceRefresh),
      loadActiveRegistrations(forceRefresh: forceRefresh),
      loadParticipationHistory(forceRefresh: forceRefresh),
      loadMySubscriptions(forceRefresh: forceRefresh),
    ]);
  }

  Future<Tournament?> fetchTournamentBracket(String tournamentId) async {
    try {
      final tournament = await _repository.fetchBracket(tournamentId);
      mergeTournament(tournament);
      return tournament;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void _syncRegistrationCounts(TournamentSubscription row) {
    final existing = _store.getTournament(row.tournamentId);
    if (existing == null) return;

    _store.updateTournament(
      existing.copyWith(
        participantsCount: row.participantsCount,
        isFull: row.isFull,
        isRegistrationOpen: row.isRegistrationOpen,
        canJoin: !row.isFull && row.isRegistrationOpen,
        myRegistrationStatus: row.isActive ? 'registered' : null,
      ),
    );
  }

  List<String> loungeIdsWithTournaments() => _store.loungeIdsWithTournaments();

  List<String> allGameNames() => _store.allGameNames();

  bool loungeMatchesGameFilter(String loungeId, String gameQuery) =>
      _store.loungeHasTournamentMatchingGame(loungeId, gameQuery);

  List<Tournament> currentTournamentsForLounge(String loungeId) =>
      _store.currentTournamentsForLounge(loungeId);

  List<Tournament> pastTournamentsForLounge(String loungeId) =>
      _store.pastTournamentsForLounge(loungeId);

  List<Tournament> allCurrentTournaments() =>
      _store.allTournaments().where((t) => t.isCurrent).toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));

  Tournament? getTournament(String id) => _store.getTournament(id);

  void mergeTournament(Tournament tournament) {
    _store.updateTournament(tournament);
    notifyListeners();
  }

  bool isJoined(String tournamentId) {
    final tournament = _store.getTournament(tournamentId);
    if (tournament?.isJoined == true) return true;
    if (_activeRegistrations.any((s) => s.tournamentId == tournamentId && s.isActive)) {
      return true;
    }
    if (_mySubscriptions.any((s) => s.tournamentId == tournamentId && s.isActive)) {
      return true;
    }
    return _registrations.any(
      (r) => r.tournamentId == tournamentId && r.isActive,
    );
  }

  TournamentRegistration? activeRegistration(String tournamentId) {
    try {
      return _registrations.firstWhere(
        (r) => r.tournamentId == tournamentId && r.isActive,
      );
    } catch (_) {
      return null;
    }
  }

  TournamentRegistration? registrationById(String registrationId) {
    try {
      return _registrations.firstWhere((r) => r.id == registrationId);
    } catch (_) {
      return null;
    }
  }

  Future<TournamentRegistration?> registerForTournament({
    required Tournament tournament,
    required String loungeName,
    required String playerName,
    required AppStateProvider appState,
  }) async {
    if (AuthRepository.instance.authToken == null ||
        AuthRepository.instance.authToken!.isEmpty) {
      _error = 'يجب تسجيل الدخول أولاً للاشتراك في البطولة';
      notifyListeners();
      return null;
    }

    if (isJoined(tournament.id)) return activeRegistration(tournament.id);

    final latest = _store.getTournament(tournament.id) ?? tournament;
    if (!latest.isRegistrationOpen) {
      _error = 'انتهى موعد التسجيل في هذه البطولة';
      notifyListeners();
      return null;
    }
    if (latest.isFull || latest.registeredParticipantCount >= latest.maxParticipants) {
      _error = 'اكتمل عدد المشاركين في هذه البطولة';
      notifyListeners();
      return null;
    }

    _isRegistering = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _store.addParticipantViaApi(
        tournamentId: tournament.id,
        playerName: playerName.trim().isEmpty ? appState.userName : playerName,
      );

      final live = result.tournament;
      final participantId = result.participantId;
      final participantName = result.participantName;
      final firstMatch = live.firstMatchForParticipant(participantId);
      final reminderStart = firstMatch?.scheduledAt ?? live.startDate;

      final registration = TournamentRegistration(
        id: 'TR-$participantId',
        tournamentId: tournament.id,
        loungeId: tournament.loungeId,
        loungeName: loungeName,
        tournamentTitle: tournament.title,
        playerId: participantId,
        playerName: participantName,
        paymentMethod: PaymentStatus.paid,
        registeredAt: DateTime.now(),
        entryFee: tournament.entryFee,
        startDate: reminderStart,
      );

      _registrations.insert(0, registration);

      appState.addTournamentBooking(
        id: registration.id,
        tournamentTitle: tournament.title,
        day: formatArabicDate(tournament.startDate),
        time: firstMatch != null
            ? formatHourLabel(firstMatch.scheduledAt!)
            : formatHourLabel(tournament.startDate),
        entryFee: tournament.entryFee,
        loungeName: loungeName,
        loungeId: tournament.loungeId,
        tournamentId: tournament.id,
        gameName: tournament.gameName,
        paymentStatus: PaymentStatus.paid,
        startDateTime: reminderStart,
      );

      appState.pushNotification(
        AppNotification(
          id: 'tournament-confirm-${registration.id}',
          title: 'تم تأكيد اشتراكك',
          body: 'تم تأكيد اشتراكك في ${tournament.title} بنجاح!',
          createdAt: DateTime.now(),
          icon: Icons.emoji_events,
          color: const Color(0xFFA020F0),
          tournamentId: tournament.id,
          type: NotificationType.general,
        ),
      );

      await syncCustomerParticipation(forceRefresh: true);
      notifyListeners();
      return registration;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _error = 'يجب تسجيل الدخول أولاً للاشتراك في البطولة';
      } else if (e.statusCode == 409) {
        await syncCustomerParticipation(forceRefresh: true);
        _error = e.message;
      } else {
        _error = e.message;
      }
      return null;
    } catch (e) {
      _error = 'فشل تأكيد الاشتراك — حاول مرة أخرى';
      return null;
    } finally {
      _isRegistering = false;
      notifyListeners();
    }
  }

  Future<bool> withdrawFromTournament({
    required String tournamentId,
    AppStateProvider? appState,
    String? registrationId,
  }) async {
    try {
      final updated = await _store.withdrawViaApi(tournamentId: tournamentId);
      if (updated != null) {
        mergeTournament(updated);
      }

      final registrationIndex = _registrations.indexWhere(
        (r) => r.tournamentId == tournamentId && r.isActive,
      );
      if (registrationIndex != -1) {
        registrationId ??= _registrations[registrationIndex].id;
        _registrations[registrationIndex] =
            _registrations[registrationIndex].copyWith(
          status: TournamentRegistrationStatus.cancelled,
        );
      }

      if (registrationId != null && appState != null) {
        appState.cancelTournamentBooking(registrationId);
      }

      _activeRegistrations = _activeRegistrations
          .where((s) => s.tournamentId != tournamentId)
          .toList();
      _mySubscriptions = _mySubscriptions
          .where((s) => s.tournamentId != tournamentId || !s.isActive)
          .toList();

      await syncCustomerParticipation(forceRefresh: true);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelSubscription({
    required String tournamentId,
    AppStateProvider? appState,
  }) async {
    return withdrawFromTournament(
      tournamentId: tournamentId,
      appState: appState,
      registrationId: activeRegistration(tournamentId)?.id,
    );
  }

  Future<bool> cancelRegistration({
    required String tournamentId,
    required String playerId,
    required AppStateProvider appState,
    required String registrationId,
  }) async {
    return cancelSubscription(
      tournamentId: tournamentId,
      appState: appState,
    );
  }
}

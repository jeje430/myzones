import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/notification_model.dart';
import '../models/tournament.dart';
import '../services/tournament_data_store.dart';
import '../utils/date_format_utils.dart';
import 'app_state_provider.dart';

class TournamentProvider extends ChangeNotifier {
  final TournamentDataStore _store = TournamentDataStore.instance;
  final List<TournamentRegistration> _registrations = [];
  bool _isRegistering = false;
  String? _error;

  bool get isRegistering => _isRegistering;
  String? get error => _error;
  List<TournamentRegistration> get registrations =>
      List.unmodifiable(_registrations);

  List<String> loungeIdsWithTournaments() => _store.loungeIdsWithTournaments();

  List<String> allGameNames() => _store.allGameNames();

  bool loungeMatchesGameFilter(String loungeId, String gameQuery) =>
      _store.loungeHasTournamentMatchingGame(loungeId, gameQuery);

  List<Tournament> currentTournamentsForLounge(String loungeId) =>
      _store.currentTournamentsForLounge(loungeId);

  List<Tournament> pastTournamentsForLounge(String loungeId) =>
      _store.pastTournamentsForLounge(loungeId);

  Tournament? getTournament(String id) => _store.getTournament(id);

  bool isJoined(String tournamentId) {
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
    if (isJoined(tournament.id)) return activeRegistration(tournament.id);

    final latest = _store.getTournament(tournament.id) ?? tournament;
    if (latest.registeredParticipantCount >= Tournament.kMaxCapacity) {
      _error = 'اكتمل عدد المشاركين في هذه البطولة';
      notifyListeners();
      return null;
    }

    _isRegistering = true;
    _error = null;
    notifyListeners();

    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));

      final participant = TournamentParticipant(
        id: TournamentDataStore.currentPlayerId,
        name: playerName,
      );
      _store.addParticipant(tournament.id, participant);

      final updated = _store.getTournament(tournament.id)!;
      final firstMatch = updated.firstMatchForParticipant(participant.id);
      final reminderStart =
          firstMatch?.scheduledAt ?? updated.startDate;

      final registration = TournamentRegistration(
        id: 'TR-${DateTime.now().millisecondsSinceEpoch}',
        tournamentId: tournament.id,
        loungeId: tournament.loungeId,
        loungeName: loungeName,
        tournamentTitle: tournament.title,
        playerId: participant.id,
        playerName: playerName,
        paymentMethod: PaymentStatus.paid,
        registeredAt: DateTime.now(),
        entryFee: 0,
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
        entryFee: 0,
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

      return registration;
    } catch (e) {
      _error = 'فشل تأكيد الاشتراك — حاول مرة أخرى';
      return null;
    } finally {
      _isRegistering = false;
      notifyListeners();
    }
  }

  Future<bool> cancelRegistration({
    required String tournamentId,
    required String playerId,
    required AppStateProvider appState,
    required String registrationId,
  }) async {
    final registrationIndex = _registrations.indexWhere(
      (r) => r.tournamentId == tournamentId && r.isActive,
    );
    if (registrationIndex == -1) return false;

    _registrations[registrationIndex] =
        _registrations[registrationIndex].copyWith(
      status: TournamentRegistrationStatus.cancelled,
    );

    _store.removeParticipant(tournamentId, playerId);
    appState.cancelTournamentBooking(registrationId);
    notifyListeners();
    return true;
  }
}

import 'package:final_p/models/tournament.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TournamentSubscription', () {
    test('fromApi parses capacity fields', () {
      final sub = TournamentSubscription.fromApi({
        'id': '1',
        'tournament_id': '10',
        'tournament_title': 'Summer Cup',
        'game_name': 'FC 25',
        'status': 'registered',
        'status_label': 'مسجل',
        'participants_count': 7,
        'max_participants': 8,
      });

      expect(sub.capacityLabel, '7/8');
      expect(sub.isActive, isTrue);
    });

    test('isActive is false when withdrawn', () {
      final sub = TournamentSubscription.fromApi({
        'id': '1',
        'tournament_id': '10',
        'tournament_title': 'Summer Cup',
        'game_name': 'FC 25',
        'status': 'withdrawn',
        'status_label': 'منسحب',
        'participants_count': 6,
        'max_participants': 8,
      });

      expect(sub.isActive, isFalse);
      expect(sub.capacityLabel, '6/8');
    });
  });

  group('Tournament capacity label', () {
    test('formats current/max slots', () {
      final tournament = Tournament(
        id: '1',
        loungeId: '2',
        title: 'Test',
        gameName: 'Game',
        gameEmoji: '🎮',
        startDate: DateTime(2026, 7, 1),
        prizeSummary: '',
        entryFee: 0,
        status: TournamentStatus.upcoming,
        participants: [],
        matches: [],
        matchRules: '',
        maxParticipants: 16,
        participantsCount: 0,
      );

      expect(tournament.participantCapacityLabel, '0/16');
    });
  });

  group('Tournament subscription deadline', () {
    Tournament buildTournament({
      DateTime? registrationDeadline,
      bool isRegistrationOpen = true,
    }) {
      return Tournament(
        id: '1',
        loungeId: '2',
        title: 'Test Cup',
        gameName: 'Game',
        gameEmoji: '🎮',
        startDate: DateTime(2026, 7, 1),
        registrationDeadline: registrationDeadline,
        prizeSummary: '',
        entryFee: 0,
        status: TournamentStatus.upcoming,
        participants: [],
        matches: [],
        matchRules: '',
        isRegistrationOpen: isRegistrationOpen,
      );
    }

    test('isSubscriptionClosed is false while deadline is in the future', () {
      final tournament = buildTournament(
        registrationDeadline: DateTime.now().add(const Duration(hours: 2)),
        isRegistrationOpen: true,
      );

      expect(tournament.isSubscriptionClosed, isFalse);
    });

    test('isSubscriptionClosed is true after deadline passes', () {
      final tournament = buildTournament(
        registrationDeadline: DateTime.now().subtract(const Duration(minutes: 1)),
        isRegistrationOpen: false,
      );

      expect(tournament.isSubscriptionClosed, isTrue);
    });

    test('subscriptionDeadline aliases registrationDeadline', () {
      final deadline = DateTime(2026, 6, 20, 22, 0);
      final tournament = buildTournament(registrationDeadline: deadline);

      expect(tournament.subscriptionDeadline, deadline);
    });

    test('without deadline uses isRegistrationOpen from API', () {
      expect(
        buildTournament(isRegistrationOpen: true).isSubscriptionClosed,
        isFalse,
      );
      expect(
        buildTournament(isRegistrationOpen: false).isSubscriptionClosed,
        isTrue,
      );
    });
  });
}

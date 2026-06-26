import 'dart:convert';

import 'package:final_p/models/tournament.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sample Laravel POST /api/tournaments/5/register response (201).
const _sampleRegisterResponse = '''
{
  "message": "تم تأكيد اشتراكك في البطولة",
  "tournament": {
    "id": "5",
    "lounge_id": "1",
    "lounge_name": "Control Gaming",
    "title": "ليالي ابطال",
    "game_name": "fifa24",
    "game_emoji": "🎮",
    "start_date": "2026-07-01T00:00:00+00:00",
    "end_date": "2026-07-20T00:00:00+00:00",
    "registration_deadline": "2026-06-28T00:00:00+00:00",
    "prize_summary": "i phone 17 pro",
    "entry_fee": 0,
    "match_rules": "• rule one",
    "delay_minutes": 10,
    "status": "upcoming",
    "max_participants": 8,
    "participants_count": 1,
    "is_full": false,
    "is_registration_open": true,
    "can_join": false,
    "my_registration_status": "registered",
    "participants": [{"id": "12", "name": "Test Player", "avatar_url": null}],
    "matches": []
  },
  "participant": {"id": "12", "name": "Test Player", "status": "registered"}
}
''';

void main() {
  group('Subscribe API response', () {
    test('contains tournament + participant payload', () {
      final json = jsonDecode(_sampleRegisterResponse) as Map<String, dynamic>;
      final tournament = json['tournament'] as Map<String, dynamic>;
      final participant = json['participant'] as Map<String, dynamic>;

      expect(tournament['id'], '5');
      expect(tournament['is_registration_open'], isTrue);
      expect(tournament['my_registration_status'], 'registered');
      expect(participant['id'], '12');
      expect(participant['name'], isNotEmpty);
    });

    test('TournamentRegisterResult stores participant id', () {
      final result = TournamentRegisterResult(
        tournament: Tournament(
          id: '5',
          loungeId: '1',
          title: 'ليالي ابطال',
          gameName: 'fifa24',
          gameEmoji: '🎮',
          startDate: DateTime(2026, 7, 1),
          prizeSummary: '',
          entryFee: 0,
          status: TournamentStatus.upcoming,
          participants: [],
          matches: [],
          matchRules: '',
        ),
        participantId: '12',
        participantName: 'Test Player',
      );

      expect(result.participantId, '12');
      expect(result.participantName, 'Test Player');
    });
  });
}

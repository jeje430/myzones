import '../models/tournament.dart';

/// Mock tournament catalog synced with the management dashboard structure.
class TournamentDataStore {
  TournamentDataStore._();
  static final TournamentDataStore instance = TournamentDataStore._();

  static const currentPlayerId = 'player-me';

  final Map<String, Tournament> _tournaments = {};

  void seedIfEmpty() {
    if (_tournaments.isNotEmpty) return;

    final now = DateTime.now();
    final upcomingStart = now.add(const Duration(days: 5));
    final ongoingStart = now.add(const Duration(days: 2));
    final pastEnd = now.subtract(const Duration(days: 10));

    _tournaments['t-fifa-ramadan'] = _buildFifaTournament(
      id: 't-fifa-ramadan',
      loungeId: 'lounge-1',
      startDate: upcomingStart,
      status: TournamentStatus.upcoming,
    );

    _tournaments['t-pubg-challenge'] = _buildPubgTournament(
      id: 't-pubg-challenge',
      loungeId: 'lounge-1',
      startDate: ongoingStart,
      status: TournamentStatus.ongoing,
    );

    _tournaments['t-tekken-8'] = _buildTekkenTournament(
      id: 't-tekken-8',
      loungeId: 'lounge-2',
      startDate: now.add(const Duration(days: 8)),
      status: TournamentStatus.upcoming,
    );

    _tournaments['t-summer-cup'] = _buildCompletedFifaTournament(
      id: 't-summer-cup',
      loungeId: 'lounge-1',
      startDate: pastEnd,
      endDate: pastEnd.add(const Duration(days: 2)),
    );

    _tournaments['t-valorant-pro'] = _buildValorantTournament(
      id: 't-valorant-pro',
      loungeId: 'lounge-3',
      startDate: now.add(const Duration(days: 12)),
      status: TournamentStatus.upcoming,
    );

    _tournaments['t-winter-league'] = _buildCompletedPubgTournament(
      id: 't-winter-league',
      loungeId: 'lounge-2',
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now.subtract(const Duration(days: 28)),
    );
  }

  List<String> loungeIdsWithTournaments() {
    seedIfEmpty();
    return _tournaments.values.map((t) => t.loungeId).toSet().toList();
  }

  List<Tournament> allTournaments() {
    seedIfEmpty();
    return _tournaments.values.toList();
  }

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
    seedIfEmpty();
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

  Tournament? getTournament(String id) {
    seedIfEmpty();
    return _tournaments[id];
  }

  void updateTournament(Tournament tournament) {
    _tournaments[tournament.id] = tournament;
  }

  void addParticipant(String tournamentId, TournamentParticipant participant) {
    final tournament = getTournament(tournamentId);
    if (tournament == null) return;
    if (tournament.participants.any((p) => p.id == participant.id)) return;
    if (tournament.participants.length >= Tournament.kMaxCapacity) return;

    final updatedParticipants = [...tournament.participants, participant];
    final firstMatchTime = tournament.matches.isNotEmpty
        ? tournament.matches.first.scheduledAt ??
            tournament.startDate.add(const Duration(hours: 2))
        : tournament.startDate.add(const Duration(hours: 2));

    updateTournament(
      tournament.copyWith(
        participants: updatedParticipants,
        matches: _buildBracket(
          updatedParticipants,
          firstMatchTime,
          completed: tournament.status == TournamentStatus.completed,
        ),
      ),
    );
  }

  void removeParticipant(String tournamentId, String participantId) {
    final tournament = getTournament(tournamentId);
    if (tournament == null) return;

    final updatedParticipants =
        tournament.participants.where((p) => p.id != participantId).toList();
    final firstMatchTime = tournament.matches.isNotEmpty
        ? tournament.matches.first.scheduledAt ??
            tournament.startDate.add(const Duration(hours: 2))
        : tournament.startDate.add(const Duration(hours: 2));

    updateTournament(
      tournament.copyWith(
        participants: updatedParticipants,
        matches: _buildBracket(
          updatedParticipants,
          firstMatchTime,
          completed: tournament.status == TournamentStatus.completed,
        ),
      ),
    );
  }

  static const _fifaRules =
      '• نظام خروج المغلوب — 8 لاعبين\n'
      '• مباريات ربع النهائي: 6 دقائق لكل شوط\n'
      '• النهائي: 8 دقائق لكل شوط\n'
      '• يُمنع استخدام الحيل أو البرامج المحظورة';

  static const _pubgRules =
      '• فرق فردية — 8 مشاركين\n'
      '• 3 جولات — أعلى مجموع نقاط يتأهل\n'
      '• الخريطة: Erangel\n'
      '• يجب الحضور قبل 15 دقيقة من البداية';

  static const _tekkenRules =
      '• نظام خروج المغلوب — أفضل من 3\n'
      '• 8 لاعبين — مباريات فردية\n'
      '• يُسمح بجهاز تحكم واحد فقط';

  static const _valorantRules =
      '• 5 ضد 5 — تنسيق الفرق عشوائي\n'
      '• خريطة Bind — أفضل من 13\n'
      '• يُطلب حساب Riot Games نشط';

  Tournament _buildFifaTournament({
    required String id,
    required String loungeId,
    required DateTime startDate,
    required TournamentStatus status,
  }) {
    final participants = _defaultParticipants();
    final firstMatchTime = startDate.add(const Duration(hours: 2));

    return Tournament(
      id: id,
      loungeId: loungeId,
      title: 'بطولة فيفا الرمضانية',
      gameName: 'FIFA 24',
      gameEmoji: '🎮',
      startDate: startDate,
      prizeSummary: '🏆 كأس + 500 د.ل',
      entryFee: 50,
      matchRules: _fifaRules,
      status: status,
      participants: participants,
      matches: _buildBracket(participants, firstMatchTime, completed: false),
    );
  }

  Tournament _buildPubgTournament({
    required String id,
    required String loungeId,
    required DateTime startDate,
    required TournamentStatus status,
  }) {
    final participants = _defaultParticipants(includeCurrentPlayer: false);
    final firstMatchTime = startDate.add(const Duration(hours: 1));

    return Tournament(
      id: id,
      loungeId: loungeId,
      title: 'تحدي PUBG Mobile',
      gameName: 'PUBG Mobile',
      gameEmoji: '🎯',
      startDate: startDate,
      prizeSummary: '🏆 300 د.ل + هدايا',
      entryFee: 30,
      matchRules: _pubgRules,
      status: status,
      participants: participants,
      matches: _buildBracket(participants, firstMatchTime, completed: false),
    );
  }

  Tournament _buildTekkenTournament({
    required String id,
    required String loungeId,
    required DateTime startDate,
    required TournamentStatus status,
  }) {
    final participants = _defaultParticipants(includeCurrentPlayer: false);

    return Tournament(
      id: id,
      loungeId: loungeId,
      title: 'بطولة Tekken 8',
      gameName: 'Tekken 8',
      gameEmoji: '🥊',
      startDate: startDate,
      prizeSummary: '🏆 كأس + 400 د.ل',
      entryFee: 40,
      matchRules: _tekkenRules,
      status: status,
      participants: participants,
      matches: _buildBracket(
        participants,
        startDate.add(const Duration(hours: 3)),
        completed: false,
      ),
    );
  }

  Tournament _buildValorantTournament({
    required String id,
    required String loungeId,
    required DateTime startDate,
    required TournamentStatus status,
  }) {
    final participants = _defaultParticipants(includeCurrentPlayer: false);

    return Tournament(
      id: id,
      loungeId: loungeId,
      title: 'Valorant Pro League',
      gameName: 'Valorant',
      gameEmoji: '🔫',
      startDate: startDate,
      prizeSummary: '🏆 600 د.ل + ميداليات',
      entryFee: 45,
      matchRules: _valorantRules,
      status: status,
      participants: participants,
      matches: _buildBracket(
        participants,
        startDate.add(const Duration(hours: 2)),
        completed: false,
      ),
    );
  }

  Tournament _buildCompletedFifaTournament({
    required String id,
    required String loungeId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final participants = _completedParticipants(includeCurrentPlayer: true);
    final firstMatchTime = startDate.add(const Duration(hours: 2));

    return Tournament(
      id: id,
      loungeId: loungeId,
      title: 'كأس الصيف 2025',
      gameName: 'FIFA 24',
      gameEmoji: '🎮',
      startDate: startDate,
      endDate: endDate,
      prizeSummary: '🏆 كأس + 800 د.ل',
      entryFee: 50,
      matchRules: _fifaRules,
      status: TournamentStatus.completed,
      participants: participants,
      matches: _buildBracket(participants, firstMatchTime, completed: true),
    );
  }

  Tournament _buildCompletedPubgTournament({
    required String id,
    required String loungeId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final participants = _completedParticipants();
    final firstMatchTime = startDate.add(const Duration(hours: 1));

    return Tournament(
      id: id,
      loungeId: loungeId,
      title: 'دوري الشتاء PUBG',
      gameName: 'PUBG Mobile',
      gameEmoji: '🎯',
      startDate: startDate,
      endDate: endDate,
      prizeSummary: '🏆 250 د.ل',
      entryFee: 25,
      matchRules: _pubgRules,
      status: TournamentStatus.completed,
      participants: participants,
      matches: _buildBracket(participants, firstMatchTime, completed: true),
    );
  }

  List<TournamentParticipant> _defaultParticipants({
    bool includeCurrentPlayer = false,
  }) {
    const base = [
      TournamentParticipant(id: 'p1', name: 'محمد علي'),
      TournamentParticipant(id: 'p2', name: 'سارة أحمد'),
      TournamentParticipant(id: 'p3', name: 'خالد عمر'),
      TournamentParticipant(id: 'p4', name: 'ليلى حسن'),
    ];

    if (includeCurrentPlayer &&
        !base.any((p) => p.id == currentPlayerId)) {
      return [
        const TournamentParticipant(id: currentPlayerId, name: 'أحمد محمد'),
        ...base.take(Tournament.kMaxCapacity - 1),
      ];
    }
    return base;
  }

  List<TournamentParticipant> _completedParticipants({
    bool includeCurrentPlayer = false,
  }) {
    const base = [
      TournamentParticipant(id: 'p1', name: 'محمد علي'),
      TournamentParticipant(id: 'p2', name: 'سارة أحمد'),
      TournamentParticipant(id: 'p3', name: 'خالد عمر'),
      TournamentParticipant(id: 'p4', name: 'ليلى حسن'),
      TournamentParticipant(id: 'p5', name: 'يوسف كريم'),
      TournamentParticipant(id: 'p6', name: 'نور الدين'),
      TournamentParticipant(id: 'p7', name: 'أمينة سالم'),
      TournamentParticipant(id: 'p8', name: 'طارق محمود'),
    ];

    if (includeCurrentPlayer &&
        !base.any((p) => p.id == currentPlayerId)) {
      return [
        const TournamentParticipant(id: currentPlayerId, name: 'أحمد محمد'),
        ...base.take(Tournament.kMaxCapacity - 1),
      ];
    }
    return base;
  }

  List<BracketMatch> _buildBracket(
    List<TournamentParticipant> participants,
    DateTime firstRoundStart, {
    required bool completed,
  }) {
    if (participants.isEmpty) return [];

    final qfTime = firstRoundStart;
    final sfTime = firstRoundStart.add(const Duration(hours: 3));
    final finalTime = firstRoundStart.add(const Duration(hours: 6));

    TournamentParticipant? participantAt(int index) =>
        index < participants.length ? participants[index] : null;

    BracketMatch qf(int index, int p1, int p2, {bool done = false}) {
      final player1 = participantAt(p1);
      final player2 = participantAt(p2);
      final winner = done && player1 != null ? player1.id : null;
      return BracketMatch(
        id: 'qf-$index',
        round: BracketRound.quarterFinal,
        player1: player1,
        player2: player2,
        score1: done && player1 != null ? 3 : null,
        score2: done && player2 != null ? 1 : null,
        scheduledAt: qfTime.add(Duration(hours: index)),
        status: done && player1 != null && player2 != null
            ? MatchStatus.completed
            : MatchStatus.upcoming,
        winnerId: winner,
      );
    }

    BracketMatch sf(int index, TournamentParticipant p1, TournamentParticipant p2,
        {bool done = false}) {
      final winner = done ? p1.id : null;
      return BracketMatch(
        id: 'sf-$index',
        round: BracketRound.semiFinal,
        player1: p1,
        player2: p2,
        score1: done ? 2 : null,
        score2: done ? 0 : null,
        scheduledAt: sfTime.add(Duration(hours: index)),
        status: done ? MatchStatus.completed : MatchStatus.upcoming,
        winnerId: winner,
      );
    }

    final qfMatches = completed
        ? [
            qf(0, 0, 1, done: true),
            qf(1, 2, 3, done: true),
            qf(2, 4, 5, done: true),
            qf(3, 6, 7, done: true),
          ]
        : [
            qf(0, 0, 1),
            qf(1, 2, 3),
            qf(2, 4, 5),
            qf(3, 6, 7),
          ];

    final sfMatches = completed
        ? [
            sf(0, participants[0], participants[2], done: true),
            sf(1, participants[4], participants[6], done: true),
          ]
        : [
            BracketMatch(
              id: 'sf-0',
              round: BracketRound.semiFinal,
              player1: null,
              player2: null,
              scheduledAt: sfTime,
              status: MatchStatus.upcoming,
            ),
            BracketMatch(
              id: 'sf-1',
              round: BracketRound.semiFinal,
              player1: null,
              player2: null,
              scheduledAt: sfTime.add(const Duration(hours: 1)),
              status: MatchStatus.upcoming,
            ),
          ];

    final finalMatch = completed
        ? BracketMatch(
            id: 'final-1',
            round: BracketRound.finalRound,
            player1: participants[0],
            player2: participants[4],
            score1: 3,
            score2: 2,
            scheduledAt: finalTime,
            status: MatchStatus.completed,
            winnerId: participants[0].id,
          )
        : BracketMatch(
            id: 'final-1',
            round: BracketRound.finalRound,
            player1: null,
            player2: null,
            scheduledAt: finalTime,
            status: MatchStatus.upcoming,
          );

    return [...qfMatches, ...sfMatches, finalMatch];
  }
}

import 'booking.dart';

enum TournamentStatus { upcoming, ongoing, completed, cancelled }

enum BracketRound { quarterFinal, semiFinal, finalRound }

enum MatchStatus { upcoming, live, completed }

enum TournamentRegistrationStatus { active, cancelled }

class TournamentParticipant {
  const TournamentParticipant({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? avatarUrl;
}

class BracketMatch {
  const BracketMatch({
    required this.id,
    required this.round,
    this.player1,
    this.player2,
    this.score1,
    this.score2,
    this.scheduledAt,
    this.status = MatchStatus.upcoming,
    this.winnerId,
  });

  final String id;
  final BracketRound round;
  final TournamentParticipant? player1;
  final TournamentParticipant? player2;
  final int? score1;
  final int? score2;
  final DateTime? scheduledAt;
  final MatchStatus status;
  final String? winnerId;

  bool get isUpcoming => status == MatchStatus.upcoming;
  bool get isCompleted => status == MatchStatus.completed;

  bool get hasBothPlayers => player1 != null && player2 != null;

  String playerLabel(TournamentParticipant? player, BracketRound round) {
    if (player != null) return player.name;
    if (round == BracketRound.quarterFinal) return '—';
    return 'بانتظار الفائز';
  }

  String get scoreLabel {
    if (isCompleted && score1 != null && score2 != null) {
      return '$score1 - $score2';
    }
    if (!hasBothPlayers) return '—';
    if (isUpcoming) return 'لم تُلعب بعد';
    return '—';
  }
}

class Tournament {
  static const int kMaxCapacity = 8;

  const Tournament({
    required this.id,
    required this.loungeId,
    required this.title,
    required this.gameName,
    required this.gameEmoji,
    required this.startDate,
    required this.prizeSummary,
    required this.entryFee,
    required this.status,
    required this.participants,
    required this.matches,
    required this.matchRules,
    this.endDate,
    this.maxParticipants = kMaxCapacity,
  });

  final String id;
  final String loungeId;
  final String title;
  final String gameName;
  final String gameEmoji;
  final DateTime startDate;
  final DateTime? endDate;
  final String prizeSummary;
  final double entryFee;
  final String matchRules;
  final TournamentStatus status;
  final List<TournamentParticipant> participants;
  final List<BracketMatch> matches;
  final int maxParticipants;

  bool get isPast =>
      status == TournamentStatus.completed || status == TournamentStatus.cancelled;

  bool get isCurrent => !isPast;

  int get registeredParticipantCount =>
      participants.length.clamp(0, kMaxCapacity);

  String get participantCapacityLabel =>
      '$registeredParticipantCount/$kMaxCapacity';

  List<BracketMatch> matchesForRound(BracketRound round) =>
      matches.where((m) => m.round == round).toList();

  BracketMatch? firstMatchForParticipant(String participantId) {
    final playerMatches = matches
        .where(
          (m) =>
              m.player1?.id == participantId || m.player2?.id == participantId,
        )
        .toList()
      ..sort((a, b) {
        final aTime = a.scheduledAt ?? DateTime(2100);
        final bTime = b.scheduledAt ?? DateTime(2100);
        return aTime.compareTo(bTime);
      });
    return playerMatches.isEmpty ? null : playerMatches.first;
  }

  Tournament copyWith({
    List<TournamentParticipant>? participants,
    List<BracketMatch>? matches,
    TournamentStatus? status,
    String? matchRules,
  }) {
    return Tournament(
      id: id,
      loungeId: loungeId,
      title: title,
      gameName: gameName,
      gameEmoji: gameEmoji,
      startDate: startDate,
      endDate: endDate,
      prizeSummary: prizeSummary,
      entryFee: entryFee,
      matchRules: matchRules ?? this.matchRules,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      matches: matches ?? this.matches,
      maxParticipants: maxParticipants,
    );
  }
}

class TournamentRegistration {
  const TournamentRegistration({
    required this.id,
    required this.tournamentId,
    required this.loungeId,
    required this.loungeName,
    required this.tournamentTitle,
    required this.playerId,
    required this.playerName,
    required this.paymentMethod,
    required this.registeredAt,
    required this.entryFee,
    required this.startDate,
    this.status = TournamentRegistrationStatus.active,
  });

  final String id;
  final String tournamentId;
  final String loungeId;
  final String loungeName;
  final String tournamentTitle;
  final String playerId;
  final String playerName;
  final PaymentStatus paymentMethod;
  final DateTime registeredAt;
  final double entryFee;
  final DateTime startDate;
  final TournamentRegistrationStatus status;

  bool get isActive => status == TournamentRegistrationStatus.active;

  TournamentRegistration copyWith({
    TournamentRegistrationStatus? status,
  }) {
    return TournamentRegistration(
      id: id,
      tournamentId: tournamentId,
      loungeId: loungeId,
      loungeName: loungeName,
      tournamentTitle: tournamentTitle,
      playerId: playerId,
      playerName: playerName,
      paymentMethod: paymentMethod,
      registeredAt: registeredAt,
      entryFee: entryFee,
      startDate: startDate,
      status: status ?? this.status,
    );
  }
}

String bracketRoundLabel(BracketRound round) {
  switch (round) {
    case BracketRound.quarterFinal:
      return 'ربع النهائي';
    case BracketRound.semiFinal:
      return 'نصف النهائي';
    case BracketRound.finalRound:
      return 'النهائي';
  }
}

String tournamentStatusLabel(TournamentStatus status) {
  switch (status) {
    case TournamentStatus.upcoming:
      return 'قادمة';
    case TournamentStatus.ongoing:
      return 'جارية';
    case TournamentStatus.completed:
      return 'منتهية';
    case TournamentStatus.cancelled:
      return 'ملغاة';
  }
}

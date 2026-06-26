import 'booking.dart';
import '../utils/date_format_utils.dart';

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

  bool get isUpcoming => resolvedStatus == MatchStatus.upcoming;
  bool get isLive => resolvedStatus == MatchStatus.live;
  bool get isCompleted => resolvedStatus == MatchStatus.completed || winnerId != null;

  bool get hasScheduledTime => scheduledAt != null;

  /// Status derived from schedule time — future matches stay upcoming.
  MatchStatus get resolvedStatus {
    if (winnerId != null || status == MatchStatus.completed) {
      return MatchStatus.completed;
    }
    final at = scheduledAt;
    if (at != null) {
      final local = at.isUtc ? at.toLocal() : at;
      if (local.isAfter(DateTime.now())) return MatchStatus.upcoming;
      return MatchStatus.live;
    }
    if (status == MatchStatus.live) return MatchStatus.upcoming;
    return status;
  }

  String? get formattedScheduleDate {
    if (scheduledAt == null) return null;
    final local = scheduledAt!.isUtc ? scheduledAt!.toLocal() : scheduledAt!;
    return formatArabicDate(local);
  }

  String? get formattedScheduleTime {
    if (scheduledAt == null) return null;
    final local = scheduledAt!.isUtc ? scheduledAt!.toLocal() : scheduledAt!;
    return formatHourLabel(local);
  }

  bool get hasBothPlayers => player1 != null && player2 != null;

  int? get team1Score => score1;
  int? get team2Score => score2;

  String? scoreLabelForPlayer(TournamentParticipant? player) {
    if (player == null) return null;
    if (player.id == player1?.id) return _formatScore(score1);
    if (player.id == player2?.id) return _formatScore(score2);
    return null;
  }

  String _formatScore(int? value) {
    if (value == null) return '–';
    return value.toString();
  }

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

  BracketMatch copyWith({
    String? id,
    BracketRound? round,
    TournamentParticipant? player1,
    TournamentParticipant? player2,
    int? score1,
    int? score2,
    DateTime? scheduledAt,
    MatchStatus? status,
    String? winnerId,
    bool clearScheduledAt = false,
  }) {
    return BracketMatch(
      id: id ?? this.id,
      round: round ?? this.round,
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      score1: score1 ?? this.score1,
      score2: score2 ?? this.score2,
      scheduledAt: clearScheduledAt ? null : (scheduledAt ?? this.scheduledAt),
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
    );
  }

  factory BracketMatch.fromJson(Map<String, dynamic> json) {
    final winnerRaw = json['winner_id'];
    final winnerId = winnerRaw != null ? winnerRaw.toString() : null;

    DateTime? scheduledAt;
    final scheduledRaw = json['scheduled_at'];
    if (scheduledRaw != null && scheduledRaw.toString().trim().isNotEmpty) {
      final parsed = DateTime.tryParse(scheduledRaw.toString());
      if (parsed != null) {
        scheduledAt = parsed.isUtc ? parsed.toLocal() : parsed;
      }
    }

    final rawStatus = json['status']?.toString().toLowerCase() ?? 'upcoming';
    MatchStatus status;
    switch (rawStatus) {
      case 'live':
        status = MatchStatus.live;
        break;
      case 'completed':
      case 'finished':
        status = MatchStatus.completed;
        break;
      default:
        status = MatchStatus.upcoming;
    }

    if (winnerId != null) {
      status = MatchStatus.completed;
    } else if (scheduledAt != null) {
      status = scheduledAt.isAfter(DateTime.now())
          ? MatchStatus.upcoming
          : MatchStatus.live;
    } else if (status == MatchStatus.live) {
      status = MatchStatus.upcoming;
    }

    BracketRound round;
    switch (json['round']?.toString()) {
      case 'semi_final':
        round = BracketRound.semiFinal;
        break;
      case 'final':
        round = BracketRound.finalRound;
        break;
      default:
        round = BracketRound.quarterFinal;
    }

  TournamentParticipant? parsePlayer(dynamic raw) {
      if (raw is! Map<String, dynamic>) return null;
      return TournamentParticipant(
        id: raw['id']?.toString() ?? '',
        name: raw['name']?.toString() ?? '',
        avatarUrl: raw['avatar_url'] as String?,
      );
    }

    return BracketMatch(
      id: json['id']?.toString() ?? '',
      round: round,
      player1: parsePlayer(json['player1']),
      player2: parsePlayer(json['player2']),
      score1: _parseOptionalInt(json['score1'] ?? json['team1_score']),
      score2: _parseOptionalInt(json['score2'] ?? json['team2_score']),
      scheduledAt: scheduledAt,
      status: status,
      winnerId: winnerId,
    );
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
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
    this.loungeName = '',
    this.endDate,
    this.registrationDeadline,
    this.coverImageUrl,
    this.maxParticipants = kMaxCapacity,
    this.participantsCount,
    this.isFull = false,
    this.canJoin = true,
    this.isRegistrationOpen = true,
    this.myRegistrationStatus,
    this.delayMinutes = 10,
  });

  final String id;
  final String loungeId;
  final String loungeName;
  final String title;
  final String gameName;
  final String gameEmoji;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? registrationDeadline;
  final String? coverImageUrl;
  final String prizeSummary;
  final double entryFee;
  final String matchRules;
  final TournamentStatus status;
  final List<TournamentParticipant> participants;
  final List<BracketMatch> matches;
  final int maxParticipants;
  final int? participantsCount;
  final bool isFull;
  final bool canJoin;
  final bool isRegistrationOpen;
  final String? myRegistrationStatus;
  final int delayMinutes;

  bool get isPast =>
      status == TournamentStatus.completed || status == TournamentStatus.cancelled;

  bool get isCurrent => !isPast;

  bool get isJoined => myRegistrationStatus == 'registered';

  /// Backend `registration_deadline` — last moment to subscribe or withdraw.
  DateTime? get subscriptionDeadline => registrationDeadline;

  /// True once the subscription window has ended; bracket tree may be shown.
  bool get isSubscriptionClosed {
    final deadline = registrationDeadline;
    if (deadline != null) {
      return DateTime.now().isAfter(deadline);
    }
    return !isRegistrationOpen;
  }

  int get registeredParticipantCount =>
      participantsCount ?? participants.length.clamp(0, maxParticipants);

  String get participantCapacityLabel =>
      '$registeredParticipantCount/$maxParticipants';

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
    int? participantsCount,
    bool? isFull,
    bool? canJoin,
    bool? isRegistrationOpen,
    String? myRegistrationStatus,
  }) {
    return Tournament(
      id: id,
      loungeId: loungeId,
      loungeName: loungeName,
      title: title,
      gameName: gameName,
      gameEmoji: gameEmoji,
      startDate: startDate,
      endDate: endDate,
      registrationDeadline: registrationDeadline,
      coverImageUrl: coverImageUrl,
      prizeSummary: prizeSummary,
      entryFee: entryFee,
      matchRules: matchRules ?? this.matchRules,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      matches: matches ?? this.matches,
      maxParticipants: maxParticipants,
      participantsCount: participantsCount ?? this.participantsCount,
      isFull: isFull ?? this.isFull,
      canJoin: canJoin ?? this.canJoin,
      isRegistrationOpen: isRegistrationOpen ?? this.isRegistrationOpen,
      myRegistrationStatus: myRegistrationStatus ?? this.myRegistrationStatus,
      delayMinutes: delayMinutes,
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

/// User's tournament subscription row from Laravel registration APIs.
class TournamentSubscription {
  const TournamentSubscription({
    required this.id,
    required this.tournamentId,
    required this.tournamentTitle,
    required this.gameName,
    required this.status,
    required this.statusLabel,
    this.gameEmoji = '🎮',
    this.loungeId = '',
    this.loungeName = '',
    this.coverImageUrl,
    this.startDate,
    this.endDate,
    this.registrationDeadline,
    this.registeredAt,
    this.participantsCount = 0,
    this.maxParticipants = 8,
    this.tournamentStatus = '',
    this.tournamentStatusLabel = '',
    this.resultSummary = '—',
    this.completionStatus = '',
    this.canWithdraw = false,
    this.isFull = false,
    this.isRegistrationOpen = true,
  });

  final String id;
  final String tournamentId;
  final String tournamentTitle;
  final String gameName;
  final String gameEmoji;
  final String loungeId;
  final String loungeName;
  final String? coverImageUrl;
  final String status;
  final String statusLabel;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? registrationDeadline;
  final DateTime? registeredAt;
  final int participantsCount;
  final int maxParticipants;
  final String tournamentStatus;
  final String tournamentStatusLabel;
  final String resultSummary;
  final String completionStatus;
  final bool canWithdraw;
  final bool isFull;
  final bool isRegistrationOpen;

  bool get isActive => status == 'registered';

  String get capacityLabel => '$participantsCount/$maxParticipants';

  factory TournamentSubscription.fromApi(Map<String, dynamic> json) {
    return TournamentSubscription(
      id: json['id']?.toString() ?? '',
      tournamentId: json['tournament_id']?.toString() ?? '',
      tournamentTitle: json['tournament_title']?.toString() ?? '—',
      gameName: json['game_name']?.toString() ?? '',
      gameEmoji: json['game_emoji']?.toString() ?? '🎮',
      loungeId: json['lounge_id']?.toString() ?? '',
      loungeName: json['lounge_name']?.toString() ?? '',
      coverImageUrl: json['cover_image_url'] as String?,
      status: json['status']?.toString() ?? 'registered',
      statusLabel: json['status_label']?.toString() ?? 'مسجل',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      registrationDeadline: json['registration_deadline'] != null
          ? DateTime.tryParse(json['registration_deadline'] as String)
          : null,
      registeredAt: json['registered_at'] != null
          ? DateTime.tryParse(json['registered_at'] as String)
          : null,
      participantsCount: _parseInt(json['participants_count']) ?? 0,
      maxParticipants:
          _parseInt(json['max_participants']) ?? Tournament.kMaxCapacity,
      tournamentStatus: json['tournament_status']?.toString() ?? '',
      tournamentStatusLabel:
          json['tournament_status_label']?.toString() ?? '',
      resultSummary: json['result_summary']?.toString() ?? '—',
      completionStatus: json['completion_status']?.toString() ?? '',
      canWithdraw: json['can_withdraw'] == true,
      isFull: json['is_full'] == true,
      isRegistrationOpen: json['is_registration_open'] != false,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  TournamentSubscription copyWith({
    String? status,
    String? statusLabel,
    int? participantsCount,
    bool? canWithdraw,
    bool? isFull,
    bool? isRegistrationOpen,
  }) {
    return TournamentSubscription(
      id: id,
      tournamentId: tournamentId,
      tournamentTitle: tournamentTitle,
      gameName: gameName,
      gameEmoji: gameEmoji,
      loungeId: loungeId,
      loungeName: loungeName,
      coverImageUrl: coverImageUrl,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      startDate: startDate,
      endDate: endDate,
      registrationDeadline: registrationDeadline,
      registeredAt: registeredAt,
      participantsCount: participantsCount ?? this.participantsCount,
      maxParticipants: maxParticipants,
      tournamentStatus: tournamentStatus,
      tournamentStatusLabel: tournamentStatusLabel,
      resultSummary: resultSummary,
      completionStatus: completionStatus,
      canWithdraw: canWithdraw ?? this.canWithdraw,
      isFull: isFull ?? this.isFull,
      isRegistrationOpen: isRegistrationOpen ?? this.isRegistrationOpen,
    );
  }
}

/// Result of POST /tournaments/{id}/register.
class TournamentRegisterResult {
  const TournamentRegisterResult({
    required this.tournament,
    required this.participantId,
    required this.participantName,
  });

  final Tournament tournament;
  final String participantId;
  final String participantName;
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

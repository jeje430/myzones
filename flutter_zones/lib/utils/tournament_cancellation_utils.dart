import '../models/tournament.dart';

/// Tournament registrations can be cancelled only if >= 60 minutes before
/// the player's first match (or tournament start if no match scheduled yet).
bool canCancelTournamentRegistration({
  required Tournament tournament,
  required String playerId,
}) {
  final firstMatch = tournament.firstMatchForParticipant(playerId);
  final cutoffTime = firstMatch?.scheduledAt ?? tournament.startDate;
  final deadline = cutoffTime.subtract(const Duration(hours: 1));
  return DateTime.now().isBefore(deadline);
}

String tournamentCancellationBlockedMessage() =>
    'لا يمكن إلغاء الاشتراك خلال ساعة من أول مباراة';

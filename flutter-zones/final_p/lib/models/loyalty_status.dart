class LoyaltyStatus {
  const LoyaltyStatus({
    required this.pointsBalance,
    required this.minimumPointsRequired,
    required this.pointsPerCompletedSession,
    required this.estimatedSessionsRequired,
    required this.sessionsRemaining,
    required this.progressPoints,
    required this.progressMax,
    required this.progressPercent,
    required this.canRedeemReward,
    required this.rewardUnlocked,
  });

  factory LoyaltyStatus.fromJson(Map<String, dynamic> json) {
    return LoyaltyStatus(
      pointsBalance: (json['points_balance'] as num?)?.toInt() ?? 0,
      minimumPointsRequired: (json['minimum_points_required'] as num?)?.toInt() ?? 100,
      pointsPerCompletedSession: (json['points_per_completed_session'] as num?)?.toInt() ?? 10,
      estimatedSessionsRequired: (json['estimated_sessions_required'] as num?)?.toInt() ?? 10,
      sessionsRemaining: (json['sessions_remaining'] as num?)?.toInt() ?? 10,
      progressPoints: (json['progress_points'] as num?)?.toInt() ?? 0,
      progressMax: (json['progress_max'] as num?)?.toInt() ?? 100,
      progressPercent: (json['progress_percent'] as num?)?.toInt() ?? 0,
      canRedeemReward: json['can_redeem_reward'] == true,
      rewardUnlocked: json['reward_unlocked'] == true,
    );
  }

  final int pointsBalance;
  final int minimumPointsRequired;
  final int pointsPerCompletedSession;
  final int estimatedSessionsRequired;
  final int sessionsRemaining;
  final int progressPoints;
  final int progressMax;
  final int progressPercent;
  final bool canRedeemReward;
  final bool rewardUnlocked;

  double get progressValue {
    if (progressMax <= 0) return 0;
    return (progressPoints / progressMax).clamp(0.0, 1.0);
  }
}

class LoyaltyNotificationDto {
  const LoyaltyNotificationDto({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.createdAt,
    this.payload,
  });

  factory LoyaltyNotificationDto.fromJson(Map<String, dynamic> json) {
    return LoyaltyNotificationDto(
      id: json['id'] as int,
      type: (json['type'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      payload: json['payload'] is Map<String, dynamic>
          ? json['payload'] as Map<String, dynamic>
          : null,
    );
  }

  final int id;
  final String type;
  final String title;
  final String body;
  final DateTime? createdAt;
  final Map<String, dynamic>? payload;
}

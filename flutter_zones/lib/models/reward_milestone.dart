class RewardMilestone {
  const RewardMilestone({
    required this.id,
    required this.pointsRequired,
    required this.title,
    required this.couponPrefix,
  });

  final String id;
  final int pointsRequired;
  final String title;
  final String couponPrefix;
}

const kRewardMilestones = [
  RewardMilestone(
    id: 'discount-5',
    pointsRequired: 150,
    title: 'خصم 5 دنانير',
    couponPrefix: 'ZONEZ5',
  ),
  RewardMilestone(
    id: 'free-hour',
    pointsRequired: 300,
    title: 'ساعة لعب مجانية',
    couponPrefix: 'ZONEZFREE',
  ),
];

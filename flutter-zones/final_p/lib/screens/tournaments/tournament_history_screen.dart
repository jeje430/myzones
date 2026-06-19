import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../models/booking.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/circuit_background.dart';
import '../../widgets/tournament/tournament_participation_card.dart';

/// Player tournament archive — current and past participations (separate from lounge bookings).
class TournamentHistoryScreen extends StatefulWidget {
  const TournamentHistoryScreen({
    super.key,
    this.initialTabIndex = 0,
    this.showSuccessMessage = false,
  });

  final int initialTabIndex;
  final bool showSuccessMessage;

  @override
  State<TournamentHistoryScreen> createState() => _TournamentHistoryScreenState();
}

class _TournamentHistoryScreenState extends State<TournamentHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );

    if (widget.showSuccessMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تأكيد اشتراكك — يمكنك متابعة البطولة من المشاركات الحالية',
              style: ZonezTypography.body(),
              textAlign: TextAlign.center,
            ),
            backgroundColor: ZonezColors.neonCyan,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? ZonezColors.neonCyan : ZonezColors.lightAccent;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'سجل البطولات',
          style: ZonezTypography.title(size: 16, context: context),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          const CircuitBackground(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'مشاركاتك في البطولات',
                  style: ZonezTypography.display(size: 20, color: onSurface),
                ),
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                labelStyle:
                    ZonezTypography.caption(size: 13, weight: FontWeight.bold),
                unselectedLabelStyle: ZonezTypography.caption(size: 13),
                labelColor: accent,
                unselectedLabelColor: ZonezColors.textMuted,
                indicatorColor:
                    isDark ? ZonezColors.neonPurple : ZonezColors.lightPrimary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'المشاركات الحالية'),
                  Tab(text: 'المشاركات السابقة'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ParticipationList(
                      participations: appState.currentTournamentParticipations,
                      emptyMessage: 'لا توجد مشاركات حالية',
                      isActive: true,
                    ),
                    _ParticipationList(
                      participations: appState.pastTournamentParticipations,
                      emptyMessage: 'لا توجد مشاركات سابقة',
                      isActive: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ParticipationList extends StatelessWidget {
  const _ParticipationList({
    required this.participations,
    required this.emptyMessage,
    required this.isActive,
  });

  final List<Booking> participations;
  final String emptyMessage;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    if (participations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: ZonezTypography.body(size: 15, color: ZonezColors.textMuted),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: participations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => TournamentParticipationCard(
        booking: participations[index],
        isActive: isActive,
      ),
    );
  }
}

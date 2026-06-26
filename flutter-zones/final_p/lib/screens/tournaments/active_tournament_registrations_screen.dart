import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';
import '../../models/tournament.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/circuit_background.dart';
import '../../widgets/glass_container.dart';
import 'tournament_home_details_screen.dart';

class ActiveTournamentRegistrationsScreen extends StatefulWidget {
  const ActiveTournamentRegistrationsScreen({super.key});

  @override
  State<ActiveTournamentRegistrationsScreen> createState() =>
      _ActiveTournamentRegistrationsScreenState();
}

class _ActiveTournamentRegistrationsScreenState
    extends State<ActiveTournamentRegistrationsScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentProvider>().loadActiveRegistrations(forceRefresh: true);
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      context.read<TournamentProvider>().loadActiveRegistrations(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _confirmWithdraw(
    BuildContext context,
    TournamentSubscription registration,
  ) async {
    if (!registration.canWithdraw) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'انتهى موعد الانسحاب من هذه البطولة',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: ZonezColors.neonRed,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'إلغاء الاشتراك؟',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل تريد الانسحاب من «${registration.tournamentTitle}»؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('تراجع', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'إلغاء الاشتراك',
              style: GoogleFonts.cairo(
                color: ZonezColors.neonRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final provider = context.read<TournamentProvider>();
    final appState = context.read<AppStateProvider>();
    final ok = await provider.withdrawFromTournament(
      tournamentId: registration.tournamentId,
      appState: appState,
    );

    if (!context.mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إلغاء الاشتراك', style: GoogleFonts.cairo()),
        ),
      );
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!, style: GoogleFonts.cairo()),
          backgroundColor: ZonezColors.neonRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final registrations = provider.myActiveSubscriptions;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'سجل اشتراك بطولات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          const CircuitBackground(),
          if (provider.activeRegistrationsLoading && registrations.isEmpty)
            const Center(
              child: CircularProgressIndicator(color: ZonezColors.neonPurple),
            )
          else if (registrations.isEmpty)
            RefreshIndicator(
              color: ZonezColors.neonPurple,
              onRefresh: () =>
                  provider.loadActiveRegistrations(forceRefresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      'لا توجد مشاركات نشطة حالياً',
                      style: GoogleFonts.cairo(color: ZonezColors.textMuted),
                    ),
                  ),
                ],
              ),
            )
          else
            RefreshIndicator(
              color: ZonezColors.neonPurple,
              onRefresh: () =>
                  provider.loadActiveRegistrations(forceRefresh: true),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: registrations.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final registration = registrations[index];
                  final live = provider.getTournament(registration.tournamentId);
                  final capacity = live?.participantCapacityLabel ??
                      registration.capacityLabel;

                  return _ActiveRegistrationCard(
                    registration: registration,
                    capacityLabel: capacity,
                    onOpenDetails: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TournamentHomeDetailsScreen(
                            tournamentId: registration.tournamentId,
                          ),
                        ),
                      );
                    },
                    onWithdraw: () => _confirmWithdraw(context, registration),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ActiveRegistrationCard extends StatelessWidget {
  const _ActiveRegistrationCard({
    required this.registration,
    required this.capacityLabel,
    required this.onOpenDetails,
    required this.onWithdraw,
  });

  final TournamentSubscription registration;
  final String capacityLabel;
  final VoidCallback onOpenDetails;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderColor: ZonezColors.neonPurple.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpenDetails,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (registration.coverImageUrl != null &&
                      registration.coverImageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 7,
                        child: Image.network(
                          registration.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _coverFallback(),
                        ),
                      ),
                    )
                  else
                    _coverFallback(),
                  const SizedBox(height: 14),
                  Text(
                    registration.tournamentTitle,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (registration.loungeName.isNotEmpty)
                    Text(
                      registration.loungeName,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: ZonezColors.textMuted,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${registration.gameEmoji} ${registration.gameName}',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: ZonezColors.neonCyan,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    registration.statusLabel,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ZonezColors.neonPurple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Text(
                      capacityLabel,
                      key: ValueKey<String>(capacityLabel),
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: registration.isFull
                            ? ZonezColors.neonRed
                            : ZonezColors.neonCyan,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: registration.canWithdraw ? onWithdraw : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: ZonezColors.neonRed,
              disabledForegroundColor: ZonezColors.textMuted,
              side: BorderSide(
                color: registration.canWithdraw
                    ? ZonezColors.neonRed
                    : ZonezColors.borderMuted,
              ),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              registration.canWithdraw
                  ? 'إلغاء الاشتراك'
                  : 'الانسحاب غير متاح',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverFallback() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: ZonezColors.neonGradient,
      ),
      alignment: Alignment.center,
      child: Text(
        registration.gameEmoji,
        style: const TextStyle(fontSize: 42),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../models/lounge_model.dart';
import '../../models/tournament.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../utils/date_format_utils.dart';
import '../../widgets/circuit_background.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_gradient_button.dart';
import 'tournament_bracket_screen.dart';
import 'widgets/participants_row.dart';

/// Step 1 — tournament summary before registration confirmation.
class TournamentRegistrationSummaryScreen extends StatelessWidget {
  const TournamentRegistrationSummaryScreen({
    super.key,
    required this.lounge,
    required this.tournamentId,
  });

  final LoungeModel lounge;
  final String tournamentId;

  Future<void> _confirmRegistration(
    BuildContext context,
    Tournament tournament,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('هل أنت متأكد؟', style: ZonezTypography.title()),
        content: Text(
          'سيتم تأكيد اشتراكك في «${tournament.title}» '
          'برسوم ${tournament.entryFee.toStringAsFixed(0)} د.ل.',
          style: ZonezTypography.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('لا', style: ZonezTypography.body()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'نعم، تأكيد',
              style: ZonezTypography.body(color: ZonezColors.neonCyan),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final appState = context.read<AppStateProvider>();
    final provider = context.read<TournamentProvider>();

    final registration = await provider.registerForTournament(
      tournament: tournament,
      loungeName: lounge.name,
      playerName: appState.userName,
      appState: appState,
    );

    if (!context.mounted) return;

    if (registration != null) {
      final updated = provider.getTournament(tournament.id)!;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TournamentBracketScreen(
            lounge: lounge,
            tournament: updated,
            highlightPlayerId: registration.playerId,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.error ?? 'فشل تأكيد الاشتراك',
            style: ZonezTypography.body(),
            textAlign: TextAlign.center,
          ),
          backgroundColor: ZonezColors.neonRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final tournament = provider.getTournament(tournamentId);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).brightness == Brightness.dark
        ? ZonezColors.textMuted
        : ZonezColors.lightTextMuted;

    if (tournament == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('التسجيل', style: ZonezTypography.title(context: context)),
        ),
        body: Center(
          child: Text(
            'البطولة غير موجودة',
            style: ZonezTypography.body(color: muted),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ملخص البطولة',
          style: ZonezTypography.title(size: 16, context: context),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          const CircuitBackground(),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.paddingOf(context).top + kToolbarHeight + 12,
                    20,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlassContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              tournament.title,
                              style: ZonezTypography.display(
                                size: 20,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _InfoRow(
                              icon: Icons.sports_esports,
                              label:
                                  '${tournament.gameEmoji} ${tournament.gameName}',
                              onSurface: onSurface,
                            ),
                            _InfoRow(
                              icon: Icons.store,
                              label: lounge.name,
                              onSurface: onSurface,
                            ),
                            _InfoRow(
                              icon: Icons.calendar_today,
                              label: formatArabicDate(tournament.startDate),
                              onSurface: onSurface,
                            ),
                            _InfoRow(
                              icon: Icons.groups,
                              label: tournament.participantCapacityLabel,
                              onSurface: onSurface,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'قواعد المباراة',
                              style: ZonezTypography.title(
                                size: 16,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              tournament.matchRules,
                              style: ZonezTypography.body(
                                size: 13,
                                color: onSurface.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'الرسوم والجوائز',
                              style: ZonezTypography.title(
                                size: 16,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _FeePrizeRow(
                              icon: Icons.payments_outlined,
                              label: 'رسوم الاشتراك',
                              value:
                                  '${tournament.entryFee.toStringAsFixed(0)} د.ل',
                              color: ZonezColors.neonCyan,
                            ),
                            const SizedBox(height: 8),
                            _FeePrizeRow(
                              icon: Icons.emoji_events,
                              label: 'الجوائز',
                              value: tournament.prizeSummary,
                              color: ZonezColors.neonGold,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'المشاركون الحاليون',
                              style: ZonezTypography.title(
                                size: 16,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ParticipantsRow(
                              participants: tournament.participants,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.paddingOf(context).bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.95),
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? ZonezColors.borderMuted
                          : ZonezColors.lightBorder,
                    ),
                  ),
                ),
                child: provider.isRegistering
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: ZonezColors.neonPurple,
                        ),
                      )
                    : NeonGradientButton(
                        label: 'تأكيد الاشتراك',
                        icon: Icons.how_to_reg,
                        onPressed: () =>
                            _confirmRegistration(context, tournament),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.onSurface,
  });

  final IconData icon;
  final String label;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor =
        isDark ? ZonezColors.neonPurple : ZonezColors.lightPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: ZonezTypography.body(
                size: 13,
                color: onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeePrizeRow extends StatelessWidget {
  const _FeePrizeRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: ZonezTypography.body(size: 13),
          ),
        ),
        Text(
          value,
          style: ZonezTypography.title(size: 13, color: color),
        ),
      ],
    );
  }
}

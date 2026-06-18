import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../models/lounge_model.dart';
import '../../models/tournament.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../services/tournament_data_store.dart';
import '../../utils/date_format_utils.dart';
import '../../utils/tournament_cancellation_utils.dart';
import '../../widgets/circuit_background.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_gradient_button.dart';
import '../../widgets/tournament/tournament_receipt_sheet.dart';
import 'tournament_bracket_screen.dart';
import 'tournament_registration_summary_screen.dart';
import 'widgets/bracket_view.dart';
import 'widgets/participants_row.dart';

class TournamentDetailsScreen extends StatefulWidget {
  const TournamentDetailsScreen({
    super.key,
    required this.lounge,
    required this.tournamentId,
    this.showResults = false,
  });

  final LoungeModel lounge;
  final String tournamentId;
  final bool showResults;

  @override
  State<TournamentDetailsScreen> createState() =>
      _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends State<TournamentDetailsScreen> {
  Timer? _policyTimer;

  @override
  void initState() {
    super.initState();
    _policyTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _policyTimer?.cancel();
    super.dispose();
  }

  void _showReceipt(Tournament tournament) {
    final provider = context.read<TournamentProvider>();
    final registration = provider.activeRegistration(tournament.id);
    if (registration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يوجد إيصال — يجب الاشتراك أولاً',
            style: ZonezTypography.body(),
          ),
          backgroundColor: ZonezColors.neonRed,
        ),
      );
      return;
    }

    showTournamentReceiptSheet(
      context,
      registration: registration,
      gameName: tournament.gameName,
      formattedDate: formatArabicDate(tournament.startDate),
    );
  }

  void _openRegistrationSummary(Tournament tournament) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TournamentRegistrationSummaryScreen(
          lounge: widget.lounge,
          tournamentId: tournament.id,
        ),
      ),
    );
  }

  void _openBracketTree(Tournament tournament) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TournamentBracketScreen(
          lounge: widget.lounge,
          tournament: tournament,
          highlightPlayerId: TournamentDataStore.currentPlayerId,
        ),
      ),
    );
  }

  Future<void> _confirmCancel(Tournament tournament) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إلغاء الاشتراك', style: ZonezTypography.title()),
        content: Text(
          'هل أنت متأكد من إلغاء اشتراكك في هذه البطولة؟',
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
              'نعم، إلغاء',
              style: ZonezTypography.body(color: ZonezColors.neonRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<TournamentProvider>();
    final appState = context.read<AppStateProvider>();
    final registration = provider.activeRegistration(tournament.id);
    if (registration == null) return;

    final success = await provider.cancelRegistration(
      tournamentId: tournament.id,
      playerId: TournamentDataStore.currentPlayerId,
      appState: appState,
      registrationId: registration.id,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إلغاء الاشتراك',
            style: ZonezTypography.body(),
            textAlign: TextAlign.center,
          ),
        ),
      );
      setState(() {});
    }
  }

  Color _statusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.upcoming:
        return ZonezColors.neonCyan;
      case TournamentStatus.ongoing:
        return ZonezColors.neonPurple;
      case TournamentStatus.completed:
        return ZonezColors.neonGold;
      case TournamentStatus.cancelled:
        return ZonezColors.neonRed;
    }
  }

  Widget? _buildBottomBar(Tournament tournament, TournamentProvider provider) {
    if (tournament.isPast) return null;

    final joined = provider.isJoined(tournament.id);
    final canCancel = joined &&
        canCancelTournamentRegistration(
          tournament: tournament,
          playerId: TournamentDataStore.currentPlayerId,
        );
    final showBlocked = joined && !canCancel;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? ZonezColors.borderMuted
                : ZonezColors.lightBorder,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!joined) ...[
            provider.isRegistering
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(
                        color: ZonezColors.neonPurple,
                      ),
                    ),
                  )
                : NeonGradientButton(
                    label: 'اشترك الآن',
                    icon: Icons.person_add_alt_1,
                    onPressed: () => _openRegistrationSummary(tournament),
                  ),
          ] else ...[
            NeonGradientButton(
              label: 'عرض الإيصال',
              icon: Icons.receipt_long,
              onPressed: () => _showReceipt(tournament),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _openBracketTree(tournament),
              icon: const Icon(Icons.account_tree, size: 18),
              label: Text(
                'شجرة البطولة',
                style: ZonezTypography.body(size: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ZonezColors.neonPurple,
                side: const BorderSide(color: ZonezColors.neonPurple),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            if (canCancel) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => _confirmCancel(tournament),
                child: Text(
                  'إلغاء الاشتراك',
                  style: ZonezTypography.body(
                    size: 13,
                    color: ZonezColors.neonRed,
                  ),
                ),
              ),
            ],
            if (showBlocked) ...[
              const SizedBox(height: 8),
              Text(
                tournamentCancellationBlockedMessage(),
                textAlign: TextAlign.center,
                style: ZonezTypography.caption(
                  size: 11,
                  color: ZonezColors.neonRed,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final tournament = provider.getTournament(widget.tournamentId);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).brightness == Brightness.dark
        ? ZonezColors.textMuted
        : ZonezColors.lightTextMuted;

    if (tournament == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('البطولة', style: ZonezTypography.title(context: context)),
        ),
        body: Center(
          child: Text(
            'البطولة غير موجودة',
            style: ZonezTypography.body(color: muted),
          ),
        ),
      );
    }

    final bottomBar = _buildBottomBar(tournament, provider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.showResults ? 'نتائج البطولة' : 'البطولة',
          style: ZonezTypography.title(size: 16, context: context),
        ),
        backgroundColor: Colors.transparent,
      ),
      bottomNavigationBar: bottomBar,
      body: Stack(
        children: [
          const CircuitBackground(),
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + kToolbarHeight + 12,
              20,
              bottomBar != null ? 16 : 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tournament.title,
                              style: ZonezTypography.display(
                                size: 20,
                                color: onSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(tournament.status)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _statusColor(tournament.status)
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              tournamentStatusLabel(tournament.status),
                              style: ZonezTypography.caption(
                                size: 11,
                                weight: FontWeight.bold,
                                color: _statusColor(tournament.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.sports_esports,
                        label: '${tournament.gameEmoji} ${tournament.gameName}',
                        onSurface: onSurface,
                      ),
                      _DetailRow(
                        icon: Icons.store,
                        label: widget.lounge.name,
                        onSurface: onSurface,
                      ),
                      _DetailRow(
                        icon: Icons.calendar_today,
                        label: formatArabicDate(tournament.startDate),
                        onSurface: onSurface,
                      ),
                      _DetailRow(
                        icon: Icons.emoji_events,
                        label: tournament.prizeSummary,
                        color: ZonezColors.neonGold,
                        onSurface: onSurface,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'المشاركون',
                        style: ZonezTypography.title(size: 16, color: onSurface),
                      ),
                      const SizedBox(height: 12),
                      ParticipantsRow(participants: tournament.participants),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'شجرة المباريات',
                        style: ZonezTypography.title(size: 16, color: onSurface),
                      ),
                      const SizedBox(height: 12),
                      BracketView(matches: tournament.matches),
                    ],
                  ),
                ),
                if (bottomBar != null) const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.onSurface,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color onSurface;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = color ??
        (isDark ? ZonezColors.neonPurple : ZonezColors.lightPrimary);

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
                color: color ?? onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

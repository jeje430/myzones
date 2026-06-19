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
import '../../widgets/tournament/tournament_receipt_sheet.dart';

/// Legacy screen — registration now happens on [TournamentDetailsScreen].
/// Kept for backward-compatible deep links; redirects after registration.
class TournamentRegistrationScreen extends StatefulWidget {
  const TournamentRegistrationScreen({
    super.key,
    required this.lounge,
    required this.tournament,
  });

  final LoungeModel lounge;
  final Tournament tournament;

  @override
  State<TournamentRegistrationScreen> createState() =>
      _TournamentRegistrationScreenState();
}

class _TournamentRegistrationScreenState
    extends State<TournamentRegistrationScreen> {
  bool _registrationComplete = false;

  Future<void> _confirmRegistration() async {
    final appState = context.read<AppStateProvider>();
    final provider = context.read<TournamentProvider>();

    final registration = await provider.registerForTournament(
      tournament: widget.tournament,
      loungeName: widget.lounge.name,
      playerName: appState.userName,
      appState: appState,
    );

    if (!mounted) return;

    if (registration != null) {
      setState(() => _registrationComplete = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تأكيد اشتراكك بنجاح',
            style: ZonezTypography.body(),
            textAlign: TextAlign.center,
          ),
          backgroundColor: ZonezColors.neonCyan,
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

  void _showReceipt() {
    final provider = context.read<TournamentProvider>();
    final registration = provider.activeRegistration(widget.tournament.id);
    if (registration == null) return;

    showTournamentReceiptSheet(
      context,
      registration: registration,
      gameName: widget.tournament.gameName,
      formattedDate: formatArabicDate(widget.tournament.startDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final appState = context.watch<AppStateProvider>();
    final tournament = widget.tournament;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _registrationComplete ? 'تم التسجيل' : 'تأكيد الاشتراك',
          style: ZonezTypography.title(size: 16),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          const CircuitBackground(),
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + kToolbarHeight + 12,
              20,
              32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_registrationComplete) ...[
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? ZonezColors.neonCyan
                              : ZonezColors.lightPrimary,
                          size: 56,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'تم تأكيد اشتراكك!',
                          style: ZonezTypography.display(
                            size: 20,
                            color: onSurface,
                          ),
                        ),
                        Text(
                          tournament.title,
                          style: ZonezTypography.accent(
                            size: 13,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? ZonezColors.neonCyan
                                : ZonezColors.lightPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
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
                      const SizedBox(height: 8),
                      Text(
                        '${tournament.gameEmoji} ${tournament.gameName}',
                        style: ZonezTypography.accent(
                          size: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? ZonezColors.neonCyan
                              : ZonezColors.lightPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow('الصالة', widget.lounge.name),
                      _SummaryRow(
                        'التاريخ',
                        formatArabicDate(tournament.startDate),
                      ),
                      _SummaryRow('الجوائز', tournament.prizeSummary),
                      _SummaryRow('اللاعب', appState.userName),
                    ],
                  ),
                ),
                if (!_registrationComplete) ...[
                  const SizedBox(height: 28),
                  provider.isRegistering
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: ZonezColors.neonPurple,
                          ),
                        )
                      : NeonGradientButton(
                          label: 'تأكيد الاشتراك',
                          icon: Icons.check_circle_outline,
                          onPressed: _confirmRegistration,
                        ),
                ],
                if (_registrationComplete) ...[
                  const SizedBox(height: 24),
                  NeonGradientButton(
                    label: 'عرض الإيصال',
                    icon: Icons.receipt_long,
                    onPressed: _showReceipt,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).brightness == Brightness.dark
                          ? ZonezColors.neonCyan
                          : ZonezColors.lightPrimary,
                      side: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? ZonezColors.neonCyan
                            : ZonezColors.lightPrimary,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'العودة للبطولات',
                      style: ZonezTypography.title(size: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ZonezTypography.caption(size: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: ZonezTypography.title(size: 14, color: onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

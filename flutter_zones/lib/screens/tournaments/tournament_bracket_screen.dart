import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../models/lounge_model.dart';
import '../../models/tournament.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/circuit_background.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_gradient_button.dart';
import 'widgets/bracket_view.dart';

/// Step 3 — full-screen tournament bracket tree after successful registration.
class TournamentBracketScreen extends StatelessWidget {
  const TournamentBracketScreen({
    super.key,
    required this.lounge,
    required this.tournament,
    this.highlightPlayerId,
  });

  final LoungeModel lounge;
  final Tournament tournament;
  final String? highlightPlayerId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final live = provider.getTournament(tournament.id) ?? tournament;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'شجرة البطولة',
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
                            Row(
                              children: [
                                const Icon(
                                  Icons.account_tree,
                                  color: ZonezColors.neonPurple,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    live.title,
                                    style: ZonezTypography.title(
                                      size: 17,
                                      color: onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${live.gameEmoji} ${live.gameName} · ${lounge.name}',
                              style: ZonezTypography.caption(
                                size: 12,
                                color: ZonezColors.textMuted,
                              ),
                            ),
                            if (highlightPlayerId != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: ZonezColors.neonCyan
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: ZonezColors.neonCyan
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: ZonezColors.neonCyan,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'تم تسجيلك بنجاح — موقعك في الشجرة أدناه',
                                        style: ZonezTypography.body(
                                          size: 12,
                                          color: ZonezColors.neonCyan,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassContainer(
                        padding: const EdgeInsets.all(12),
                        child: BracketView(matches: live.matches),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  MediaQuery.paddingOf(context).bottom + 16,
                ),
                child: NeonGradientButton(
                  label: 'العودة للبطولة',
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

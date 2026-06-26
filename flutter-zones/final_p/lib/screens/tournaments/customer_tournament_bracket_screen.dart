import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../models/tournament.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/circuit_background.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_gradient_button.dart';
import 'widgets/bracket_view.dart';

class CustomerTournamentBracketScreen extends StatefulWidget {
  const CustomerTournamentBracketScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentTitle,
    this.loungeName = '',
    this.gameName = '',
    this.gameEmoji = '🎮',
  });

  final String tournamentId;
  final String tournamentTitle;
  final String loungeName;
  final String gameName;
  final String gameEmoji;

  @override
  State<CustomerTournamentBracketScreen> createState() =>
      _CustomerTournamentBracketScreenState();
}

class _CustomerTournamentBracketScreenState
    extends State<CustomerTournamentBracketScreen> {
  Tournament? _tournament;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final provider = context.read<TournamentProvider>();
    final tournament = await provider.fetchTournamentBracket(widget.tournamentId);

    if (!mounted) return;

    setState(() {
      _loading = false;
      if (tournament == null) {
        _error = provider.error ?? 'تعذر تحميل شجرة البطولة';
      } else {
        _tournament = tournament;
      }
    });
  }

  String? get _championName {
    final tournament = _tournament;
    if (tournament == null) return null;

    final finalMatch = tournament.matches
        .where((m) => m.round == BracketRound.finalRound && m.isCompleted)
        .toList();
    if (finalMatch.isEmpty) return null;

    final winnerId = finalMatch.first.winnerId;
    if (winnerId == null) return null;

    for (final match in tournament.matches) {
      if (match.player1?.id == winnerId) return match.player1?.name;
      if (match.player2?.id == winnerId) return match.player2?.name;
    }
    return null;
  }

  Widget _buildBracketBody({
    required Tournament live,
    required Color onSurface,
    required String? champion,
  }) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: ZonezColors.neonPurple,
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                                live.title.isNotEmpty
                                    ? live.title
                                    : widget.tournamentTitle,
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
                          '${live.gameEmoji.isNotEmpty ? live.gameEmoji : widget.gameEmoji} '
                          '${live.gameName.isNotEmpty ? live.gameName : widget.gameName}'
                          '${widget.loungeName.isNotEmpty ? ' · ${widget.loungeName}' : ''}',
                          style: ZonezTypography.caption(
                            size: 12,
                            color: ZonezColors.textMuted,
                          ),
                        ),
                        if (champion != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: ZonezColors.neonCyan.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: ZonezColors.neonCyan.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.emoji_events,
                                  color: ZonezColors.neonCyan,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'البطل: $champion',
                                    style: ZonezTypography.body(
                                      size: 13,
                                      color: ZonezColors.neonCyan,
                                      weight: FontWeight.bold,
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
                    child: live.matches.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'لم تُنشأ مباريات هذه البطولة بعد',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                color: ZonezColors.textMuted,
                              ),
                            ),
                          )
                        : BracketView(matches: live.matches),
                  ),
                ],
              ),
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
            label: 'رجوع',
            icon: Icons.arrow_back,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final live = provider.getTournament(widget.tournamentId) ?? _tournament;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final champion = _championName;

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
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: ZonezColors.neonPurple),
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(color: ZonezColors.neonRed),
                    ),
                    const SizedBox(height: 16),
                    NeonGradientButton(
                      label: 'إعادة المحاولة',
                      icon: Icons.refresh,
                      onPressed: _load,
                    ),
                  ],
                ),
              ),
            )
          else if (live != null)
            _buildBracketBody(
              live: live,
              onSurface: onSurface,
              champion: champion,
            ),
        ],
      ),
    );
  }
}

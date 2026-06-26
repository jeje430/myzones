import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../models/tournament.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/circuit_background.dart';
import '../home/widgets/tournaments_carousel.dart';
import 'tournament_home_details_screen.dart';

/// Flat tournament catalog — no hall nesting.
class TournamentBrowseScreen extends StatefulWidget {
  const TournamentBrowseScreen({super.key});

  @override
  State<TournamentBrowseScreen> createState() => _TournamentBrowseScreenState();
}

class _TournamentBrowseScreenState extends State<TournamentBrowseScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final next = _searchController.text.trim();
      if (next == _query) return;
      setState(() => _query = next);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentProvider>().loadTournaments(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Tournament> _filter(List<Tournament> tournaments) {
    if (_query.isEmpty) return tournaments;
    final q = _query.toLowerCase();
    return tournaments.where((t) {
      return t.title.toLowerCase().contains(q) ||
          t.gameName.toLowerCase().contains(q) ||
          t.loungeName.toLowerCase().contains(q);
    }).toList();
  }

  void _openDetails(Tournament tournament) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TournamentHomeDetailsScreen(tournamentId: tournament.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final tournaments = _filter(provider.allCurrentTournaments());
    final muted = Theme.of(context).brightness == Brightness.dark
        ? ZonezColors.textMuted
        : ZonezColors.lightTextMuted;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'بطولات الحالية',
          style: ZonezTypography.title(context: context),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          const CircuitBackground(),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
                  16,
                  0,
                ),
                child: TextField(
                  controller: _searchController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن بطولة، لعبة، أو صالة...',
                    prefixIcon: Icon(Icons.search, color: muted),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: muted),
                            onPressed: _searchController.clear,
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: provider.isLoading && tournaments.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: ZonezColors.neonPurple,
                        ),
                      )
                    : tournaments.isEmpty
                        ? Center(
                            child: Text(
                              _query.isEmpty
                                  ? 'لا توجد بطولات متاحة حالياً'
                                  : 'لا توجد نتائج مطابقة',
                              style: GoogleFonts.cairo(color: muted),
                            ),
                          )
                        : RefreshIndicator(
                            color: ZonezColors.neonPurple,
                            onRefresh: () =>
                                provider.loadTournaments(forceRefresh: true),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                              itemCount: tournaments.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final tournament = tournaments[index];
                                final live =
                                    provider.getTournament(tournament.id) ??
                                        tournament;
                                return SizedBox(
                                  height: 240,
                                  child: TournamentCard(
                                    tournament: live,
                                    onTap: () => _openDetails(live),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

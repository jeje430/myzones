import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../models/lounge_model.dart';
import '../../providers/lounge_ratings_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/circuit_background.dart';
import 'lounge_tournaments_screen.dart';
import 'widgets/lounge_station_card.dart';

class TournamentStationsScreen extends StatefulWidget {
  const TournamentStationsScreen({super.key});

  @override
  State<TournamentStationsScreen> createState() =>
      _TournamentStationsScreenState();
}

class _TournamentStationsScreenState extends State<TournamentStationsScreen> {
  final _searchController = TextEditingController();
  String _gameFilter = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query == _gameFilter) return;
    setState(() => _gameFilter = query);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _openGameFilterSheet(TournamentProvider tournamentProvider) {
    final gameNames = tournamentProvider.allGameNames();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تصفية حسب اللعبة',
                style: ZonezTypography.title(context: ctx),
              ),
              const SizedBox(height: 16),
              ...gameNames.map(
                (game) => ListTile(
                  title: Text(game, style: ZonezTypography.body(context: ctx)),
                  trailing: _gameFilter == game
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(ctx).colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    _searchController.text = game;
                    Navigator.pop(ctx);
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  Navigator.pop(ctx);
                },
                child: Text(
                  'مسح التصفية',
                  style: ZonezTypography.body(
                    color: Theme.of(ctx).colorScheme.primary,
                    context: ctx,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openLoungeTournaments(LoungeModel lounge) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoungeTournamentsScreen(lounge: lounge),
      ),
    );
  }

  List<LoungeModel> _filterLounges(
    List<String> loungeIds,
    LoungeRatingsProvider ratingsProvider,
    TournamentProvider tournamentProvider,
  ) {
    return loungeIds
        .map(ratingsProvider.loungeById)
        .whereType<LoungeModel>()
        .where(
          (lounge) => tournamentProvider.loungeMatchesGameFilter(
            lounge.id,
            _gameFilter,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final ratingsProvider = context.watch<LoungeRatingsProvider>();
    final tournamentProvider = context.watch<TournamentProvider>();
    final loungeIds = tournamentProvider.loungeIdsWithTournaments();
    final lounges = _filterLounges(
      loungeIds,
      ratingsProvider,
      tournamentProvider,
    );
    final muted = Theme.of(context).brightness == Brightness.dark
        ? ZonezColors.textMuted
        : ZonezColors.lightTextMuted;
    final primary = Theme.of(context).colorScheme.primary;
    final hasActiveFilter = _gameFilter.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('البطولات', style: ZonezTypography.title(context: context)),
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
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'ابحث باسم اللعبة...',
                          prefixIcon: Icon(Icons.sports_esports, color: muted),
                          suffixIcon: hasActiveFilter
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: muted),
                                  onPressed: _searchController.clear,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: hasActiveFilter
                              ? primary
                              : primary.withValues(alpha: 0.4),
                        ),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? ZonezColors.inputBg
                            : ZonezColors.lightSurfaceAlt,
                      ),
                      child: IconButton(
                        icon: Icon(
                          hasActiveFilter
                              ? Icons.filter_list_off
                              : Icons.filter_list,
                          color: hasActiveFilter ? primary : muted,
                        ),
                        onPressed: () =>
                            _openGameFilterSheet(tournamentProvider),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: lounges.isEmpty
                    ? Center(
                        child: Text(
                          hasActiveFilter
                              ? 'لا توجد صالات تستضيف بطولات لهذه اللعبة'
                              : 'لا توجد صالات تستضيف بطولات حالياً',
                          style: ZonezTypography.body(
                            color: muted,
                            context: context,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: lounges.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final lounge = lounges[index];
                          return LoungeStationCard(
                            lounge: lounge,
                            onViewTournaments: () =>
                                _openLoungeTournaments(lounge),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

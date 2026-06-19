import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/zonez_colors.dart';
import '../../../core/theme/zonez_typography.dart';
import '../../../models/lounge_model.dart';
import '../../../models/tournament.dart';
import '../../../providers/tournament_provider.dart';
import '../../../utils/date_format_utils.dart';
import '../../../widgets/circuit_background.dart';
import 'tournament_details_screen.dart';
import 'widgets/tournament_list_card.dart';

class LoungeTournamentsScreen extends StatefulWidget {
  const LoungeTournamentsScreen({super.key, required this.lounge});

  final LoungeModel lounge;

  @override
  State<LoungeTournamentsScreen> createState() =>
      _LoungeTournamentsScreenState();
}

class _LoungeTournamentsScreenState extends State<LoungeTournamentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _gameSearchController = TextEditingController();
  String _gameFilter = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _gameSearchController.addListener(_onGameSearchChanged);
  }

  void _onGameSearchChanged() {
    final query = _gameSearchController.text.trim();
    if (query == _gameFilter) return;
    setState(() => _gameFilter = query);
  }

  @override
  void dispose() {
    _gameSearchController.removeListener(_onGameSearchChanged);
    _gameSearchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _openDetails(Tournament tournament, {required bool showResults}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TournamentDetailsScreen(
          lounge: widget.lounge,
          tournamentId: tournament.id,
          showResults: showResults,
        ),
      ),
    );
  }

  List<Tournament> _filterByGameName(List<Tournament> tournaments) {
    if (_gameFilter.isEmpty) return tournaments;
    final q = _gameFilter.toLowerCase();
    return tournaments
        .where((t) => t.gameName.toLowerCase().contains(q))
        .toList();
  }

  void _openGameFilterSheet(List<Tournament> allTournaments) {
    final gameNames = allTournaments
        .map((t) => t.gameName)
        .toSet()
        .toList()
      ..sort();

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
                    _gameSearchController.text = game;
                    Navigator.pop(ctx);
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _gameSearchController.clear();
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final current = _filterByGameName(
      provider.currentTournamentsForLounge(widget.lounge.id),
    );
    final past = _filterByGameName(
      provider.pastTournamentsForLounge(widget.lounge.id),
    );
    final allTournaments = [
      ...provider.currentTournamentsForLounge(widget.lounge.id),
      ...provider.pastTournamentsForLounge(widget.lounge.id),
    ];
    final muted = Theme.of(context).brightness == Brightness.dark
        ? ZonezColors.textMuted
        : ZonezColors.lightTextMuted;
    final primary = Theme.of(context).colorScheme.primary;
    final hasFilter = _gameFilter.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.lounge.name,
          style: ZonezTypography.title(size: 16, context: context),
        ),
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          labelStyle:
              ZonezTypography.caption(size: 13, weight: FontWeight.bold, context: context),
          unselectedLabelStyle: ZonezTypography.caption(size: 13, context: context),
          tabs: const [
            Tab(text: 'البطولات الحالية'),
            Tab(text: 'البطولات السابقة'),
          ],
        ),
      ),
      body: Stack(
        children: [
          const CircuitBackground(),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.paddingOf(context).top + kToolbarHeight + 52,
                  16,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _gameSearchController,
                        style: ZonezTypography.body(context: context),
                        decoration: InputDecoration(
                          hintText: 'ابحث باسم اللعبة...',
                          prefixIcon: Icon(Icons.sports_esports, color: muted),
                          suffixIcon: hasFilter
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: muted),
                                  onPressed: _gameSearchController.clear,
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
                          color: hasFilter
                              ? primary
                              : primary.withValues(alpha: 0.35),
                        ),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? ZonezColors.inputBg
                            : ZonezColors.lightSurfaceAlt,
                      ),
                      child: IconButton(
                        icon: Icon(
                          hasFilter ? Icons.filter_list_off : Icons.filter_list,
                          color: hasFilter ? primary : muted,
                        ),
                        onPressed: () => _openGameFilterSheet(allTournaments),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _TournamentTabList(
                      tournaments: current,
                      isPast: false,
                      emptyMessage: hasFilter
                          ? 'لا توجد بطولات مطابقة لهذه اللعبة'
                          : 'لا توجد بطولات حالية في هذه الصالة',
                      onTap: (t) => _openDetails(t, showResults: false),
                    ),
                    _TournamentTabList(
                      tournaments: past,
                      isPast: true,
                      emptyMessage: hasFilter
                          ? 'لا توجد بطولات مطابقة لهذه اللعبة'
                          : 'لا توجد بطولات سابقة',
                      onTap: (t) => _openDetails(t, showResults: true),
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

class _TournamentTabList extends StatelessWidget {
  const _TournamentTabList({
    required this.tournaments,
    required this.isPast,
    required this.emptyMessage,
    required this.onTap,
  });

  final List<Tournament> tournaments;
  final bool isPast;
  final String emptyMessage;
  final void Function(Tournament tournament) onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? ZonezColors.textMuted
        : ZonezColors.lightTextMuted;

    if (tournaments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: ZonezTypography.body(color: muted, context: context),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: tournaments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tournament = tournaments[index];
        final action = isPast
            ? TournamentAction.viewResults
            : TournamentAction.viewDetails;

        return TournamentListCard(
          tournament: tournament,
          action: action,
          formattedDate: formatArabicDate(tournament.startDate),
          onAction: () => onTap(tournament),
        );
      },
    );
  }
}

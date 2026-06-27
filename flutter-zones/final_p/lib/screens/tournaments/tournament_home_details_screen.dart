import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';
import '../../data/repositories/tournament_catalog_repository.dart';
import '../../models/tournament.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/app_state_provider.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/circuit_background.dart';
import '../../widgets/neon_gradient_button.dart';
import 'customer_tournament_bracket_screen.dart';

class TournamentHomeDetailsScreen extends StatefulWidget {
  const TournamentHomeDetailsScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  State<TournamentHomeDetailsScreen> createState() =>
      _TournamentHomeDetailsScreenState();
}

class _TournamentHomeDetailsScreenState extends State<TournamentHomeDetailsScreen> {
  Tournament? _tournament;
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Tournament? _liveTournament(TournamentProvider provider) {
    return provider.getTournament(widget.tournamentId) ?? _tournament;
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final tournament =
          await TournamentCatalogRepository.instance.fetchById(widget.tournamentId);
      if (!mounted) return;
      if (tournament == null) {
        setState(() {
          _error = 'البطولة غير موجودة';
          _loading = false;
        });
        return;
      }
      final provider = context.read<TournamentProvider>();
      provider.mergeTournament(tournament);
      TournamentCatalogRepository.instance.invalidateCache();
      await provider.loadTournaments(forceRefresh: true);
      if (!mounted) return;
      setState(() {
        _tournament = provider.getTournament(widget.tournamentId) ?? tournament;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _join() async {
    final auth = context.read<AuthBloc>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يجب تسجيل الدخول أولاً للاشتراك في البطولة',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: ZonezColors.neonRed,
        ),
      );
      Navigator.pushNamed(context, AppRoutes.login);
      return;
    }

    final tournament = _liveTournament(context.read<TournamentProvider>());
    if (tournament == null) return;

    final provider = context.read<TournamentProvider>();
    final appState = context.read<AppStateProvider>();
    final playerName = auth.currentUser?.name.trim().isNotEmpty == true
        ? auth.currentUser!.name
        : appState.userName;

    final result = await provider.registerForTournament(
      tournament: tournament,
      loungeName: tournament.loungeName,
      playerName: playerName,
      appState: appState,
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _tournament = provider.getTournament(widget.tournamentId) ?? tournament;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم الاشتراك في البطولة بنجاح', style: GoogleFonts.cairo()),
          backgroundColor: ZonezColors.neonPurple,
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

  void _openTournamentTree(Tournament tournament) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerTournamentBracketScreen(
          tournamentId: tournament.id,
          tournamentTitle: tournament.title,
          loungeName: tournament.loungeName,
          gameName: tournament.gameName,
          gameEmoji: tournament.gameEmoji,
        ),
      ),
    );
  }

  Future<void> _withdraw() async {
    final tournament = _liveTournament(context.read<TournamentProvider>());
    if (tournament == null) return;

    final provider = context.read<TournamentProvider>();
    final appState = context.read<AppStateProvider>();

    final ok = await provider.cancelSubscription(
      tournamentId: tournament.id,
      appState: appState,
    );

    if (!mounted) return;

    if (ok) {
      setState(() {
        _tournament = provider.getTournament(widget.tournamentId) ?? tournament;
      });
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

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final tournament = _liveTournament(provider);
    final muted = Theme.of(context).brightness == Brightness.dark
        ? ZonezColors.textMuted
        : ZonezColors.lightTextMuted;

    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل البطولة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          const CircuitBackground(),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: ZonezColors.neonPurple))
          else if (_error != null)
            Center(child: Text(_error!, style: GoogleFonts.cairo(color: ZonezColors.neonRed)))
          else if (tournament != null)
            _buildContent(tournament, muted),
        ],
      ),
      bottomNavigationBar: tournament == null
          ? null
          : _buildBottomBar(tournament, provider),
    );
  }

  Widget _buildContent(Tournament tournament, Color muted) {
    final rules = tournament.matchRules.split('\n').where((l) => l.trim().isNotEmpty);
    final deadline = tournament.registrationDeadline;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tournament.coverImageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                tournament.coverImageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: ZonezColors.neonPurple.withValues(alpha: 0.12),
              ),
              child: Text(tournament.gameEmoji, style: const TextStyle(fontSize: 56)),
            ),
          const SizedBox(height: 16),
          Text(
            tournament.title,
            style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            tournament.gameName,
            style: GoogleFonts.cairo(color: ZonezColors.neonCyan, fontSize: 14),
          ),
          if (tournament.loungeName.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              tournament.loungeName,
              style: GoogleFonts.cairo(color: muted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'تفاصيل البطولة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          if (tournament.prizeSummary.trim().isNotEmpty)
            _infoRow('الجائزة', tournament.prizeSummary),
          _infoRow('عدد المشاركين', tournament.participantCapacityLabel),
          _infoRow('تاريخ بداية البطولة', _formatDate(tournament.startDate)),
          _infoRow('تاريخ نهاية البطولة', _formatDate(tournament.endDate)),
          _infoRow(
            'تاريخ انتهاء مهلة المشاركة',
            _formatDate(deadline),
          ),
          _infoRow('مدة التأخير المسموحة', '${tournament.delayMinutes} دقيقة'),
          const SizedBox(height: 16),
          Text(
            'قواعد البطولة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...rules.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                line.trim(),
                style: GoogleFonts.cairo(fontSize: 13, color: muted, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool multiline = false}) {
    if (multiline) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.cairo(fontSize: 13, color: ZonezColors.textMuted)),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: GoogleFonts.cairo(fontSize: 13, color: ZonezColors.textMuted)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String _blockedJoinLabel(Tournament tournament) {
    if (tournament.isFull) return 'البطولة مكتملة العدد';
    if (!tournament.isRegistrationOpen) {
      final deadline = _formatDate(tournament.registrationDeadline);
      return deadline != '—'
          ? 'انتهت مهلة الاشتراك ($deadline)'
          : 'انتهت مهلة الاشتراك';
    }
    if (!tournament.canJoin) return 'الاشتراك غير متاح حالياً';
    return 'الاشتراك غير متاح';
  }

  Widget _buildBottomBar(Tournament tournament, TournamentProvider provider) {
    final joined = provider.isJoined(tournament.id) || tournament.isJoined;
    final canWithdraw = joined && tournament.isRegistrationOpen && !tournament.isPast;
    final isFull = tournament.isFull;
    final canJoin = !joined &&
        !tournament.isPast &&
        tournament.canJoin &&
        !isFull &&
        tournament.isRegistrationOpen;
    final capacityLabel = tournament.participantCapacityLabel;
    final showTournamentTree = tournament.isSubscriptionClosed;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.paddingOf(context).bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: ZonezColors.borderMuted.withValues(alpha: 0.4))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!tournament.isPast) ...[
            if (canJoin)
              NeonGradientButton(
                label: provider.isRegistering ? 'جاري الاشتراك...' : 'اشترك في البطولة',
                icon: Icons.emoji_events,
                onPressed: provider.isRegistering ? null : _join,
              )
            else if (joined && canWithdraw)
              OutlinedButton(
                onPressed: _withdraw,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ZonezColors.neonRed,
                  side: const BorderSide(color: ZonezColors.neonRed),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text('إلغاء الاشتراك', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              )
            else if (joined)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ZonezColors.neonPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ZonezColors.neonPurple.withValues(alpha: 0.35)),
                ),
                child: Text(
                  'أنت مشترك في البطولة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: ZonezColors.neonPurple),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ZonezColors.neonRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ZonezColors.neonRed.withValues(alpha: 0.35)),
                ),
                child: Text(
                  _blockedJoinLabel(tournament),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: ZonezColors.neonRed),
                ),
              ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Text(
                capacityLabel,
                key: ValueKey<String>(capacityLabel),
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isFull ? ZonezColors.neonRed : ZonezColors.neonCyan,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (showTournamentTree) ...[
            OutlinedButton.icon(
              onPressed: () => _openTournamentTree(tournament),
              icon: const Icon(Icons.account_tree, size: 20),
              label: Text('شجرة البطولة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: ZonezColors.neonCyan,
                side: const BorderSide(color: ZonezColors.neonCyan),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

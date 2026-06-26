import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';
import '../../models/tournament.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/circuit_background.dart';
import '../../widgets/glass_container.dart';
import 'customer_tournament_bracket_screen.dart';

class TournamentParticipationRecordsScreen extends StatefulWidget {
  const TournamentParticipationRecordsScreen({super.key});

  @override
  State<TournamentParticipationRecordsScreen> createState() =>
      _TournamentParticipationRecordsScreenState();
}

class _TournamentParticipationRecordsScreenState
    extends State<TournamentParticipationRecordsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<TournamentProvider>()
          .loadParticipationHistory(forceRefresh: true);
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final records = provider.participationHistory;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'سجل مشاركات البطولة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          const CircuitBackground(),
          if (provider.participationHistoryLoading && records.isEmpty)
            const Center(
              child: CircularProgressIndicator(color: ZonezColors.neonPurple),
            )
          else if (records.isEmpty)
            RefreshIndicator(
              color: ZonezColors.neonPurple,
              onRefresh: () =>
                  provider.loadParticipationHistory(forceRefresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'لا توجد بطولات منتهية في سجل مشاركاتك بعد.\n'
                        'ستظهر هنا بعد انتهاء البطولات التي شاركت فيها.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(color: ZonezColors.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            RefreshIndicator(
              color: ZonezColors.neonPurple,
              onRefresh: () =>
                  provider.loadParticipationHistory(forceRefresh: true),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: records.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final record = records[index];
                  return _ParticipationHistoryCard(
                    record: record,
                    startLabel: _formatDate(record.startDate),
                    endLabel: _formatDate(record.endDate),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerTournamentBracketScreen(
                            tournamentId: record.tournamentId,
                            tournamentTitle: record.tournamentTitle,
                            loungeName: record.loungeName,
                            gameName: record.gameName,
                            gameEmoji: record.gameEmoji,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ParticipationHistoryCard extends StatelessWidget {
  const _ParticipationHistoryCard({
    required this.record,
    required this.startLabel,
    required this.endLabel,
    required this.onTap,
  });

  final TournamentSubscription record;
  final String startLabel;
  final String endLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          borderColor: ZonezColors.neonPurple.withValues(alpha: 0.25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: ZonezColors.neonGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      record.gameEmoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.tournamentTitle,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: onSurface,
                          ),
                        ),
                        if (record.loungeName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            record.loungeName,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: ZonezColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.account_tree_outlined,
                    color: ZonezColors.neonCyan.withValues(alpha: 0.85),
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _dateRow(Icons.calendar_today_outlined, 'تاريخ البداية', startLabel),
              const SizedBox(height: 6),
              _dateRow(Icons.event_available_outlined, 'تاريخ النهاية', endLabel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ZonezColors.neonPurple),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: ZonezColors.textMuted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ZonezColors.neonCyan,
            ),
          ),
        ),
      ],
    );
  }
}

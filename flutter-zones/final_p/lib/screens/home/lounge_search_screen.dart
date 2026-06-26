import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';
import '../../models/lounge_model.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/lounge_ratings_provider.dart';
import '../../utils/lounge_filter_utils.dart';
import '../lounge/lounge_details_screen.dart';
import 'widgets/device_filter_sheet.dart';
import 'widgets/zonez_lounge_card.dart';

/// Search & filter tab embedded in the main home shell (bottom nav stays visible).
class LoungeSearchScreen extends StatefulWidget {
  const LoungeSearchScreen({super.key});

  @override
  State<LoungeSearchScreen> createState() => _LoungeSearchScreenState();
}

class _LoungeSearchScreenState extends State<LoungeSearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  LoungeDeviceFilter _deviceFilter = LoungeDeviceFilter();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query == _searchQuery) return;
    setState(() => _searchQuery = query);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<LoungeModel> _filteredLounges(List<LoungeModel> lounges) {
    return filterLounges(
      lounges: lounges,
      nameQuery: _searchQuery,
      deviceFilter: _deviceFilter,
    );
  }

  void _toggleDeviceFilter(DeviceType type) {
    setState(() => _deviceFilter = _deviceFilter.toggle(type));
  }

  void _openDeviceFilterSheet(List<LoungeModel> allLounges) {
    showDeviceFilterSheet(
      context: context,
      allLounges: allLounges,
      currentFilter: _deviceFilter,
      onApply: (filter) => setState(() => _deviceFilter = filter),
    );
  }

  void _openLounge(String loungeId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoungeDetailsScreen(loungeId: loungeId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final allLounges = context.watch<LoungeRatingsProvider>().lounges;
    final lounges = _filteredLounges(allLounges);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final muted = isDark ? ZonezColors.textMuted : ZonezColors.lightTextMuted;
    final primary = isDark ? ZonezColors.neonPurple : ZonezColors.lightPrimary;
    final hasFilters = _deviceFilter.hasActiveFilters || _searchQuery.isNotEmpty;
    final catalogDevices = aggregateAvailableDeviceTypes(allLounges);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'بحث وتصفية الصالات',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: onSurface,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
              _FilterButton(
                activeCount: _deviceFilter.activeTypes.length,
                primary: primary,
                isDark: isDark,
                onTap: () => _openDeviceFilterSheet(allLounges),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.cairo(color: onSurface),
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: 'ابحث باسم الصالة...',
              hintStyle: GoogleFonts.cairo(color: muted),
              prefixIcon: Icon(Icons.search, color: muted),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: muted),
                      onPressed: _searchController.clear,
                    )
                  : null,
            ),
          ),
        ),
        if (catalogDevices.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final type in catalogDevices) ...[
                  _DeviceChip(
                    label: deviceFilterMeta(type, allLounges).label,
                    icon: deviceFilterMeta(type, allLounges).icon,
                    selected: _deviceFilter.isActive(type),
                    onTap: () => _toggleDeviceFilter(type),
                    primary: primary,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
        if (hasFilters) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _deviceFilter = _deviceFilter.clear());
                },
                child: Text(
                  'مسح التصفية',
                  style: GoogleFonts.cairo(color: primary, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: lounges.isEmpty
              ? Center(
                  child: Text(
                    hasFilters
                        ? 'لا توجد صالات مطابقة'
                        : 'لا توجد صالات متاحة',
                    style: GoogleFonts.cairo(color: muted, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: lounges.length,
                  itemBuilder: (context, index) {
                    final l = lounges[index];
                    return ZonezLoungeCard(
                      lounge: l,
                      isFavorite: appState.isFavorite(l.name),
                      onFavoriteTap: () => appState.toggleFavorite(l.name),
                      onOpenDetails: () => _openLounge(l.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.activeCount,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  final int activeCount;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasActive = activeCount > 0;

    return Material(
      color: hasActive
          ? primary.withValues(alpha: 0.15)
          : (isDark ? ZonezColors.inputBg : ZonezColors.lightSurfaceAlt),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasActive ? primary : primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune, size: 18, color: primary),
              const SizedBox(width: 6),
              Text(
                'تصفية',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              if (hasActive) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$activeCount',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceChip extends StatelessWidget {
  const _DeviceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.primary,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: selected
              ? (isDark
                  ? ZonezColors.neonGradient
                  : ZonezColors.lightAccentGradient)
              : null,
          color: selected
              ? null
              : (isDark ? ZonezColors.inputBg : ZonezColors.lightSurfaceAlt),
          border: Border.all(
            color: selected ? primary : primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : ZonezColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

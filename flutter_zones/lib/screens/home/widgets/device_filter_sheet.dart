import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/zonez_colors.dart';
import '../../../models/lounge_model.dart';
import '../../../utils/lounge_filter_utils.dart';

/// Expandable bottom sheet — multi-select AND filter for all catalog devices.
Future<void> showDeviceFilterSheet({
  required BuildContext context,
  required List<LoungeModel> allLounges,
  required LoungeDeviceFilter currentFilter,
  required ValueChanged<LoungeDeviceFilter> onApply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return _DeviceFilterSheet(
        allLounges: allLounges,
        initialFilter: currentFilter,
        onApply: (filter) {
          onApply(filter);
          Navigator.pop(ctx);
        },
      );
    },
  );
}

class _DeviceFilterSheet extends StatefulWidget {
  const _DeviceFilterSheet({
    required this.allLounges,
    required this.initialFilter,
    required this.onApply,
  });

  final List<LoungeModel> allLounges;
  final LoungeDeviceFilter initialFilter;
  final ValueChanged<LoungeDeviceFilter> onApply;

  @override
  State<_DeviceFilterSheet> createState() => _DeviceFilterSheetState();
}

class _DeviceFilterSheetState extends State<_DeviceFilterSheet> {
  late LoungeDeviceFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = isDark ? ZonezColors.cardDark : Colors.white;
    final primary = isDark ? ZonezColors.neonPurple : ZonezColors.lightPrimary;
    final deviceTypes =
        aggregateAvailableDeviceTypes(widget.allLounges);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primary.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ZonezColors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.tune, color: primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'تصفية الأجهزة',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                  ),
                  if (_filter.hasActiveFilters)
                    TextButton(
                      onPressed: () =>
                          setState(() => _filter = _filter.clear()),
                      child: Text(
                        'مسح',
                        style: GoogleFonts.cairo(
                          color: ZonezColors.neonRed,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'اختر أجهزة متعددة — تُعرض الصالات التي توفر جميع الأجهزة المحددة',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: ZonezColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              if (deviceTypes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'لا توجد أجهزة متاحة حالياً',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(color: ZonezColors.textMuted),
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: deviceTypes.map((type) {
                    final meta =
                        deviceFilterMeta(type, widget.allLounges);
                    final selected = _filter.isActive(type);
                    return _FilterDeviceTile(
                      meta: meta,
                      selected: selected,
                      primary: primary,
                      isDark: isDark,
                      onTap: () => setState(
                        () => _filter = _filter.toggle(type),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? ZonezColors.neonGradient
                        : ZonezColors.lightAccentGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => widget.onApply(_filter),
                      child: Center(
                        child: Text(
                          'تطبيق التصفية',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterDeviceTile extends StatelessWidget {
  const _FilterDeviceTile({
    required this.meta,
    required this.selected,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  final DeviceFilterMeta meta;
  final bool selected;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: (MediaQuery.sizeOf(context).width - 72) / 2,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: selected
              ? (isDark
                  ? ZonezColors.neonGradient
                  : ZonezColors.lightAccentGradient)
              : null,
          color: selected
              ? null
              : (isDark ? ZonezColors.inputBg : ZonezColors.lightSurfaceAlt),
          border: Border.all(
            color: selected ? Colors.transparent : primary.withValues(alpha: 0.3),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              meta.icon,
              size: 22,
              color: selected ? Colors.white : primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.label,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : ZonezColors.textMuted,
                    ),
                  ),
                  Text(
                    '${meta.loungeCount} صالة',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.8)
                          : ZonezColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

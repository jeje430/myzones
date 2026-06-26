import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/location/zonez_location_service.dart';
import '../../../core/maps/zonez_explore_map_config.dart';
import '../../../core/platform/app_platform.dart';
import '../../../core/theme/zonez_colors.dart';
import '../../../models/map_lounge.dart';
import '../../../providers/app_state_provider.dart';
import '../../../providers/lounge_ratings_provider.dart';
import '../../../utils/distance_formatter.dart';
import '../../../widgets/glass_container.dart';
import '../../lounge/lounge_details_screen.dart';
import '../widgets/explore/explore_filter_chips.dart';
import '../widgets/explore/explore_map_overlay.dart';
import '../widgets/explore/explore_mobile_only_gate.dart';
import '../widgets/explore/zonez_explore_pins.dart';
import '../widgets/explore/explore_map_bottom_carousel.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key, required this.onFavoriteTap});

  final void Function(String loungeName) onFavoriteTap;

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> with TickerProviderStateMixin {
  static const _tripoliFallback = LatLng(32.8872, 13.1913);
  static const _nearbyRadiusKm = 100.0;

  final MapController _mapController = MapController();
  final PageController _bottomCardController = PageController(viewportFraction: 0.93);

  /// Real GPS only — never set from fallback or hall coordinates.
  LatLng? _userLocation;

  MapLounge? _selectedLounge;
  bool _blockMapTap = false;
  String? _locationError;
  String? _loungesError;
  bool _isLocating = true;
  bool _isLoadingLounges = false;

  bool _ps5Filter = false;
  bool _pcFilter = false;
  bool _openNowFilter = false;

  late final AnimationController _pulseController;
  List<MapLounge> _allLounges = [];
  List<MapLounge> _filteredLounges = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    if (!AppPlatform.supportsExploreMap) return;

    _pulseController.repeat();
    _pulseController.addListener(() {
      if (mounted) setState(() {});
    });
    _bootstrapExplore();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bottomCardController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapExplore() async {
    await _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    final position = await ZonezLocationService.getFastLocation();

    if (!mounted) return;

    if (position == null) {
      setState(() {
        _locationError =
            'تعذّر تحديد موقعك.\nتأكد من تفعيل GPS ومنح الصلاحية.';
        _isLocating = false;
      });
      await _loadNearbyLounges(useFallbackOrigin: true);
      return;
    }

    final location = LatLng(position.latitude, position.longitude);
    setState(() {
      _userLocation = location;
      _isLocating = false;
    });

    _moveMap(location, ZonezExploreMapConfig.defaultZoom);
    await _loadNearbyLounges();
  }

  Future<void> _loadNearbyLounges({bool useFallbackOrigin = false}) async {
    final origin = _userLocation ?? _tripoliFallback;
    String? locationHint;

    if (useFallbackOrigin && _userLocation == null) {
      locationHint =
          'تعذّر تحديد موقعك — يتم عرض الصالات حسب موقع افتراضي.';
    }

    setState(() {
      _isLoadingLounges = true;
      if (locationHint == null) {
        _loungesError = null;
      }
    });

    final provider = context.read<LoungeRatingsProvider>();
    await provider.loadLounges();

    List<MapLounge> lounges = [];
    String? fetchWarning;

    try {
      final nearby = await provider.loadNearbyLounges(
        latitude: origin.latitude,
        longitude: origin.longitude,
        radiusKm: _nearbyRadiusKm,
        openNow: _openNowFilter,
      );
      lounges = mapLoungesFromCatalog(nearby);
    } catch (e) {
      fetchWarning = _friendlyLoungesFetchError(e);
      lounges = mapLoungesNearOrigin(
        provider.lounges,
        origin,
        radiusKm: _nearbyRadiusKm,
      );
    }

    if (!mounted) return;

    setState(() {
      _isLoadingLounges = false;
      if (lounges.isEmpty) {
        _loungesError = fetchWarning ?? locationHint;
        _allLounges = [];
      } else {
        _loungesError = fetchWarning ?? locationHint;
        _allLounges = lounges;
      }
    });

    _applyFilters();
    _fitVisibleLounges();
  }

  String _friendlyLoungesFetchError(Object error) {
    final raw = error.toString();
    if (raw.contains('SocketException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('Connection refused') ||
        raw.contains('Network is unreachable')) {
      return 'تعذّر الاتصال بالخادم — تم عرض الصالات من القائمة المحفوظة.';
    }
    return 'تعذّر تحميل الصالات القريبة — تم عرض القائمة العامة.';
  }

  void _applyFilters() {
    final next = _allLounges
        .where(
          (lounge) => lounge.matchesFilters(
            ps5Filter: _ps5Filter,
            pcFilter: _pcFilter,
            openNowFilter: _openNowFilter,
          ),
        )
        .toList();

    if (_sameLounges(_filteredLounges, next)) return;

    setState(() {
      _filteredLounges = next;
      if (_selectedLounge != null &&
          !next.any((l) => l.id == _selectedLounge!.id)) {
        _selectedLounge = null;
      }
    });
  }

  bool _sameLounges(List<MapLounge> a, List<MapLounge> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  void _moveMap(LatLng center, double zoom) {
    try {
      _mapController.move(center, zoom);
    } catch (_) {}
  }

  void _fitVisibleLounges() {
    if (_filteredLounges.isEmpty) {
      if (_userLocation != null) {
        _moveMap(_userLocation!, ZonezExploreMapConfig.defaultZoom);
      }
      return;
    }

    if (_filteredLounges.length == 1) {
      _moveMap(_filteredLounges.first.position, 15.5);
      return;
    }

    final coordinates = [
      ..._filteredLounges.map((l) => l.position),
      if (_userLocation != null) _userLocation!,
    ];

    try {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: coordinates,
          padding: const EdgeInsets.fromLTRB(48, 160, 48, 140),
        ),
      );
    } catch (_) {}
  }

  void _onMarkerTap(MapLounge lounge) {
    HapticFeedback.lightImpact();
    _blockMapTap = true;
    setState(() => _selectedLounge = lounge);
    _scrollBottomCardTo(lounge);
    _moveMap(lounge.position, 15.5);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _blockMapTap = false;
    });
  }

  void _scrollBottomCardTo(MapLounge lounge) {
    final index = _filteredLounges.indexWhere((l) => l.id == lounge.id);
    if (index < 0) return;

    void jump() {
      if (!_bottomCardController.hasClients) return;
      _bottomCardController.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }

    if (_bottomCardController.hasClients) {
      jump();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => jump());
    }
  }

  void _onBottomCardPageChanged(int index) {
    if (index < 0 || index >= _filteredLounges.length) return;
    if (_blockMapTap) return;

    final lounge = _filteredLounges[index];
    if (_selectedLounge?.id == lounge.id) return;

    setState(() => _selectedLounge = lounge);
    _moveMap(lounge.position, 15.5);
  }

  void _onMapTap() {
    if (_blockMapTap) return;
    if (_selectedLounge == null) return;
    setState(() => _selectedLounge = null);
  }

  void _toggleFilter({
    required bool Function() getter,
    required void Function(bool) setter,
    bool reloadFromApi = false,
  }) {
    setState(() => setter(!getter()));

    if (reloadFromApi) {
      _loadNearbyLounges(useFallbackOrigin: _userLocation == null);
      return;
    }

    _applyFilters();
    _fitVisibleLounges();
  }

  String? _distanceLabel(MapLounge lounge) {
    if (lounge.distanceMeters != null) {
      return DistanceFormatter.fromMeters(lounge.distanceMeters);
    }

    if (_userLocation == null) return 'جاري التحديد...';

    final meters = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      lounge.position.latitude,
      lounge.position.longitude,
    );

    return DistanceFormatter.formatMeters(meters);
  }

  void _openLoungeDetails(String loungeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoungeDetailsScreen(loungeId: loungeId),
      ),
    );
  }

  void _zoomBy(double delta) {
    try {
      final camera = _mapController.camera;
      _mapController.move(camera.center, camera.zoom + delta);
    } catch (_) {}
  }

  Future<void> _recenterOnUser() async {
    if (_userLocation == null) {
      await _initializeLocation();
      return;
    }
    _moveMap(_userLocation!, ZonezExploreMapConfig.defaultZoom);
  }

  List<CircleMarker> _buildPulseCircles() {
    if (_userLocation == null) return const [];

    final t = _pulseController.value;
    final accent = ZonezColors.neonCyan;

    return [
      CircleMarker(
        point: _userLocation!,
        radius: 28 + (t * 42),
        color: accent.withValues(alpha: (1 - t) * 0.18),
        borderColor: accent.withValues(alpha: (1 - t) * 0.35),
        borderStrokeWidth: 2,
      ),
      CircleMarker(
        point: _userLocation!,
        radius: 55 + (t * 70),
        color: ZonezColors.neonPurple.withValues(alpha: (1 - t) * 0.1),
        borderColor: ZonezColors.neonPurple.withValues(alpha: (1 - t) * 0.2),
        borderStrokeWidth: 1,
      ),
    ];
  }

  List<CircleMarker> _buildSelectedCircle() {
    final selected = _selectedLounge;
    if (selected == null) return const [];

    final accent = switch (selected.category) {
      LoungeCategory.ps5 => ZonezColors.neonCyan,
      LoungeCategory.pc => ZonezColors.neonPurple,
      LoungeCategory.mixed => ZonezColors.neonGold,
    };

    return [
      CircleMarker(
        point: selected.position,
        radius: 55,
        color: accent.withValues(alpha: 0.12),
        borderColor: accent.withValues(alpha: 0.75),
        borderStrokeWidth: 2,
      ),
    ];
  }

  List<Marker> _buildHallMarkers() {
    return _filteredLounges.map((lounge) {
      final isSelected = _selectedLounge?.id == lounge.id;
      return Marker(
        point: lounge.position,
        width: isSelected ? 52 : 44,
        height: isSelected ? 64 : 56,
        child: ZonezHallPin(
          category: lounge.category,
          selected: isSelected,
          onTap: () => _onMarkerTap(lounge),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppPlatform.supportsExploreMap) {
      return ExploreMobileOnlyGate(
        onGoHome: () => context.read<AppStateProvider>().setBottomNavIndex(0),
      );
    }

    final appState = context.watch<AppStateProvider>();
    final loungeProvider = context.watch<LoungeRatingsProvider>();
    final selected = _selectedLounge;
    final initialCenter = _userLocation ?? _tripoliFallback;

    return ColoredBox(
      color: ZonezColors.darkNavy,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: ZonezExploreMapConfig.defaultZoom,
                    minZoom: ZonezExploreMapConfig.minZoom,
                    maxZoom: ZonezExploreMapConfig.maxZoom,
                    backgroundColor: ZonezColors.darkNavy,
                    onTap: (_, __) => _onMapTap(),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: ZonezExploreMapConfig.tileUrl,
                      subdomains: ZonezExploreMapConfig.tileSubdomains,
                      userAgentPackageName: ZonezExploreMapConfig.userAgent,
                      maxZoom: ZonezExploreMapConfig.maxZoom,
                    ),
                    CircleLayer(
                      circles: [
                        ..._buildPulseCircles(),
                        ..._buildSelectedCircle(),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        ..._buildHallMarkers(),
                        if (_userLocation != null)
                          Marker(
                            point: _userLocation!,
                            width: 50,
                            height: 50,
                            child: ZonezUserPin(pulse: _pulseController.value),
                          ),
                      ],
                    ),
                  ],
                ),
                const ExploreMapOverlay(),
                if (_isLocating || _isLoadingLounges)
                  Container(
                    color: ZonezColors.darkNavy.withValues(alpha: 0.72),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 42,
                            height: 42,
                            child: CircularProgressIndicator(
                              color: ZonezColors.neonCyan,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _isLocating
                                ? 'جاري تحديد موقعك...'
                                : 'جاري تحميل الصالات القريبة...',
                            style: GoogleFonts.cairo(
                              color: ZonezColors.neonCyan,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                _buildTopOverlay(),
                if (_locationError != null) _buildLocationBanner(),
                if (_loungesError != null && !_isLoadingLounges)
                  _buildLoungesBanner(),
                if (_filteredLounges.isEmpty &&
                    !_isLoadingLounges &&
                    !_isLocating)
                  _buildEmptyState(),
                _buildMapControls(),
              ],
            ),
          ),
          if (selected != null && _filteredLounges.isNotEmpty)
            ExploreMapBottomCarousel(
              lounges: _filteredLounges,
              pageController: _bottomCardController,
              loungeProvider: loungeProvider,
              appState: appState,
              onFavoriteTap: widget.onFavoriteTap,
              onOpenDetails: _openLoungeDetails,
              distanceLabelFor: _distanceLabel,
              onPageChanged: _onBottomCardPageChanged,
            ),
        ],
      ),
    );
  }

  Widget _buildTopOverlay() {
    final countLabel = _filteredLounges.isEmpty
        ? 'لا توجد صالات قريبة'
        : '${_filteredLounges.length} صالة قريبة';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassContainer(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              borderRadius: BorderRadius.circular(18),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: ZonezColors.neonGradient,
                      boxShadow: [
                        BoxShadow(
                          color: ZonezColors.neonPurple.withValues(alpha: 0.45),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.map_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'استكشف ZONEZ',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: ZonezColors.neonPurple.withValues(alpha: 0.7),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          countLabel,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: ZonezColors.neonCyan,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _GlowIconButton(
                    icon: Icons.my_location_rounded,
                    onPressed: _recenterOnUser,
                    tooltip: 'موقعي',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ExploreFilterChips(
              ps5Selected: _ps5Filter,
              pcSelected: _pcFilter,
              openNowSelected: _openNowFilter,
              onPs5Tap: () => _toggleFilter(
                getter: () => _ps5Filter,
                setter: (v) => _ps5Filter = v,
              ),
              onPcTap: () => _toggleFilter(
                getter: () => _pcFilter,
                setter: (v) => _pcFilter = v,
              ),
              onOpenNowTap: () => _toggleFilter(
                getter: () => _openNowFilter,
                setter: (v) => _openNowFilter = v,
                reloadFromApi: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationBanner() {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 132,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: ZonezColors.cardDark.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ZonezColors.neonRed.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_off_rounded, color: ZonezColors.neonRed, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _locationError!,
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: _initializeLocation,
                child: Text(
                  'إعادة',
                  style: GoogleFonts.cairo(color: ZonezColors.neonCyan),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoungesBanner() {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 132,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: ZonezColors.cardDark.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ZonezColors.neonGold.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: ZonezColors.neonGold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _loungesError!,
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: () => _loadNearbyLounges(useFallbackOrigin: _userLocation == null),
                child: Text(
                  'إعادة',
                  style: GoogleFonts.cairo(color: ZonezColors.neonCyan),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ZonezColors.cardDark.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ZonezColors.neonPurple.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          'لا توجد صالات منشورة بإحداثيات GPS في نطاقك حالياً.\nتأكّد أن المدير أدخل Latitude/Longitude وحفظ التغييرات.',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            color: ZonezColors.textMuted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const ExplorePinLegend(),
          const SizedBox(height: 10),
          _GlowIconButton(
            icon: Icons.add_rounded,
            onPressed: () => _zoomBy(1),
            tooltip: 'تكبير',
            size: 44,
          ),
          const SizedBox(height: 8),
          _GlowIconButton(
            icon: Icons.remove_rounded,
            onPressed: () => _zoomBy(-1),
            tooltip: 'تصغير',
            size: 44,
          ),
        ],
      ),
    );
  }
}

class _GlowIconButton extends StatelessWidget {
  const _GlowIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 48,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: isDark ? ZonezColors.neonGradient : ZonezColors.lightAccentGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: ZonezColors.neonPurple.withValues(alpha: 0.35),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: math.min(size * 0.5, 24)),
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/maps/zonez_map_style.dart';
import '../../../core/theme/zonez_colors.dart';
import '../../../models/map_lounge.dart';
import '../../../providers/app_state_provider.dart';
import '../widgets/explore/explore_filter_chips.dart';
import '../widgets/explore/explore_glass_card.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key, required this.onFavoriteTap});

  final void Function(String loungeName) onFavoriteTap;

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> with TickerProviderStateMixin {
  static const _fallbackLocation = LatLng(32.8872, 13.1913);
  static const _defaultZoom = 14.5;

  GoogleMapController? _mapController;
  LatLng? _userLocation;
  MapLounge? _selectedLounge;
  String? _locationError;
  bool _isLocating = true;
  bool _mapReady = false;

  bool _ps5Filter = false;
  bool _pcFilter = false;
  bool _openNowFilter = false;

  Set<Marker> _markers = {};
  Set<Circle> _pulseCircles = {};
  final Map<String, BitmapDescriptor> _markerIcons = {};

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _pulseController.addListener(_updatePulseCircles);
    _initializeLocation();
    _prepareMarkers();
  }

  @override
  void dispose() {
    _pulseController.removeListener(_updatePulseCircles);
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  List<MapLounge> get _filteredLounges => kSampleMapLounges
      .where(
        (lounge) => lounge.matchesFilters(
          ps5Filter: _ps5Filter,
          pcFilter: _pcFilter,
          openNowFilter: _openNowFilter,
        ),
      )
      .toList();

  Future<void> _initializeLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('خدمة الموقع غير مفعّلة. فعّل GPS من إعدادات الجهاز.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('تم رفض إذن الموقع. اسمح بالوصول للموقع من الإعدادات.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'إذن الموقع مرفوض نهائياً. افتح إعدادات التطبيق وفعّل الموقع.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      if (!mounted) return;

      final location = LatLng(position.latitude, position.longitude);
      setState(() {
        _userLocation = location;
        _isLocating = false;
      });

      _updatePulseCircles();
      await _animateToLocation(location, zoom: _defaultZoom);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locationError = error.toString().replaceFirst('Exception: ', '');
        _userLocation = _fallbackLocation;
        _isLocating = false;
      });
      _updatePulseCircles();
      await _animateToLocation(_fallbackLocation, zoom: _defaultZoom);
    }
  }

  Future<void> _prepareMarkers() async {
    final ps5Icon = await _createNeonMarkerIcon(ZonezColors.neonCyan);
    final pcIcon = await _createNeonMarkerIcon(ZonezColors.neonPurple);
    final mixedIcon = await _createNeonMarkerIcon(ZonezColors.neonGold);

    if (!mounted) return;

    _markerIcons['ps5'] = ps5Icon;
    _markerIcons['pc'] = pcIcon;
    _markerIcons['mixed'] = mixedIcon;

    await _rebuildMarkers();
  }

  Future<void> _rebuildMarkers() async {
    if (_markerIcons.isEmpty) return;

    final markers = <Marker>{};
    for (final lounge in _filteredLounges) {
      final iconKey = switch (lounge.category) {
        LoungeCategory.ps5 => 'ps5',
        LoungeCategory.pc => 'pc',
        LoungeCategory.mixed => 'mixed',
      };

      markers.add(
        Marker(
          markerId: MarkerId(lounge.id),
          position: lounge.position,
          icon: _markerIcons[iconKey] ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          onTap: () => _onMarkerTap(lounge),
        ),
      );
    }

    if (!mounted) return;
    setState(() => _markers = markers);
  }

  Future<BitmapDescriptor> _createNeonMarkerIcon(Color glowColor) async {
    const size = 96.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    final outerGlow = Paint()
      ..color = glowColor.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center, 28, outerGlow);

    final midGlow = Paint()
      ..color = glowColor.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, 20, midGlow);

    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor,
          glowColor.withValues(alpha: 0.65),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 14));
    canvas.drawCircle(center, 14, corePaint);

    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, 14, ringPaint);

    final pinPath = Path()
      ..moveTo(center.dx, size - 8)
      ..lineTo(center.dx - 10, center.dy + 8)
      ..lineTo(center.dx + 10, center.dy + 8)
      ..close();
    final pinPaint = Paint()..color = glowColor.withValues(alpha: 0.85);
    canvas.drawPath(pinPath, pinPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(bytes);
  }

  void _updatePulseCircles() {
    if (_userLocation == null) return;

    final t = _pulseController.value;
    final innerRadius = 35 + (t * 55);
    final outerRadius = 70 + (t * 90);
    final innerAlpha = (1 - t) * 0.35;
    final outerAlpha = (1 - t) * 0.18;

    setState(() {
      _pulseCircles = {
        Circle(
          circleId: const CircleId('pulse-inner'),
          center: _userLocation!,
          radius: innerRadius,
          fillColor: ZonezColors.neonCyan.withValues(alpha: innerAlpha),
          strokeColor: ZonezColors.neonCyan.withValues(alpha: innerAlpha + 0.15),
          strokeWidth: 2,
        ),
        Circle(
          circleId: const CircleId('pulse-outer'),
          center: _userLocation!,
          radius: outerRadius,
          fillColor: ZonezColors.neonPurple.withValues(alpha: outerAlpha),
          strokeColor: ZonezColors.neonPurple.withValues(alpha: outerAlpha + 0.1),
          strokeWidth: 1,
        ),
      };
    });
  }

  Future<void> _animateToLocation(LatLng location, {required double zoom}) async {
    final controller = _mapController;
    if (controller == null) return;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: zoom, tilt: 12),
      ),
    );
  }

  void _onMarkerTap(MapLounge lounge) {
    HapticFeedback.lightImpact();
    setState(() => _selectedLounge = lounge);
    _animateToLocation(lounge.position, zoom: 15.5);
  }

  void _onMapTap(LatLng _) {
    if (_selectedLounge == null) return;
    setState(() => _selectedLounge = null);
  }

  void _toggleFilter({
    required bool Function() getter,
    required void Function(bool) setter,
  }) {
    setState(() => setter(!getter()));
    _rebuildMarkers();
    if (_selectedLounge != null &&
        !_filteredLounges.any((l) => l.id == _selectedLounge!.id)) {
      setState(() => _selectedLounge = null);
    }
  }

  double _distanceTo(MapLounge lounge) {
    final origin = _userLocation ?? _fallbackLocation;
    return Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      lounge.position.latitude,
      lounge.position.longitude,
    );
  }

  Future<void> _openExternalNavigation(MapLounge lounge) async {
    final lat = lounge.position.latitude;
    final lng = lounge.position.longitude;
    final label = Uri.encodeComponent(lounge.name);

    final candidates = [
      Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$label',
      ),
      Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)'),
      Uri.parse('https://maps.apple.com/?daddr=$lat,$lng'),
    ];

    for (final uri in candidates) {
      try {
        if (await canLaunchUrl(uri)) {
          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (launched) return;
        }
      } catch (_) {
        continue;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تعذّر فتح تطبيق الخرائط',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: ZonezColors.cardDark,
      ),
    );
  }

  Future<void> _zoomBy(double delta) async {
    final controller = _mapController;
    if (controller == null) return;
    final zoom = await controller.getZoomLevel();
    await controller.animateCamera(CameraUpdate.zoomTo(zoom + delta));
  }

  Future<void> _recenterOnUser() async {
    if (_userLocation == null) {
      await _initializeLocation();
      return;
    }
    await _animateToLocation(_userLocation!, zoom: _defaultZoom);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final initialTarget = _userLocation ?? _fallbackLocation;

    return ColoredBox(
      color: ZonezColors.darkNavy,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GoogleMap(
            style: kZonezDarkMapStyle,
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: _defaultZoom,
              tilt: 12,
            ),
            onMapCreated: (controller) async {
              _mapController = controller;
              if (!mounted) return;
              setState(() => _mapReady = true);
              if (_userLocation != null) {
                await _animateToLocation(_userLocation!, zoom: _defaultZoom);
              }
            },
            markers: _markers,
            circles: _pulseCircles,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            liteModeEnabled: false,
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + 72,
              bottom: _selectedLounge != null ? 260 : 100,
            ),
            onTap: _onMapTap,
          ),
          if (!_mapReady || _isLocating)
            Container(
              color: ZonezColors.darkNavy.withValues(alpha: 0.75),
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
                      _isLocating ? 'جاري تحديد موقعك...' : 'تحميل الخريطة...',
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
          _buildMapControls(),
          AnimatedSlide(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            offset: _selectedLounge != null ? Offset.zero : const Offset(0, 1.2),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 260),
              opacity: _selectedLounge != null ? 1 : 0,
              child: _selectedLounge == null
                  ? const SizedBox.shrink()
                  : Align(
                      alignment: Alignment.bottomCenter,
                      child: ExploreGlassCard(
                        lounge: _selectedLounge!,
                        distanceMeters: _distanceTo(_selectedLounge!),
                        onNavigate: () => _openExternalNavigation(_selectedLounge!),
                        isFavorite: appState.isFavorite(_selectedLounge!.name),
                        onFavoriteTap: () =>
                            widget.onFavoriteTap(_selectedLounge!.name),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopOverlay() {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'استكشف ZONEZ',
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: ZonezColors.neonPurple.withValues(alpha: 0.8),
                          blurRadius: 12,
                        ),
                      ],
                    ),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBanner() {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 118,
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

  Widget _buildMapControls() {
    final bottomOffset = _selectedLounge != null ? 270.0 : 108.0;

    return Positioned(
      left: 16,
      bottom: bottomOffset,
      child: Column(
        children: [
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
              color: ZonezColors.cardDark.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: ZonezColors.neonPurple.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: ZonezColors.neonPurple.withValues(alpha: 0.25),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(icon, color: ZonezColors.neonCyan, size: math.min(size * 0.5, 24)),
          ),
        ),
      ),
    );
  }
}

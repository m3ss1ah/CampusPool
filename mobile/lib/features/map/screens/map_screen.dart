import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/cp_commute_card.dart';
import '../../../shared/widgets/cp_transit_badge.dart';
import '../../commute/providers/commute_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../../core/network/osrm_service.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  LatLng? _userLocation;
  bool _locationLoading = true;
  final OsrmService _osrmService = OsrmService();
  List<LatLng> _selectedRoute = [];
  String? _selectedCommuteId;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        // Use default location
        setState(() {
          _userLocation = const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
          _locationLoading = false;
        });
        _fetchNearby(AppConstants.defaultLat, AppConstants.defaultLng);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _locationLoading = false;
      });
      _mapController.move(_userLocation!, 14);
      _fetchNearby(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _userLocation = const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
        _locationLoading = false;
      });
      _fetchNearby(AppConstants.defaultLat, AppConstants.defaultLng);
    }
  }

  void _fetchNearby(double lat, double lng) {
    ref.read(nearbyCommutesNotifierProvider.notifier).fetchNearby(lat: lat, lng: lng);
  }

  void _recenterAndRefresh() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 14);
      _fetchNearby(_userLocation!.latitude, _userLocation!.longitude);
    }
  }

  void _showCommutePopup(BuildContext context, dynamic commute) async {
    // Fetch route polyline
    final route = await _osrmService.getRoute(
      LatLng(commute.sourceLat, commute.sourceLng),
      LatLng(commute.destLat, commute.destLng),
    );

    if (mounted) {
      setState(() {
        _selectedRoute = route;
        _selectedCommuteId = commute.id;
      });
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final minutesUntil = commute.departureTime.difference(DateTime.now()).inMinutes;
        final timeText = minutesUntil > 0
            ? 'Leaves in ${minutesUntil}m'
            : 'Departed ${timeago.format(commute.departureTime)}';
        final progress = minutesUntil > 60 ? 0.0 : (1 - (minutesUntil / 60)).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusSheet)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('RIDE DETECTED', style: AppTextStyles.labelLg.copyWith(letterSpacing: 2)),
              const SizedBox(height: 16),
              CpCommuteCard(
                routeLetter: commute.sourceLabel.isNotEmpty ? commute.sourceLabel[0].toUpperCase() : '?',
                sourceLabel: commute.sourceLabel,
                destLabel: commute.destLabel,
                timeAway: timeText,
                availableSeats: commute.availableSeats,
                totalSeats: commute.totalSeats,
                vehicleType: commute.vehicleType ?? 'car',
                progress: progress,
                onTap: null, // Card itself not clickable
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: AppConstants.buttonHeight,
                child: ElevatedButton(
                  onPressed: () {
                    context.pop();
                    context.push('/commute/${commute.id}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.signalYellow,
                    foregroundColor: AppColors.systemBlack,
                  ),
                  child: const Text('VIEW & JOIN RIDE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _selectedRoute = [];
          _selectedCommuteId = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nearbyState = ref.watch(nearbyCommutesNotifierProvider);
    final commutes = nearbyState.value?.commutes ?? [];
    final notificationsState = ref.watch(notificationNotifierProvider).value;
    final unreadCount = notificationsState?.unreadCount ?? 0;

    return Stack(
      children: [
        // ── Map Layer ──
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _userLocation ??
                const LatLng(AppConstants.defaultLat, AppConstants.defaultLng),
            initialZoom: 13.5,
            maxZoom: 18,
            minZoom: 10,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.campuspool.campuspool',
            ),
            // User location marker
            if (_userLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _userLocation!,
                    width: 20, height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 8)],
                      ),
                    ),
                  ),
                ],
              ),
            // Commute pins (Clustered)
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 45,
                size: const Size(40, 40),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(50),
                markers: commutes.map((commute) {
                  return Marker(
                    point: LatLng(commute.sourceLat, commute.sourceLng),
                    width: 48, height: 48,
                    child: GestureDetector(
                      onTap: () => _showCommutePopup(context, commute),
                      child: _PulsingPin(
                        label: commute.sourceLabel.isNotEmpty
                            ? commute.sourceLabel[0].toUpperCase()
                            : '?',
                      ),
                    ),
                  );
                }).toList(),
                builder: (context, markers) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.signalYellow.withValues(alpha: 0.8),
                      border: Border.all(color: AppColors.systemBlack, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        markers.length.toString(),
                        style: const TextStyle(
                          color: AppColors.systemBlack,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Selected Route Polyline
            if (_selectedRoute.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _selectedRoute,
                    color: AppColors.signalYellow,
                    strokeWidth: 4.0,
                    isDotted: false,
                  ),
                ],
              ),
          ],
        ),

        // ── Top Island ──
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: AppConstants.screenPaddingH,
          right: AppConstants.screenPaddingH,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface0.withOpacity(0.85),
                  border: Border.all(color: AppColors.borderStrong, width: 2),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _recenterAndRefresh,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.signalYellow.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.my_location, color: AppColors.signalYellow, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nearby Rides', style: AppTextStyles.labelSm.copyWith(color: AppColors.textSecondary, fontSize: 10)),
                          Text(
                            _locationLoading ? 'Getting location...' : '${commutes.length} active',
                            style: AppTextStyles.labelLg.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    // Refresh
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.signalYellow),
                      onPressed: _recenterAndRefresh,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    // Notifications
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
                          onPressed: () => context.push('/notifications'),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.signalYellow,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(
                                  color: AppColors.systemBlack,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Bottom Sheet ──
        DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: 0.28,
          minChildSize: 0.12,
          maxChildSize: 0.85,
          snap: true,
          snapSizes: const [0.12, 0.28, 0.55, 0.85],
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface1,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusSheet)),
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -4))],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPaddingH),
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.borderStrong,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Row(
                    children: [
                      Text('NEARBY COMMUTES', style: AppTextStyles.labelLg.copyWith(
                        color: AppColors.textPrimary, letterSpacing: 2,
                      )),
                      const SizedBox(width: 8),
                      CpTransitBadge(text: '${commutes.length} Active', isActive: commutes.isNotEmpty),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  // Loading state
                  if (nearbyState.value?.isLoading == true)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: AppColors.signalYellow),
                    )),

                  // Error state
                  if (nearbyState.value?.error != null)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        nearbyState.value!.error!,
                        style: AppTextStyles.body.copyWith(color: AppColors.rejectRed),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Empty state
                  if (commutes.isEmpty && nearbyState.value?.isLoading != true && nearbyState.value?.error == null)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.explore_off, color: AppColors.textTertiary, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'No rides nearby',
                            style: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Be the first to offer a ride!',
                            style: AppTextStyles.labelSm.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),

                  // Commute cards
                  ...commutes.map((commute) {
                    final minutesUntil = commute.departureTime.difference(DateTime.now()).inMinutes;
                    final timeText = minutesUntil > 0
                        ? 'Leaves in ${minutesUntil}m'
                        : 'Departed ${timeago.format(commute.departureTime)}';
                    final progress = minutesUntil > 60 ? 0.0 : (1 - (minutesUntil / 60)).clamp(0.0, 1.0);

                    return CpCommuteCard(
                      routeLetter: commute.sourceLabel.isNotEmpty
                          ? commute.sourceLabel[0].toUpperCase()
                          : '?',
                      sourceLabel: commute.sourceLabel,
                      destLabel: commute.destLabel,
                      timeAway: timeText,
                      availableSeats: commute.availableSeats,
                      totalSeats: commute.totalSeats,
                      vehicleType: commute.vehicleType ?? 'car',
                      progress: progress,
                      onTap: () => context.push('/commute/${commute.id}'),
                    );
                  }),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Pulsing map pin with route letter.
class _PulsingPin extends StatefulWidget {
  final String label;
  const _PulsingPin({required this.label});

  @override
  State<_PulsingPin> createState() => _PulsingPinState();
}

class _PulsingPinState extends State<_PulsingPin> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _scale = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.signalYellow.withOpacity(_opacity.value),
              ),
            ),
          ),
        ),
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(
            color: AppColors.signalYellow,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.systemBlack,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

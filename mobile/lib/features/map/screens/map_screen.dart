import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/cp_commute_card.dart';
import '../../../shared/widgets/cp_transit_badge.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Map Layer ──
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(AppConstants.defaultLat, AppConstants.defaultLng),
            initialZoom: 13.5, // Forced refresh zoom
            maxZoom: 18,
            minZoom: 10,
          ),
          children: [
            // Dark tile layer
            TileLayer(
              urlTemplate: 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.campuspool.campuspool',
            ),
            // Commute pins will render here via MarkerLayer
            MarkerLayer(
              markers: [
                const Marker(
                  point: LatLng(19.0760, 72.8777),
                  width: 48, height: 48,
                  child: _PulsingPin(label: 'M'),
                ),
                const Marker(
                  point: LatLng(19.0780, 72.8750),
                  width: 48, height: 48,
                  child: _PulsingPin(label: 'K'),
                ),
                const Marker(
                  point: LatLng(19.1136, 72.8697),
                  width: 48, height: 48,
                  child: _PulsingPin(label: 'A'),
                ),
              ],
            ),
          ],
        ),

        // ── Zomato-style Top Island ──
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
                    // Profile / Menu
                    GestureDetector(
                      onTap: () {
                        // Open menu
                      },
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.signalYellow.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: AppColors.signalYellow, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Location/Status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Current Location', style: AppTextStyles.labelSm.copyWith(color: AppColors.textSecondary, fontSize: 10)),
                              const Icon(Icons.arrow_drop_down, color: AppColors.signalYellow, size: 16),
                            ],
                          ),
                          Text(
                            'Main Campus',
                            style: AppTextStyles.labelLg.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Theme Toggle
                    IconButton(
                      icon: const Icon(Icons.light_mode, color: AppColors.signalYellow),
                      onPressed: () {
                        // Toggle Theme Logic (Placeholder for phase 3 wiring)
                      },
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    // Notification Bell
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
                          onPressed: () {
                            // Open Notifications
                          },
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                        Container(
                          width: 10, height: 10,
                          margin: const EdgeInsets.only(top: 8, right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.rejectRed,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surface0, width: 2),
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
                      const CpTransitBadge(text: '2 Active', isActive: true),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  // Commute cards (sample data)
                  CpCommuteCard(
                    routeLetter: 'M',
                    sourceLabel: 'Main Lib',
                    destLabel: 'South Dorms',
                    timeAway: 'Leaves in 4m',
                    availableSeats: 2,
                    totalSeats: 4,
                    vehicleType: 'car',
                    progress: 0.15,
                    onTap: () {},
                  ),
                  CpCommuteCard(
                    routeLetter: 'K',
                    sourceLabel: 'Rec Center',
                    destLabel: 'Downtown',
                    timeAway: 'Leaves in 12m',
                    availableSeats: 1,
                    totalSeats: 1,
                    vehicleType: 'bike',
                    progress: 0.45,
                    onTap: () {},
                  ),
                  CpCommuteCard(
                    routeLetter: 'A',
                    sourceLabel: 'Andheri Stn',
                    destLabel: 'Powai',
                    timeAway: 'Leaves in 20m',
                    availableSeats: 3,
                    totalSeats: 4,
                    vehicleType: 'car',
                    progress: 0.8,
                    onTap: () {},
                  ),
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
        // Pulse ring
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
        // Pin core
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

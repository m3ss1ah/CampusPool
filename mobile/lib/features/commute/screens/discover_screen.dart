import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/cp_commute_card.dart';
import '../../../shared/widgets/cp_transit_badge.dart';
import '../providers/commute_provider.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadNearby);
  }

  Future<void> _loadNearby() async {
    double lat = AppConstants.defaultLat;
    double lng = AppConstants.defaultLng;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.deniedForever &&
          permission != LocationPermission.denied) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        lat = position.latitude;
        lng = position.longitude;
      }
    } catch (_) {}

    ref.read(nearbyCommutesNotifierProvider.notifier).fetchNearby(lat: lat, lng: lng);
  }

  @override
  Widget build(BuildContext context) {
    final nearbyState = ref.watch(nearbyCommutesNotifierProvider);
    final commutes = nearbyState.value?.commutes ?? [];
    final isLoading = nearbyState.value?.isLoading ?? false;
    final error = nearbyState.value?.error;

    return Scaffold(
      backgroundColor: AppColors.surface0,
      appBar: AppBar(
        title: const Text('DISCOVER RIDES'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.signalYellow),
            onPressed: () => context.push('/commute/create'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.signalYellow,
        backgroundColor: AppColors.surface1,
        onRefresh: _loadNearby,
        child: isLoading && commutes.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.signalYellow))
            : error != null && commutes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, color: AppColors.textTertiary, size: 48),
                        const SizedBox(height: 12),
                        Text(error, style: AppTextStyles.body.copyWith(color: AppColors.rejectRed)),
                      ],
                    ),
                  )
                : commutes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.explore_off, color: AppColors.textTertiary, size: 56),
                            const SizedBox(height: 12),
                            Text('No rides nearby', style: AppTextStyles.headline.copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              'Be the first to offer a ride!',
                              style: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: () => context.push('/commute/create'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.signalYellow,
                                  borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
                                ),
                                child: Text('OFFER RIDE', style: AppTextStyles.label.copyWith(
                                  color: AppColors.systemBlack,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                )),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppConstants.screenPaddingH),
                        itemCount: commutes.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppConstants.spacingLg),
                              child: Row(
                                children: [
                                  Text('NEARBY RIDES', style: AppTextStyles.labelLg.copyWith(
                                    color: AppColors.textPrimary, letterSpacing: 2,
                                  )),
                                  const SizedBox(width: 8),
                                  CpTransitBadge(text: '${commutes.length} Found', isActive: true),
                                ],
                              ),
                            );
                          }

                          final commute = commutes[index - 1];
                          final minutesUntil = commute.departureTime.difference(DateTime.now()).inMinutes;
                          final timeText = minutesUntil > 0
                              ? 'Leaves in ${minutesUntil}m'
                              : 'Departed ${timeago.format(commute.departureTime)}';
                          final progress = minutesUntil > 60
                              ? 0.0
                              : (1 - (minutesUntil / 60)).clamp(0.0, 1.0);

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
                        },
                      ),
      ),
    );
  }
}

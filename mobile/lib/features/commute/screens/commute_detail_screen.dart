import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/cp_button.dart';
import '../../../shared/widgets/cp_transit_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/commute_provider.dart';
import '../providers/seat_request_provider.dart';

class CommuteDetailScreen extends ConsumerStatefulWidget {
  final String commuteId;
  const CommuteDetailScreen({super.key, required this.commuteId});

  @override
  ConsumerState<CommuteDetailScreen> createState() => _CommuteDetailScreenState();
}

class _CommuteDetailScreenState extends ConsumerState<CommuteDetailScreen> {
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(commuteDetailNotifierProvider.notifier).fetchDetail(widget.commuteId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(commuteDetailNotifierProvider);
    final authState = ref.watch(authNotifierProvider).value;
    final currentUserId = authState?.user?['id'];

    return Scaffold(
      backgroundColor: AppColors.surface0,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('COMMUTE DETAIL'),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.signalYellow)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.rejectRed, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load commute', style: AppTextStyles.body.copyWith(color: AppColors.rejectRed)),
              const SizedBox(height: 12),
              CpButton(label: 'Retry', onPressed: () {
                ref.read(commuteDetailNotifierProvider.notifier).fetchDetail(widget.commuteId);
              }),
            ],
          ),
        ),
        data: (commute) {
          if (commute == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.signalYellow));
          }

          final isCreator = commute.creatorId == currentUserId;
          final creatorName = commute.creator?['full_name'] ?? 'Unknown';
          final departureFmt = DateFormat('MMM d, yyyy • h:mm a').format(commute.departureTime.toLocal());
          final participants = commute.participants ?? [];
          final myRequestStatus = commute.myRequestStatus;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.screenPaddingH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mini Map Route
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
                    border: Border.all(color: AppColors.borderStrong, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCameraFit: CameraFit.bounds(
                        bounds: LatLngBounds(
                          LatLng(commute.sourceLat, commute.sourceLng),
                          LatLng(commute.destLat, commute.destLng),
                        ),
                        padding: const EdgeInsets.all(32),
                      ),
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.campuspool.campuspool',
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [
                              LatLng(commute.sourceLat, commute.sourceLng),
                              LatLng(commute.destLat, commute.destLng),
                            ],
                            color: AppColors.signalYellow,
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(commute.sourceLat, commute.sourceLng),
                            width: 24, height: 24,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.signalYellow, width: 2),
                                color: AppColors.surface0,
                              ),
                            ),
                          ),
                          Marker(
                            point: LatLng(commute.destLat, commute.destLng),
                            width: 24, height: 24,
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.signalYellow,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spacingLg),

                // Status badge
                Row(
                  children: [
                    CpTransitBadge(
                      text: commute.status.toUpperCase(),
                      isActive: commute.status == 'open',
                    ),
                    const SizedBox(width: 8),
                    if (commute.vehicleType != null)
                      CpTransitBadge(text: commute.vehicleType!.toUpperCase(), isActive: false),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingLg),

                // Route
                _RouteBlock(
                  source: commute.sourceLabel,
                  dest: commute.destLabel,
                ),
                const SizedBox(height: AppConstants.spacingLg),

                // Time & Seats
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    border: Border.all(color: AppColors.borderSubtle, width: 2),
                    borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(icon: Icons.schedule, label: 'Departure', value: departureFmt),
                      const Divider(color: AppColors.borderSubtle, height: 24),
                      _InfoRow(
                        icon: Icons.event_seat,
                        label: 'Seats',
                        value: '${commute.availableSeats} of ${commute.totalSeats} available',
                      ),
                      if (commute.notes != null && commute.notes!.isNotEmpty) ...[
                        const Divider(color: AppColors.borderSubtle, height: 24),
                        _InfoRow(icon: Icons.note, label: 'Notes', value: commute.notes!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spacingLg),

                // Creator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    border: Border.all(color: AppColors.borderSubtle, width: 2),
                    borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.signalYellow.withOpacity(0.2),
                        child: Text(
                          creatorName.isNotEmpty ? creatorName[0].toUpperCase() : '?',
                          style: AppTextStyles.headline.copyWith(color: AppColors.signalYellow),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(creatorName, style: AppTextStyles.labelLg.copyWith(color: AppColors.textPrimary)),
                            Text(
                              isCreator ? 'You • Creator' : 'Ride Creator',
                              style: AppTextStyles.labelSm.copyWith(color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spacingLg),

                // Participants
                if (participants.isNotEmpty) ...[
                  Text('PARTICIPANTS', style: AppTextStyles.labelLg.copyWith(
                    color: AppColors.textPrimary, letterSpacing: 2,
                  )),
                  const SizedBox(height: 8),
                  ...participants.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface1,
                      borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
                      border: Border.all(color: AppColors.acceptGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.acceptGreen, size: 20),
                        const SizedBox(width: 8),
                        Text(p['full_name'] ?? 'Unknown', style: AppTextStyles.body),
                      ],
                    ),
                  )),
                  const SizedBox(height: AppConstants.spacingLg),
                ],

                // Action section
                if (!isCreator && commute.status == 'open') ...[
                  if (myRequestStatus == null) ...[
                    // Request a seat
                    Text('REQUEST A SEAT', style: AppTextStyles.labelLg.copyWith(
                      color: AppColors.textPrimary, letterSpacing: 2,
                    )),
                    const SizedBox(height: 8),
                    CpButton(
                      label: 'Request Seat →',
                      icon: Icons.person_add,
                      isLoading: ref.watch(seatRequestNotifierProvider).value?.isLoading ?? false,
                      onPressed: () async {
                        final success = await ref.read(seatRequestNotifierProvider.notifier)
                            .requestSeat(commuteId: widget.commuteId);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Seat request sent!'), backgroundColor: AppColors.acceptGreen),
                          );
                          ref.read(commuteDetailNotifierProvider.notifier).fetchDetail(widget.commuteId);
                        }
                      },
                    ),
                  ] else ...[
                    // Show request status
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: myRequestStatus == 'accepted'
                            ? AppColors.acceptGreen.withOpacity(0.1)
                            : myRequestStatus == 'rejected'
                                ? AppColors.rejectRed.withOpacity(0.1)
                                : AppColors.signalYellow.withOpacity(0.1),
                        border: Border(
                          left: BorderSide(
                            color: myRequestStatus == 'accepted'
                                ? AppColors.acceptGreen
                                : myRequestStatus == 'rejected'
                                    ? AppColors.rejectRed
                                    : AppColors.signalYellow,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        'Your request: ${myRequestStatus.toUpperCase()}',
                        style: AppTextStyles.label.copyWith(
                          color: myRequestStatus == 'accepted'
                              ? AppColors.acceptGreen
                              : myRequestStatus == 'rejected'
                                  ? AppColors.rejectRed
                                  : AppColors.signalYellow,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],

                // Seat request error
                if (ref.watch(seatRequestNotifierProvider).value?.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      ref.watch(seatRequestNotifierProvider).value!.error!,
                      style: AppTextStyles.label.copyWith(color: AppColors.rejectRed),
                    ),
                  ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RouteBlock extends StatelessWidget {
  final String source;
  final String dest;
  const _RouteBlock({required this.source, required this.dest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        border: Border.all(color: AppColors.borderSubtle, width: 2),
        borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.signalYellow, width: 2),
              )),
              Container(width: 2, height: 32, color: AppColors.borderSubtle),
              Container(width: 12, height: 12, decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.signalYellow,
              )),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FROM', style: AppTextStyles.labelSm.copyWith(color: AppColors.textTertiary)),
                Text(source, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Text('TO', style: AppTextStyles.labelSm.copyWith(color: AppColors.textTertiary)),
                Text(dest, style: AppTextStyles.body.copyWith(color: AppColors.signalYellow, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.signalYellow, size: 20),
        const SizedBox(width: 12),
        Text('$label  ', style: AppTextStyles.labelSm.copyWith(color: AppColors.textTertiary)),
        Expanded(
          child: Text(value, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary), textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

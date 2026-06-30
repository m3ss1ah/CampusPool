import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/cp_commute_card.dart';
import '../providers/commute_provider.dart';

class MyCommutesScreen extends ConsumerStatefulWidget {
  const MyCommutesScreen({super.key});

  @override
  ConsumerState<MyCommutesScreen> createState() => _MyCommutesScreenState();
}

class _MyCommutesScreenState extends ConsumerState<MyCommutesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myCommutesNotifierProvider.notifier).fetchMyCommutes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myCommutesNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface0,
      appBar: AppBar(
        title: const Text('MY RIDES', style: AppTextStyles.h3),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.signalYellow),
            onPressed: () => context.push('/commute/create'),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.signalYellow)),
        error: (err, stack) => Center(
          child: Text(
            'Failed to load rides\n$err',
            style: AppTextStyles.body.copyWith(color: AppColors.rejectRed),
            textAlign: TextAlign.center,
          ),
        ),
        data: (commutes) {
          if (commutes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.directions_car_outlined, size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  Text('No rides posted yet.', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.push('/commute/create'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.signalYellow,
                      foregroundColor: AppColors.systemBlack,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('OFFER A RIDE', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.signalYellow,
            backgroundColor: AppColors.surface1,
            onRefresh: () async {
              await ref.read(myCommutesNotifierProvider.notifier).fetchMyCommutes();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: commutes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final commute = commutes[index];
                final minutesUntil = commute.departureTime.difference(DateTime.now()).inMinutes;
                final timeText = minutesUntil > 0
                    ? 'Leaves in ${minutesUntil}m'
                    : 'Departed ${timeago.format(commute.departureTime)}';
                final progress = minutesUntil > 60 ? 0.0 : (1 - (minutesUntil / 60)).clamp(0.0, 1.0);

                return Opacity(
                  opacity: commute.status == 'completed' || commute.status == 'cancelled' ? 0.5 : 1.0,
                  child: CpCommuteCard(
                    routeLetter: commute.sourceLabel.isNotEmpty ? commute.sourceLabel[0].toUpperCase() : '?',
                    sourceLabel: commute.sourceLabel,
                    destLabel: commute.destLabel,
                    timeAway: commute.status == 'open' ? timeText : commute.status!.toUpperCase(),
                    availableSeats: commute.availableSeats,
                    totalSeats: commute.totalSeats,
                    vehicleType: commute.vehicleType ?? 'car',
                    progress: progress,
                    onTap: () => context.push('/commute/${commute.id}').then((_) {
                      ref.read(myCommutesNotifierProvider.notifier).fetchMyCommutes();
                    }),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

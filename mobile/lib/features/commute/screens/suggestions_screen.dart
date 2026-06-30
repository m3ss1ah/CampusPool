import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/cp_commute_card.dart';
import '../../../shared/widgets/cp_text_field.dart';
import '../../../shared/widgets/cp_transit_badge.dart';
import '../providers/match_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends ConsumerState<SuggestionsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  double _lat = AppConstants.defaultLat;
  double _lng = AppConstants.defaultLng;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
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
        _lat = position.latitude;
        _lng = position.longitude;
      }
    } catch (_) {}
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      ref.read(suggestionsNotifierProvider.notifier).clear();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 600), () {
      ref.read(suggestionsNotifierProvider.notifier).fetchSuggestions(
        lat: _lat,
        lng: _lng,
        destLabel: query.trim(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(suggestionsNotifierProvider);
    final suggestions = state.value?.matches ?? [];
    final isLoading = state.value?.isLoading ?? false;
    final error = state.value?.error;
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.surface0,
      appBar: AppBar(
        title: const Text('FIND A RIDE'),
      ),
      body: Column(
        children: [
          // Search Box
          Container(
            padding: const EdgeInsets.all(AppConstants.screenPaddingH),
            decoration: const BoxDecoration(
              color: AppColors.surface1,
              border: Border(bottom: BorderSide(color: AppColors.borderStrong, width: 2)),
            ),
            child: CpTextField(
              controller: _searchController,
              hint: 'Where to? (e.g., BKC, Andheri East)',
              prefixIcon: Icons.search,
              onChanged: _onSearchChanged,
            ),
          ),

          // Content
          Expanded(
            child: !hasQuery
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_searching, color: AppColors.textTertiary, size: 56),
                        const SizedBox(height: 16),
                        Text(
                          'Search your destination',
                          style: AppTextStyles.headline.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Our matching engine connects you\nwith rides heading your way.',
                          style: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : isLoading && suggestions.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: AppColors.signalYellow))
                    : error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(error, style: AppTextStyles.body.copyWith(color: AppColors.rejectRed)),
                            ),
                          )
                        : suggestions.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.route, color: AppColors.textTertiary, size: 56),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No rides found',
                                      style: AppTextStyles.headline.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(AppConstants.screenPaddingH),
                                itemCount: suggestions.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: AppConstants.spacingLg),
                                      child: Row(
                                        children: [
                                          Text('TOP MATCHES', style: AppTextStyles.labelLg.copyWith(
                                            color: AppColors.textPrimary, letterSpacing: 2,
                                          )),
                                          const Spacer(),
                                          CpTransitBadge(text: '${suggestions.length} Found', isActive: true),
                                        ],
                                      ),
                                    );
                                  }

                                  final commute = suggestions[index - 1];
                                  final minutesUntil = commute.departureTime.difference(DateTime.now()).inMinutes;
                                  final timeText = minutesUntil > 0
                                      ? 'Leaves in ${minutesUntil}m'
                                      : 'Departed ${timeago.format(commute.departureTime)}';
                                  final progress = minutesUntil > 60
                                      ? 0.0
                                      : (1 - (minutesUntil / 60)).clamp(0.0, 1.0);

                                  return CpCommuteCard(
                                    routeLetter: commute.destLabel.isNotEmpty
                                        ? commute.destLabel[0].toUpperCase()
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
        ],
      ),
    );
  }
}

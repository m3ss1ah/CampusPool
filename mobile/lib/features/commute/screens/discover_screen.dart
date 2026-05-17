import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/cp_commute_card.dart';
import '../../../shared/widgets/cp_empty_state.dart';
import '../../../shared/widgets/cp_transit_badge.dart';

/// Discover / Rides feed screen.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String _activeFilter = 'All';

  final List<Map<String, dynamic>> _allRides = [
    {
      'route': 'M', 'src': 'Main Library', 'dst': 'South Dorms',
      'time': 'Leaves in 4m', 'avail': 2, 'tot': 4, 'type': 'car', 'progress': 0.15
    },
    {
      'route': 'K', 'src': 'Rec Center', 'dst': 'Downtown',
      'time': 'Leaves in 12m', 'avail': 1, 'tot': 1, 'type': 'bike', 'progress': 0.45
    },
    {
      'route': 'A', 'src': 'Andheri Station', 'dst': 'Powai',
      'time': 'Leaves in 20m', 'avail': 3, 'tot': 4, 'type': 'car', 'progress': 0.8
    },
    {
      'route': 'S', 'src': 'Sports Complex', 'dst': 'Main Gate',
      'time': 'Leaves in 2m', 'avail': 5, 'tot': 7, 'type': 'suv', 'progress': 0.05
    },
  ];

  List<Map<String, dynamic>> get _filteredRides {
    if (_activeFilter == 'All') return _allRides;
    if (_activeFilter == 'Leaving Now') return _allRides.where((r) => (r['progress'] as double) < 0.2).toList();
    return _allRides.where((r) => r['type'] == _activeFilter.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rides = _filteredRides;

    return Scaffold(
      backgroundColor: AppColors.surface0,
      appBar: AppBar(
        title: const Text('DISCOVER'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.screenPaddingH),
        children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Car', 'Bike', 'Leaving Now'].map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _activeFilter = filter),
                    child: CpTransitBadge(
                      text: filter,
                      isActive: _activeFilter == filter,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppConstants.spacingXl),

          // Section header
          Row(
            children: [
              Text('AVAILABLE RIDES', style: AppTextStyles.labelLg.copyWith(
                color: AppColors.textPrimary, letterSpacing: 2,
              )),
              const Spacer(),
              Text('${rides.length} FOUND', style: AppTextStyles.labelSm),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // Cards
          if (rides.isEmpty)
            const CpEmptyState(
              icon: Icons.search_off,
              title: 'NO RIDES FOUND',
              subtitle: 'Try adjusting your filters.',
            )
          else
            ...rides.map((r) => CpCommuteCard(
              routeLetter: r['route'],
              sourceLabel: r['src'],
              destLabel: r['dst'],
              timeAway: r['time'],
              availableSeats: r['avail'],
              totalSeats: r['tot'],
              vehicleType: r['type'],
              progress: r['progress'],
              onTap: () {},
            )),
        ],
      ),
    );
  }
}

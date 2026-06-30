import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/cp_button.dart';
import '../../../shared/widgets/cp_text_field.dart';
import '../../../shared/widgets/cp_transit_badge.dart';
import '../../map/screens/location_picker_screen.dart';
import '../providers/commute_provider.dart';

/// Create Commute — "PLAN COMMUTE" screen.
class CreateCommuteScreen extends ConsumerStatefulWidget {
  const CreateCommuteScreen({super.key});

  @override
  ConsumerState<CreateCommuteScreen> createState() => _CreateCommuteScreenState();
}

class _CreateCommuteScreenState extends ConsumerState<CreateCommuteScreen> {
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  int _seats = 1;
  String _vehicleType = 'car';

  // Location data from picker
  PickedLocation? _source;
  PickedLocation? _destination;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  int _getVehicleMaxSeats(String type) {
    switch (type) {
      case 'bike': return 1;
      case 'auto': return 2;
      case 'suv': return 7;
      case 'car':
      default: return 4;
    }
  }

  void _onVehicleChanged(String type) {
    setState(() {
      _vehicleType = type;
      final maxSeats = _getVehicleMaxSeats(type);
      if (_seats > maxSeats) _seats = maxSeats;
    });
  }

  Future<void> _pickSource() async {
    final result = await context.push<PickedLocation>('/location-picker');
    if (result != null) {
      setState(() => _source = result);
    }
  }

  Future<void> _pickDestination() async {
    final result = await context.push<PickedLocation>('/location-picker');
    if (result != null) {
      setState(() => _destination = result);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _submit() async {
    // Validation
    if (_source == null) {
      _showError('Please select a source location');
      return;
    }
    if (_destination == null) {
      _showError('Please select a destination');
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      _showError('Please select date and time');
      return;
    }

    final departureTime = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _selectedTime!.hour, _selectedTime!.minute,
    );

    if (departureTime.isBefore(DateTime.now())) {
      _showError('Departure time must be in the future');
      return;
    }

    final data = {
      'source_label': _source!.label,
      'source_lat': _source!.lat,
      'source_lng': _source!.lng,
      'dest_label': _destination!.label,
      'dest_lat': _destination!.lat,
      'dest_lng': _destination!.lng,
      'departure_time': departureTime.toUtc().toIso8601String(),
      'total_seats': _seats,
      'vehicle_type': _vehicleType,
      'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
    };

    final success = await ref.read(createCommuteNotifierProvider.notifier).createCommute(data);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commute posted!'),
          backgroundColor: AppColors.acceptGreen,
        ),
      );
      context.pop();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.rejectRed),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createCommuteNotifierProvider);
    final isLoading = createState.value?.isLoading ?? false;
    final error = createState.value?.error;

    return Scaffold(
      backgroundColor: AppColors.surface0,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('CAMPUSPOOL'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.screenPaddingH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title block
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: AppColors.signalYellow,
              child: Text('PLAN', style: AppTextStyles.displayLg.copyWith(color: AppColors.systemBlack)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderSubtle, width: 2),
              ),
              child: const Text('COMMUTE', style: AppTextStyles.displayLg),
            ),
            const SizedBox(height: AppConstants.spacing3xl),

            // Error
            if (error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.rejectRed.withOpacity(0.1),
                  border: const Border(left: BorderSide(color: AppColors.rejectRed, width: 3)),
                ),
                child: Text(error, style: AppTextStyles.label.copyWith(color: AppColors.rejectRed)),
              ),

            // Route section
            const CpTransitBadge(text: 'Route', isActive: true),
            const SizedBox(height: AppConstants.spacingMd),

            // Source picker
            _LocationPickerTile(
              icon: Icons.my_location,
              label: '⦿ Origin',
              value: _source?.label,
              onTap: _pickSource,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            // Destination picker
            _LocationPickerTile(
              icon: Icons.place,
              label: '◉ Destination',
              value: _destination?.label,
              onTap: _pickDestination,
            ),
            const SizedBox(height: AppConstants.spacing3xl),

            // Time section
            const CpTransitBadge(text: 'Time', isActive: true),
            const SizedBox(height: AppConstants.spacingMd),
            Row(
              children: [
                Expanded(
                  child: CpTextField(
                    controller: _dateController,
                    label: '⊞ Date',
                    hint: 'Select Date',
                    prefixIcon: Icons.calendar_today,
                    readOnly: true,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CpTextField(
                    controller: _timeController,
                    label: '⊕ Departure Time',
                    hint: '--:--',
                    prefixIcon: Icons.schedule,
                    readOnly: true,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacing3xl),

            // Seats & Vehicle
            const CpTransitBadge(text: 'Seats', isActive: true),
            const SizedBox(height: AppConstants.spacingMd),
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() { if (_seats > 1) _seats--; }),
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary),
                ),
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderSubtle, width: 2),
                    borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
                  ),
                  child: Center(child: Text('$_seats', style: AppTextStyles.headline)),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    if (_seats < _getVehicleMaxSeats(_vehicleType)) _seats++;
                  }),
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.signalYellow),
                ),
                const Spacer(),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: ['bike', 'auto', 'car', 'suv'].map((type) {
                        final isSelected = _vehicleType == type;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: GestureDetector(
                            onTap: () => _onVehicleChanged(type),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.signalYellow : AppColors.surface2,
                                borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
                                border: Border.all(
                                  color: isSelected ? AppColors.signalYellow : AppColors.borderSubtle,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                type == 'car' ? Icons.directions_car
                                  : type == 'bike' ? Icons.two_wheeler
                                  : type == 'suv' ? Icons.airport_shuttle
                                  : Icons.electric_rickshaw,
                                color: isSelected ? AppColors.systemBlack : AppColors.textSecondary,
                                size: 20,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacing3xl),

            // Notes
            CpTextField(
              controller: _notesController,
              label: 'Notes (optional)',
              hint: 'AC car, will wait 5 mins...',
              prefixIcon: Icons.note_alt_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: AppConstants.spacing4xl),

            CpButton(
              label: 'Post Commute →',
              isLoading: isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppConstants.spacing3xl),
          ],
        ),
      ),
    );
  }
}

/// Tile for picking a location — displays label or placeholder.
class _LocationPickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _LocationPickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          border: Border.all(color: AppColors.borderSubtle, width: 2),
          borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
        ),
        child: Row(
          children: [
            Icon(icon, color: value != null ? AppColors.signalYellow : AppColors.textTertiary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.labelSm.copyWith(color: AppColors.textTertiary)),
                  const SizedBox(height: 2),
                  Text(
                    value ?? 'Tap to pick on map',
                    style: AppTextStyles.body.copyWith(
                      color: value != null ? AppColors.textPrimary : AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.map, color: AppColors.signalYellow, size: 20),
          ],
        ),
      ),
    );
  }
}

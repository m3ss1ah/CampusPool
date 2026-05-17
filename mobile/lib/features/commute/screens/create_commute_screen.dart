import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/cp_button.dart';
import '../../../shared/widgets/cp_text_field.dart';
import '../../../shared/widgets/cp_transit_badge.dart';

/// Create Commute — "PLAN COMMUTE" screen.
class CreateCommuteScreen extends StatefulWidget {
  const CreateCommuteScreen({super.key});

  @override
  State<CreateCommuteScreen> createState() => _CreateCommuteScreenState();
}

class _CreateCommuteScreenState extends State<CreateCommuteScreen> {
  final _originController = TextEditingController();
  final _destController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  int _seats = 1;
  String _vehicleType = 'car';

  static const List<String> _campusLocations = [
    'Main Lib', 'South Dorms', 'Rec Center', 'Downtown',
    'Andheri Stn', 'Powai', 'Engineering Block', 'Cafeteria',
    'Main Gate', 'Sports Complex', 'Science Lab'
  ];

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
      if (_seats > maxSeats) {
        _seats = maxSeats;
      }
    });
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
        _timeController.text = picked.format(context);
      });
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              child: Text('COMMUTE', style: AppTextStyles.displayLg),
            ),
            const SizedBox(height: AppConstants.spacing3xl),

            // Route section
            const CpTransitBadge(text: 'Route', isActive: true),
            const SizedBox(height: AppConstants.spacingMd),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') return const Iterable<String>.empty();
                return _campusLocations.where((String option) => 
                  option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selection) => _originController.text = selection,
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return CpTextField(
                  controller: controller,
                  focusNode: focusNode,
                  label: '⦿ Origin',
                  hint: 'Search origin...',
                  prefixIcon: Icons.my_location,
                );
              },
              optionsViewBuilder: (context, onSelected, options) => _AutocompleteOptions(
                options: options,
                onSelected: onSelected,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') return const Iterable<String>.empty();
                return _campusLocations.where((String option) => 
                  option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selection) => _destController.text = selection,
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return CpTextField(
                  controller: controller,
                  focusNode: focusNode,
                  label: '◉ Destination',
                  hint: 'Search destination...',
                  prefixIcon: Icons.place,
                );
              },
              optionsViewBuilder: (context, onSelected, options) => _AutocompleteOptions(
                options: options,
                onSelected: onSelected,
              ),
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

            // Seats
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
                  child: Center(
                    child: Text('$_seats', style: AppTextStyles.headline),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    if (_seats < _getVehicleMaxSeats(_vehicleType)) _seats++;
                  }),
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.signalYellow),
                ),
                const Spacer(),
                // Vehicle type selector
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
            const SizedBox(height: AppConstants.spacing4xl),

            CpButton(
              label: 'Post Commute →',
              onPressed: () {
                // TODO: wire to provider
                context.pop();
              },
            ),
            const SizedBox(height: AppConstants.spacing3xl),
          ],
        ),
      ),
    );
  }
}

class _AutocompleteOptions extends StatelessWidget {
  final Iterable<String> options;
  final AutocompleteOnSelected<String> onSelected;

  const _AutocompleteOptions({
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width - (AppConstants.screenPaddingH * 2),
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            border: Border.all(color: AppColors.signalYellow, width: 2),
            borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options.elementAt(index);
                return InkWell(
                  onTap: () => onSelected(option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      option,
                      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

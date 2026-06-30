import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/coordinate_utils.dart';
import '../../../shared/widgets/cp_button.dart';

/// Location data returned from the picker.
class PickedLocation {
  final double lat;
  final double lng;
  final String label;

  const PickedLocation({required this.lat, required this.lng, required this.label});
}

/// Full-screen map with centered crosshair for location picking.
/// Debounces reverse geocoding on map movement.
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String title;

  const LocationPickerScreen({
    super.key,
    this.initialLocation,
    this.title = 'Pick Location',
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  
  String _label = 'Move map to select location';
  bool _isGeocoding = false;
  Timer? _debounceTimer;
  late LatLng _center;

  // Search
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _center = widget.initialLocation ??
        const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapMoved(MapPosition position, bool hasGesture) {
    if (!hasGesture) return;
    setState(() {
      _center = position.center!;
    });

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _reverseGeocode(_center);
    });
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _isGeocoding = true);
    final label = await CoordinateUtils.reverseGeocode(point.latitude, point.longitude);
    if (mounted) {
      setState(() {
        _label = label;
        _isGeocoding = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults.clear());
      return;
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      try {
        final res = await Dio().get(
          'https://nominatim.openstreetmap.org/search',
          queryParameters: {'q': query, 'format': 'json', 'limit': 5},
          options: Options(headers: {'User-Agent': 'CampusPoolApp/1.0'}),
        );
        if (mounted) setState(() => _searchResults = res.data as List);
      } catch (e) {
        // ignore
      }
      if (mounted) setState(() => _isSearching = false);
    });
  }

  void _onResultSelected(dynamic result) {
    FocusScope.of(context).unfocus();
    final lat = double.parse(result['lat'].toString());
    final lon = double.parse(result['lon'].toString());
    final point = LatLng(lat, lon);
    
    setState(() {
      _searchResults.clear();
      _searchController.text = result['display_name'].toString().split(',')[0];
      _center = point;
      _label = result['display_name'];
    });
    
    _mapController.move(point, 16);
  }

  void _confirm() {
    context.pop(PickedLocation(
      lat: _center.latitude,
      lng: _center.longitude,
      label: _label,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface0,
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 16,
              maxZoom: 18,
              minZoom: 10,
              onPositionChanged: (camera, hasGesture) => _onMapMoved(camera, hasGesture),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.campuspool.campuspool',
              ),
            ],
          ),

          // Centered crosshair
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.signalYellow,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.place, color: AppColors.systemBlack, size: 28),
                ),
                Container(
                  width: 2,
                  height: 20,
                  color: AppColors.signalYellow.withOpacity(0.6),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.signalYellow.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),

          // Top Search Bar & Results
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16, right: 16, bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surface0.withOpacity(0.9),
                    AppColors.surface0.withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: AppColors.surface1,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                          onPressed: () => context.pop(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: AppTextStyles.body,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search location...',
                            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
                            filled: true,
                            fillColor: AppColors.surface1,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                            suffixIcon: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.signalYellow),
                                  )
                                : const Icon(Icons.search, color: AppColors.textTertiary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8, left: 48),
                      decoration: BoxDecoration(
                        color: AppColors.surface1,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                            title: Text(
                              result['display_name'],
                              style: AppTextStyles.labelSm,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _onResultSelected(result),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom panel — label + confirm
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: AppConstants.screenPaddingH,
                right: AppConstants.screenPaddingH,
                top: 20,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.radiusSheet)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, -4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.signalYellow, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _isGeocoding
                            ? Text('Identifying location...', style: AppTextStyles.body.copyWith(color: AppColors.textTertiary))
                            : Text(
                                _label,
                                style: AppTextStyles.body.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Coordinates
                  Text(
                    '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}',
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.textTertiary, fontFamily: 'SpaceMono'),
                  ),
                  const SizedBox(height: 16),
                  CpButton(
                    label: 'Confirm Location',
                    icon: Icons.check,
                    onPressed: _confirm,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

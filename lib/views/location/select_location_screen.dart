import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../consts/appConst.dart';
import '../../data/repositories/rides_repository.dart';
import '../courier_service/package_details_screen.dart';
import '../custom_navbar/navbar.dart';
import '../driver_screens/driver_details_screen.dart';
import 'nearby_driver_model.dart';
import 'ride_fare_screen.dart';

enum _LocationSelectionMode { pickup, destination }

class SelectLocationScreen extends StatefulWidget {
  final bool isCourierService;

  const SelectLocationScreen({super.key, this.isCourierService = false});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  static const String _googleApiKey = 'AIzaSyDuAloVADiL2L-pa1Dg7OIkjPLl-lAE6eA';
  GoogleMapController? _mapController;
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(24.8607, 67.0011),
    zoom: 12,
  );
  bool _isLoadingLocation = true;

  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;
  _LocationSelectionMode _selectionMode = _LocationSelectionMode.pickup;

  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _pickupFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();

  Timer? _searchDebounce;
  List<_PlaceSuggestion> _searchSuggestions = [];
  bool _isFetchingSuggestions = false;
  bool _isApplyingSuggestion = false;
  final RidesRepository _ridesRepository = RidesRepository();
  bool _isCheckingActiveRide = false;
  bool _didCheckActiveRide = false;

  @override
  void initState() {
    super.initState();
    _pickupFocusNode.addListener(() {
      if (_pickupFocusNode.hasFocus &&
          _selectionMode != _LocationSelectionMode.pickup) {
        setState(() => _selectionMode = _LocationSelectionMode.pickup);
      }
    });
    _destinationFocusNode.addListener(() {
      if (_destinationFocusNode.hasFocus &&
          _selectionMode != _LocationSelectionMode.destination) {
        setState(() => _selectionMode = _LocationSelectionMode.destination);
      }
    });
    _initLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only check for an active ride when this screen
      // is being used for standard ride flow, not courier.
      if (!widget.isCourierService) {
        _checkActiveRide();
      }
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _pickupController.dispose();
    _destinationController.dispose();
    _pickupFocusNode.dispose();
    _destinationFocusNode.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  double? _tryParseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  Future<void> _checkActiveRide() async {
    if (_didCheckActiveRide) return;
    _didCheckActiveRide = true;

    setState(() {
      _isCheckingActiveRide = true;
    });

    try {
      final resp = await _ridesRepository.getActiveRide();

      // ignore: avoid_print
      print('SelectLocationScreen rides/active response: $resp');

      if (!mounted) return;

      if (resp['status'] == true && resp['data'] is Map<String, dynamic>) {
        final data = resp['data'] as Map<String, dynamic>;
        final serviceType = (data['service_type'] as String?)?.trim() ?? 'ride';

        final pickupAddress = (data['pickup_address'] as String?)?.trim() ?? '';
        final dropoffAddress =
            (data['dropoff_address'] as String?)?.trim() ?? '';

        final pickupLat = _tryParseDouble(data['pickup_lat']);
        final pickupLng = _tryParseDouble(data['pickup_lng']);
        final dropLat = _tryParseDouble(data['dropoff_lat']);
        final dropLng = _tryParseDouble(data['dropoff_lng']);

        final paymentMethod =
            (data['payment_method'] as String?)?.trim() ?? 'Cash';
        final fareRaw = data['fare'];
        final fare = (fareRaw is num) ? fareRaw : num.tryParse('$fareRaw');

        // Map driver data into NearbyDriver for DriverDetailsScreen.
        final driverObj = data['driver'];
        NearbyDriver? driver;
        if (driverObj is Map<String, dynamic>) {
          final driverId = (driverObj['id'] as num?)?.toInt() ?? 0;
          final driverName =
              (driverObj['name'] as String?)?.trim() ??
              (driverObj['driver_id']?.toString() ?? 'Driver');
          final driverRating = driverObj['rating']?.toString() ?? '0.0';
          final vehicle =
              (driverObj['vehicle_model'] as String?) ??
              (driverObj['vehicle'] as String?) ??
              (driverObj['type_id'] != null
                  ? 'Type ${driverObj['type_id']}'
                  : null);

          final imageUrl =
              (driverObj['image_url'] as String?) ??
              (driverObj['image'] as String?);

          driver = NearbyDriver(
            id: driverId,
            name: driverName.isNotEmpty ? driverName : 'Driver',
            rating: driverRating,
            vehicle: vehicle,
            photo: imageUrl,
            eta: '',
            distance: '',
          );
        }

        final rideIdNum = (data['id'] as num?)?.toInt();

        final args = <String, dynamic>{
          'driver': driver,
          'pickup_address': pickupAddress,
          'pickup_lat': pickupLat,
          'pickup_lng': pickupLng,
          'dropoff_address': dropoffAddress,
          'dropoff_lat': dropLat,
          'dropoff_lng': dropLng,
          'payment_method': paymentMethod,
          'fare': fare,
          'ride_type': serviceType == 'ride' ? 'Ride' : serviceType,
          // keep cancel working (DriverDetailsScreen reads ride_request.data.id)
          'ride_request': {
            'data': {if (rideIdNum != null) 'id': rideIdNum},
          },
        };

        Get.off(
          () => DriverDetailsScreen(isCourierService: serviceType != 'ride'),
          arguments: args,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('SelectLocationScreen _checkActiveRide error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingActiveRide = false;
        });
      }
    }
  }

  Future<void> _initLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final current = LatLng(position.latitude, position.longitude);
        setState(() {
          _initialCameraPosition = CameraPosition(target: current, zoom: 14.0);
          _isLoadingLocation = false;
        });
        await _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(_initialCameraPosition),
        );
        // Auto-fill pickup with current location on first load.
        if (_pickupLatLng == null && _pickupController.text.trim().isEmpty) {
          await _applySelectedPosition(
            mode: _LocationSelectionMode.pickup,
            position: current,
          );
        }
      } else {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('SelectLocationScreen _initLocation error: $e');
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final current = LatLng(position.latitude, position.longitude);
        await _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: current, zoom: 15.0),
          ),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('SelectLocationScreen _goToCurrentLocation error: $e');
    }
  }

  Future<void> _onMapTap(LatLng position) async {
    final mode = _destinationFocusNode.hasFocus
        ? _LocationSelectionMode.destination
        : _pickupFocusNode.hasFocus
        ? _LocationSelectionMode.pickup
        : _selectionMode;
    await _applySelectedPosition(mode: mode, position: position);
  }

  Set<Marker> get _markers {
    final markers = <Marker>{};
    if (_pickupLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          infoWindow: InfoWindow(title: 'common.pickup'.tr),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }
    if (_destinationLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLatLng!,
          infoWindow: InfoWindow(title: 'common.destination'.tr),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    return markers;
  }

  bool get _canContinue => _pickupLatLng != null && _destinationLatLng != null;

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _fetchSearchSuggestions(value);
    });
  }

  void _onPickupChanged(String value) {
    if (_selectionMode != _LocationSelectionMode.pickup) {
      setState(() => _selectionMode = _LocationSelectionMode.pickup);
    }
    if (!_pickupFocusNode.hasFocus) _pickupFocusNode.requestFocus();
    _onSearchChanged(value);
  }

  void _onDestinationChanged(String value) {
    if (_selectionMode != _LocationSelectionMode.destination) {
      setState(() => _selectionMode = _LocationSelectionMode.destination);
    }
    if (!_destinationFocusNode.hasFocus) _destinationFocusNode.requestFocus();
    _onSearchChanged(value);
  }

  Future<void> _fetchSearchSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _searchSuggestions = [];
        _isFetchingSuggestions = false;
      });
      return;
    }

    try {
      if (mounted) {
        setState(() => _isFetchingSuggestions = true);
      }
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(trimmed)}'
        '&key=$_googleApiKey',
      );

      final response = await http.get(uri);
      if (response.statusCode != 200 && response.statusCode != 201) {
        // ignore: avoid_print
        print(
          'SelectLocationScreen _fetchSearchSuggestions error: '
          'statusCode=${response.statusCode}, body=${response.body}',
        );
        return;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['status'] != 'OK') {
        // ignore: avoid_print
        print(
          'SelectLocationScreen _fetchSearchSuggestions API status: '
          '${decoded['status']} - ${decoded['error_message']}',
        );
        return;
      }

      final preds = decoded['predictions'] as List<dynamic>? ?? [];
      final suggestions = preds
          .whereType<Map<String, dynamic>>()
          .map(
            (p) => _PlaceSuggestion(
              description: p['description'] as String? ?? '',
              placeId: p['place_id'] as String? ?? '',
            ),
          )
          .where((s) => s.description.isNotEmpty && s.placeId.isNotEmpty)
          .toList();

      setState(() {
        _searchSuggestions = suggestions;
      });
    } catch (e) {
      // ignore: avoid_print
      print('SelectLocationScreen _fetchSearchSuggestions exception: $e');
    } finally {
      if (mounted) {
        setState(() => _isFetchingSuggestions = false);
      }
    }
  }

  Future<void> _searchLocationByName(
    String query,
    _LocationSelectionMode mode,
  ) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    try {
      final locations = await locationFromAddress(trimmed);
      if (locations.isEmpty) {
        // ignore: avoid_print
        print(
          'SelectLocationScreen _searchLocationByName: '
          'no results for "$trimmed"',
        );
        return;
      }

      final loc = locations.first;
      final position = LatLng(loc.latitude, loc.longitude);
      await _applySelectedPosition(mode: mode, position: position);
    } catch (e) {
      // ignore: avoid_print
      print('SelectLocationScreen _searchLocationByName error: $e');
    }
  }

  Future<void> _searchLocationBySuggestion(
    _PlaceSuggestion suggestion,
    _LocationSelectionMode mode,
  ) async {
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${Uri.encodeComponent(suggestion.placeId)}'
        '&fields=geometry/location'
        '&key=$_googleApiKey',
      );

      final response = await http.get(uri);
      if (response.statusCode != 200 && response.statusCode != 201) {
        // ignore: avoid_print
        print(
          'SelectLocationScreen _searchLocationBySuggestion HTTP error: '
          'statusCode=${response.statusCode}, body=${response.body}',
        );
        await _searchLocationByName(suggestion.description, mode);
        return;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final result = decoded['result'] as Map<String, dynamic>?;
      final geometry = result?['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      final lat = (location?['lat'] as num?)?.toDouble();
      final lng = (location?['lng'] as num?)?.toDouble();

      if (lat == null || lng == null) {
        // ignore: avoid_print
        print(
          'SelectLocationScreen _searchLocationBySuggestion: '
          'missing geometry for placeId=${suggestion.placeId}',
        );
        await _searchLocationByName(suggestion.description, mode);
        return;
      }

      await _applySelectedPosition(mode: mode, position: LatLng(lat, lng));
    } catch (e) {
      // ignore: avoid_print
      print('SelectLocationScreen _searchLocationBySuggestion error: $e');
      await _searchLocationByName(suggestion.description, mode);
    }
  }

  Future<void> _applySelectedPosition({
    required _LocationSelectionMode mode,
    required LatLng position,
  }) async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 15.0),
      ),
    );

    String label;
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final street = (p.street?.isNotEmpty == true)
            ? p.street
            : (p.name?.isNotEmpty == true ? p.name : null);
        final city = p.locality;
        final state = p.administrativeArea;
        final country = p.country;

        final parts = <String>[];
        if (street != null && street.isNotEmpty) {
          parts.add(street);
        }
        if (city != null && city.isNotEmpty && !parts.contains(city)) {
          parts.add(city);
        }
        if (state != null && state.isNotEmpty && !parts.contains(state)) {
          parts.add(state);
        }
        if (country != null && country.isNotEmpty && !parts.contains(country)) {
          parts.add(country);
        }

        if (parts.length > 3) {
          label = parts.sublist(0, 3).join(', ');
        } else if (parts.isNotEmpty) {
          label = parts.join(', ');
        } else {
          label =
              '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        }
      } else {
        label =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }
    } catch (e) {
      // ignore: avoid_print
      print(
        'SelectLocationScreen _applySelectedPosition reverse geocode error: $e',
      );
      label =
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    }

    setState(() {
      if (mode == _LocationSelectionMode.pickup) {
        _pickupLatLng = position;
        _pickupController.text = label;
        _selectionMode = _LocationSelectionMode.pickup;
      } else {
        _destinationLatLng = position;
        _destinationController.text = label;
        _selectionMode = _LocationSelectionMode.destination;
      }
      _searchSuggestions = [];
    });

    if (mode == _LocationSelectionMode.pickup && !_pickupFocusNode.hasFocus) {
      _pickupFocusNode.requestFocus();
    } else if (mode == _LocationSelectionMode.destination &&
        !_destinationFocusNode.hasFocus) {
      _destinationFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _initialCameraPosition,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  onMapCreated: (controller) => _mapController = controller,
                  markers: _markers,
                  onTap: _onMapTap,
                ),
                if (_isLoadingLocation)
                  const Center(child: CircularProgressIndicator()),
                Positioned(
                  bottom: 20.h,
                  right: 20.w,
                  child: GestureDetector(
                    onTap: _goToCurrentLocation,
                    child: Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        color: AppConst.black,
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppConst.blackWithOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.near_me,
                        color: AppConst.white,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildBottomSheet(),
                ),
                if (_isCheckingActiveRide)
                  Positioned.fill(
                    child: Container(
                      color: AppConst.background.withValues(alpha: 0.85),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            SizedBox(height: 12.h),
                            Text(
                              'location.checking_active_ride'.tr,
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppConst.black),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10.h,
        bottom: 16.h,
        left: 20.w,
        right: 20.w,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Get.offAll(() => const Navbar());
                  }
                },
                child: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.arrow_forward
                      : Icons.arrow_back,
                  color: AppConst.white,
                  size: 24.sp,
                ),
              ),
              Text(
                'location.select_title'.tr,
                style: TextStyle(
                  color: AppConst.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.settings, color: AppConst.white, size: 24.sp),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions({required _LocationSelectionMode mode}) {
    return Container(
      width: double.infinity,
      color: AppConst.cardLight,
      child: ListView.separated(
        itemCount: _searchSuggestions.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: AppConst.grey.withValues(alpha: 0.2)),
        itemBuilder: (context, index) {
          final suggestion = _searchSuggestions[index];
          return ListTile(
            dense: true,
            leading: Icon(
              Icons.location_on,
              color: AppConst.black,
              size: 20.sp,
            ),
            title: Text(
              suggestion.description,
              style: TextStyle(color: AppConst.black, fontSize: 14.sp),
            ),
            onTap: () async {
              setState(() => _isApplyingSuggestion = true);
              try {
                await _searchLocationBySuggestion(suggestion, mode);
              } finally {
                if (mounted) {
                  setState(() => _isApplyingSuggestion = false);
                }
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildInlineSuggestions(_LocationSelectionMode mode) {
    if (_searchSuggestions.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      constraints: BoxConstraints(maxHeight: 180.h),
      decoration: BoxDecoration(
        color: AppConst.cardLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppConst.grey.withValues(alpha: 0.25)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: _buildSearchSuggestions(mode: mode),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: AppConst.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppConst.blackWithOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppConst.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 16.h,
                bottom: 16.h,
              ),
              child: Column(
                children: [
                  _buildLocationInput(
                    label: 'ride.pickup_location'.tr,
                    controller: _pickupController,
                    isActive: _selectionMode == _LocationSelectionMode.pickup,
                    onTap: () {
                      setState(
                        () => _selectionMode = _LocationSelectionMode.pickup,
                      );
                      _pickupFocusNode.requestFocus();
                    },
                    focusNode: _pickupFocusNode,
                    onChanged: _onPickupChanged,
                  ),
                  if (_selectionMode == _LocationSelectionMode.pickup)
                    _buildInlineSuggestions(_LocationSelectionMode.pickup),
                  SizedBox(height: 12.h),
                  _buildLocationInput(
                    label: 'common.destination'.tr,
                    controller: _destinationController,
                    isActive:
                        _selectionMode == _LocationSelectionMode.destination,
                    onTap: () {
                      setState(
                        () =>
                            _selectionMode = _LocationSelectionMode.destination,
                      );
                      _destinationFocusNode.requestFocus();
                    },
                    focusNode: _destinationFocusNode,
                    onChanged: _onDestinationChanged,
                  ),
                  if (_selectionMode == _LocationSelectionMode.destination)
                    _buildInlineSuggestions(_LocationSelectionMode.destination),
                  SizedBox(height: 12.h),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectionMode =
                            _selectionMode == _LocationSelectionMode.pickup
                            ? _LocationSelectionMode.destination
                            : _LocationSelectionMode.pickup;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppConst.black,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          _selectionMode == _LocationSelectionMode.pickup
                              ? 'location.tap_set_pickup'.tr
                              : 'location.tap_set_destination'.tr,
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  GestureDetector(
                    onTap: _canContinue
                        ? () {
                            final args = {
                              'pickup': _pickupLatLng,
                              'destination': _destinationLatLng,
                              'pickupLabel': _pickupController.text,
                              'destinationLabel': _destinationController.text,
                            };
                            if (widget.isCourierService) {
                              Get.to(
                                () => const PackageDetailsScreen(),
                                arguments: args,
                              );
                            } else {
                              Get.to(
                                () => const RideFareScreen(),
                                arguments: args,
                              );
                            }
                          }
                        : null,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        color: _canContinue
                            ? AppConst.accent
                            : AppConst.accentWithOpacity(0.5),
                        borderRadius: AppConst.buttonRadius,
                      ),
                      child: Center(
                        child: Text(
                          'location.find_rides'.tr,
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInput({
    required String label,
    required TextEditingController controller,
    required bool isActive,
    required VoidCallback onTap,
    required FocusNode focusNode,
    required ValueChanged<String> onChanged,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: AppConst.cardLight,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isActive ? AppConst.black : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.place, color: AppConst.grey, size: 24.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: label,
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppConst.grey, fontSize: 14.sp),
                ),
                style: TextStyle(
                  color: AppConst.black,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isActive && (_isFetchingSuggestions || _isApplyingSuggestion))
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
                child: SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppConst.black,
                  ),
                ),
              )
            else if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  controller.clear();
                  setState(() {
                    _searchSuggestions = [];
                    _isFetchingSuggestions = false;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 10.h,
                  ),
                  child: Icon(Icons.close, color: AppConst.grey, size: 18.sp),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaceSuggestion {
  const _PlaceSuggestion({required this.description, required this.placeId});

  final String description;
  final String placeId;
}

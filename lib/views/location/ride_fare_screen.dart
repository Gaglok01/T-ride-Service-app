import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../consts/appConst.dart';
import '../../core/config/api_urls.dart';
import '../../data/firestore/active_rides_firestore_service.dart';
import '../../data/local/secure_storage_service.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/rides_repository.dart';
import '../../widgets/app_snackbar.dart';
import '../driver_screens/driver_details_screen.dart';
import 'nearby_driver_model.dart';

/// After pickup/destination on [SelectLocationScreen], shows fare + payment and
/// auto-assigns the first nearby driver on confirm (no manual driver pick).
class RideFareScreen extends StatefulWidget {
  const RideFareScreen({super.key});

  @override
  State<RideFareScreen> createState() => _RideFareScreenState();
}

class _RideFareScreenState extends State<RideFareScreen> {
  static const String _googleApiKey = 'AIzaSyDuAloVADiL2L-pa1Dg7OIkjPLl-lAE6eA';

  final SecureStorageService _storageService = SecureStorageService();
  final ProfileRepository _profileRepository = ProfileRepository();
  final RidesRepository _ridesRepository = RidesRepository();

  GoogleMapController? _mapController;
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(24.8607, 67.0011),
    zoom: 12,
  );
  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;
  String? _pickupLabel;
  String? _destinationLabel;
  Polyline? _routePolyline;
  bool _isLoadingRoute = false;

  UserProfile? _riderProfile;
  bool _isLoadingProfile = true;

  bool _isLoadingFare = false;
  String? _estimatedFareText;
  num? _estimatedFareValue;

  bool _isLoadingDrivers = true;
  NearbyDriver? _assignedDriver;
  Timer? _driverPollTimer;
  int _driverPollTicks = 0;
  static const int _maxDriverPollTicks = 18;

  String _paymentMethod = 'Cash';
  final TextEditingController _tipController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();
  bool _isRequestingRide = false;

  @override
  void initState() {
    super.initState();
    _initFromArguments();
    _loadRiderProfile();
    _startDriverPolling();
  }

  @override
  void dispose() {
    _driverPollTimer?.cancel();
    _promoController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _initFromArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      _pickupLatLng = args['pickup'] as LatLng?;
      _destinationLatLng = args['destination'] as LatLng?;
      _pickupLabel = args['pickupLabel'] as String?;
      _destinationLabel = args['destinationLabel'] as String?;
      if (_pickupLatLng != null) {
        _initialCameraPosition = CameraPosition(
          target: _pickupLatLng!,
          zoom: 14,
        );
      }
    }
    if (_pickupLatLng != null && _destinationLatLng != null) {
      _fetchRoute();
      _fetchFareEstimate();
      _fetchNearbyDrivers();
    } else {
      setState(() {
        _isLoadingDrivers = false;
        _isLoadingFare = false;
      });
    }
  }

  void _startDriverPolling() {
    _driverPollTimer?.cancel();
    _driverPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (_assignedDriver != null) return;
      if (_driverPollTicks >= _maxDriverPollTicks) return;
      _driverPollTicks++;
      if (_pickupLatLng != null) {
        _fetchNearbyDrivers(silent: true);
      }
    });
  }

  Future<void> _loadRiderProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      final p = await _profileRepository.getProfile();
      if (mounted) setState(() => _riderProfile = p);
    } catch (_) {
      if (mounted) setState(() => _riderProfile = null);
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  String? _resolvePhotoUrl(String? path) {
    if (path == null) return null;
    final v = path.trim();
    if (v.isEmpty) return null;
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    final cleaned = v.startsWith('/') ? v.substring(1) : v;
    return '${ApiUrls.baseUrl}$cleaned';
  }

  String _riderInitials(UserProfile? p) {
    final n = p?.name?.trim() ?? '';
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return n[0].toUpperCase();
  }

  Future<void> _fetchRoute() async {
    if (_pickupLatLng == null || _destinationLatLng == null) return;
    setState(() => _isLoadingRoute = true);
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${_pickupLatLng!.latitude},${_pickupLatLng!.longitude}'
      '&destination=${_destinationLatLng!.latitude},${_destinationLatLng!.longitude}'
      '&mode=driving&key=$_googleApiKey',
    );
    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] == 'OK') {
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final overviewPolyline =
              (routes.first as Map<String, dynamic>)['overview_polyline']
                  as Map<String, dynamic>?;
          final encoded = overviewPolyline?['points'] as String?;
          if (encoded != null) {
            final points = _decodePolyline(encoded);
            if (mounted) {
              setState(() {
                _routePolyline = Polyline(
                  polylineId: const PolylineId('route'),
                  points: points,
                  width: 4,
                  color: Colors.blue,
                );
              });
            }
          }
        }
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;
    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  Future<void> _fetchFareEstimate() async {
    if (_pickupLatLng == null || _destinationLatLng == null) return;
    setState(() => _isLoadingFare = true);
    try {
      final token = await _storageService.getAuthToken();
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
      final uri = Uri.parse('${ApiUrls.baseUrl}${ApiUrls.ridesEstimate}');
      final body = jsonEncode({
        'pickup_lat': _pickupLatLng!.latitude,
        'pickup_lng': _pickupLatLng!.longitude,
        'dropoff_lat': _destinationLatLng!.latitude,
        'dropoff_lng': _destinationLatLng!.longitude,
      });
      final response = await http.post(uri, headers: headers, body: body);
      if (response.statusCode != 200 && response.statusCode != 201) return;
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['status'] != true) return;
      final dataList = decoded['data'] as List<dynamic>?;
      if (dataList == null || dataList.isEmpty) return;
      final first = dataList.first as Map<String, dynamic>;
      final fare = first['fare'];
      if (fare is num && mounted) {
        setState(() {
          _estimatedFareText = '\$ ${fare.toDouble().toStringAsFixed(2)}';
          _estimatedFareValue = fare;
        });
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoadingFare = false);
    }
  }

  Future<void> _fetchNearbyDrivers({bool silent = false}) async {
    if (_pickupLatLng == null) return;
    if (!silent) setState(() => _isLoadingDrivers = true);
    try {
      final token = await _storageService.getAuthToken();
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
      final uri = Uri.parse('${ApiUrls.baseUrl}${ApiUrls.ridesNearbyDrivers}');
      final body = jsonEncode({
        'pickup_lat': _pickupLatLng!.latitude,
        'pickup_lng': _pickupLatLng!.longitude,
      });
      final response = await http.post(uri, headers: headers, body: body);
      if (response.statusCode != 200 && response.statusCode != 201) return;
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['status'] != true) return;
      final dataList = decoded['data'] as List<dynamic>? ?? [];
      final drivers = dataList
          .whereType<Map<String, dynamic>>()
          .map(NearbyDriver.fromJson)
          .where((d) => d.id > 0)
          .toList();
      if (!mounted) return;
      setState(() {
        _assignedDriver ??= drivers.isNotEmpty ? drivers.first : null;
      });
      if (_assignedDriver != null) {
        _driverPollTimer?.cancel();
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted && !silent) setState(() => _isLoadingDrivers = false);
    }
  }

  num _toNum(dynamic value, {required num fallback}) {
    if (value is num) return value;
    return num.tryParse('$value') ?? fallback;
  }

  /// Parsed tip from the tip field; empty or invalid → 0; negative clamped to 0.
  num _parseTipAmount() {
    final t = _tipController.text.trim();
    if (t.isEmpty) return 0;
    final n = num.tryParse(t) ?? 0;
    return n < 0 ? 0 : n;
  }

  num _extractDiscountedFare(Map<String, dynamic> decoded, num originalFare) {
    num? fromFareMap(Map<String, dynamic> m) {
      if (m['discounted_fare'] != null) {
        return _toNum(m['discounted_fare'], fallback: originalFare);
      }
      if (m['final_fare'] != null) {
        return _toNum(m['final_fare'], fallback: originalFare);
      }
      if (m['fare'] != null) return _toNum(m['fare'], fallback: originalFare);
      if (m['discount_amount'] != null) {
        final discount = _toNum(m['discount_amount'], fallback: 0);
        return (originalFare - discount).clamp(0, originalFare);
      }
      if (m['discount'] != null) {
        final discount = _toNum(m['discount'], fallback: 0);
        return (originalFare - discount).clamp(0, originalFare);
      }
      return null;
    }

    final rawData = decoded['data'];
    if (rawData is Map) {
      final fromData = fromFareMap(Map<String, dynamic>.from(rawData));
      if (fromData != null) return fromData;
    }
    final fromRoot = fromFareMap(decoded);
    if (fromRoot != null) return fromRoot;
    return originalFare;
  }

  Future<num?> _applyCouponIfAny(num fare) async {
    final couponCode = _promoController.text.trim();
    if (couponCode.isEmpty) return fare;
    final token = await _storageService.getAuthToken();
    final uri = Uri.parse('${ApiUrls.baseUrl}${ApiUrls.couponApply}');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({'coupon_code': couponCode, 'fare': fare});
    try {
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 8));
      Map<String, dynamic>? decoded;
      final bodyTrim = response.body.trim();
      if (bodyTrim.startsWith('{')) {
        try {
          decoded = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
      }
      if (response.statusCode != 200 && response.statusCode != 201) {
        AppSnackBar.show(
          'food.coupon'.tr,
          decoded?['message']?.toString() ??
              'Failed to apply coupon (${response.statusCode}).',
        );
        return null;
      }
      final status = decoded?['status'];
      final ok =
          status == true || status == 1 || status == '1' || status == 'true';
      if (!ok || decoded == null) {
        AppSnackBar.show(
          'food.coupon'.tr,
          decoded?['message']?.toString() ?? 'Invalid coupon code.',
        );
        return null;
      }
      final discounted = _extractDiscountedFare(decoded, fare);
      final msg = decoded['message']?.toString();
      if (msg != null && msg.isNotEmpty) {
        AppSnackBar.show('food.coupon'.tr, msg);
      }
      return discounted;
    } on TimeoutException {
      AppSnackBar.show('food.coupon'.tr, 'Coupon check timed out. Try again.');
      return null;
    } catch (e) {
      AppSnackBar.show(
        'food.coupon'.tr,
        'Could not validate coupon right now.',
      );
      return null;
    }
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

  /// Driver returned on `rides/request` (same shape as active-ride `data.driver`).
  NearbyDriver? _driverFromRideResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    final driverObj = map['driver'];
    if (driverObj is! Map) return null;
    final driverMap = Map<String, dynamic>.from(driverObj);
    final driverId = (driverMap['id'] as num?)?.toInt() ?? 0;
    final driverName =
        (driverMap['name'] as String?)?.trim() ??
        (driverMap['driver_id']?.toString() ?? 'Driver');
    final driverRating = driverMap['rating']?.toString() ?? '0.0';
    final vehicle =
        (driverMap['vehicle_model'] as String?) ??
        (driverMap['vehicle'] as String?) ??
        (driverMap['type_id'] != null ? 'Type ${driverMap['type_id']}' : null);
    final imageUrl =
        (driverMap['image_url'] as String?) ?? (driverMap['image'] as String?);
    return NearbyDriver(
      id: driverId,
      name: driverName.isNotEmpty ? driverName : 'Driver',
      rating: driverRating,
      vehicle: vehicle,
      photo: imageUrl,
      eta: driverMap['eta']?.toString() ?? '',
      distance: driverMap['distance']?.toString() ?? '',
    );
  }

  Future<void> _onConfirmRide() async {
    if (_isRequestingRide) return;
    final fareValue = _estimatedFareValue;
    if (fareValue == null) {
      AppSnackBar.show('ride.fare_unavailable'.tr, 'ride.fare_calculating'.tr);
      return;
    }
    final pickupAddress = (_pickupLabel ?? '').trim();
    final dropoffAddress = (_destinationLabel ?? '').trim();
    if (pickupAddress.isEmpty ||
        dropoffAddress.isEmpty ||
        _pickupLatLng == null ||
        _destinationLatLng == null) {
      AppSnackBar.show(
        'common.error'.tr,
        'Pickup/dropoff information is missing.',
      );
      return;
    }

    setState(() => _isRequestingRide = true);
    try {
      final fareAfter = await _applyCouponIfAny(fareValue);
      if (fareAfter == null) return;

      final tipAmount = _parseTipAmount();

      final response = await _ridesRepository.requestRide(
        pickupAddress: pickupAddress,
        pickupLat: _pickupLatLng!.latitude,
        pickupLng: _pickupLatLng!.longitude,
        dropoffAddress: dropoffAddress,
        dropoffLat: _destinationLatLng!.latitude,
        dropoffLng: _destinationLatLng!.longitude,
        paymentMethod: _paymentMethod,
        fare: fareAfter,
        tipAmount: tipAmount,
      );
      debugPrint('RideFareScreen requestRide response: $response');

      if (response['status'] == true && mounted) {
        AppSnackBar.show('common.success'.tr, 'Ride requested successfully');
        final driver = _driverFromRideResponse(response) ?? _assignedDriver;
        final driverId = (driver != null && driver.id > 0) ? driver.id : null;
        try {
          await ActiveRidesFirestoreService().publishRideRequested(
            apiRideResponse: Map<String, dynamic>.from(response),
            rider: _riderProfile,
            pickupAddress: pickupAddress,
            pickupLat: _pickupLatLng!.latitude,
            pickupLng: _pickupLatLng!.longitude,
            dropoffAddress: dropoffAddress,
            dropoffLat: _destinationLatLng!.latitude,
            dropoffLng: _destinationLatLng!.longitude,
            paymentMethod: _paymentMethod,
            fare: fareAfter,
            tipAmount: tipAmount,
            couponCode: _promoController.text.trim().isEmpty
                ? null
                : _promoController.text.trim(),
            rideType: 'T-Go',
            assignedDriverId: driverId,
          );
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint('Firestore active_rides write failed: $e\n$st');
          }
        }
        final args = <String, dynamic>{
          'driver': driver,
          'pickup_address': pickupAddress,
          'pickup_lat': _pickupLatLng!.latitude,
          'pickup_lng': _pickupLatLng!.longitude,
          'dropoff_address': dropoffAddress,
          'dropoff_lat': _destinationLatLng!.latitude,
          'dropoff_lng': _destinationLatLng!.longitude,
          'payment_method': _paymentMethod,
          'fare': fareAfter,
          'tip_amount': tipAmount,
          'ride_type': 'T-Go',
          'coupon_code': _promoController.text.trim(),
          'ride_request': response,
        };
        Get.to(
          () => const DriverDetailsScreen(isCourierService: false),
          arguments: args,
        );
      } else if (mounted) {
        AppSnackBar.show(
          'common.error'.tr,
          (response['message']?.toString() ?? 'Unable to request ride'),
        );
      }
    } catch (e) {
      if (mounted) AppSnackBar.show('common.error'.tr, e.toString());
    } finally {
      if (mounted) setState(() => _isRequestingRide = false);
    }
  }

  Widget _tipChip(String amount) {
    final selected = _tipController.text.trim() == amount;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tipController.text = amount),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: selected ? AppConst.black : AppConst.cardLight,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: selected ? AppConst.black : AppConst.grey.withValues(alpha: 0.25),
            ),
          ),
          child: Center(
            child: Text(
              '\$' + amount,
              style: TextStyle(
                color: selected ? AppConst.white : AppConst.black,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paymentChip(String label, String value) {
    final selected = _paymentMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: selected ? AppConst.black : AppConst.cardLight,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: selected
                  ? AppConst.black
                  : AppConst.grey.withValues(alpha: 0.35),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppConst.white : AppConst.black,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(color: AppConst.black),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10.h,
              bottom: 16.h,
              left: 20.w,
              right: 20.w,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: Get.back,
                  child: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_forward
                        : Icons.arrow_back,
                    color: AppConst.white,
                    size: 24.sp,
                  ),
                ),
                Expanded(
                  child: Text(
                    'ride.fare_summary'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppConst.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 24.w),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _initialCameraPosition,
                  onMapCreated: (c) => _mapController = c,
                  markers: _markers,
                  polylines: _routePolyline != null ? {_routePolyline!} : {},
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                ),
                if (_isLoadingRoute)
                  Center(
                    child: CircularProgressIndicator(color: AppConst.black),
                  ),
                Positioned(
                  top: 12.h,
                  left: 12.w,
                  right: 12.w,
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppConst.blackWithOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                _pickupLabel ?? '—',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppConst.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                _destinationLabel ?? '—',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppConst.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                DraggableScrollableSheet(
                  initialChildSize: 0.42,
                  minChildSize: 0.32,
                  maxChildSize: 0.88,
                  builder: (context, scrollController) {
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
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 24.h),
                        children: [
                          Center(
                            child: Container(
                              width: 40.w,
                              height: 4.h,
                              decoration: BoxDecoration(
                                color: AppConst.grey.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'profile.title'.tr,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: AppConst.black,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              Builder(
                                builder: (context) {
                                  final photoUrl = _resolvePhotoUrl(
                                    _riderProfile?.photo,
                                  );
                                  return CircleAvatar(
                                    radius: 36.r,
                                    backgroundColor: Colors.blue,
                                    backgroundImage: photoUrl != null
                                        ? NetworkImage(photoUrl)
                                        : null,
                                    child: photoUrl == null
                                        ? Text(
                                            _riderInitials(_riderProfile),
                                            style: TextStyle(
                                              color: AppConst.white,
                                              fontSize: 22.sp,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          )
                                        : null,
                                  );
                                },
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_isLoadingProfile)
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 18.w,
                                            height: 18.w,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppConst.black,
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'common.loading'.tr,
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: AppConst.black,
                                            ),
                                          ),
                                        ],
                                      )
                                    else ...[
                                      Text(
                                        _riderProfile?.name
                                                    ?.trim()
                                                    .isNotEmpty ==
                                                true
                                            ? _riderProfile!.name!.trim()
                                            : 'common.guest'.tr,
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppConst.black,
                                        ),
                                      ),
                                      SizedBox(height: 6.h),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 14.w,
                                            height: 14.w,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppConst.black,
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Expanded(
                                            child: Text(
                                              _assignedDriver == null
                                                  ? (_isLoadingDrivers
                                                        ? 'ride.finding_nearby'
                                                              .tr
                                                        : 'ride.searching_nearby'
                                                              .tr)
                                                  : '${_assignedDriver!.name} • ${_assignedDriver!.distance}',
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                color: AppConst.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          Container(
                            padding: EdgeInsets.all(14.w),
                            decoration: BoxDecoration(
                              color: AppConst.cardLight,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ride.total_fare'.tr,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppConst.black,
                                  ),
                                ),
                                if (_isLoadingFare)
                                  SizedBox(
                                    width: 20.w,
                                    height: 20.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppConst.black,
                                    ),
                                  )
                                else
                                  Text(
                                    _estimatedFareText ?? '—',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppConst.black,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 14.h),
                          Text(
                            'wallet.select_payment'.tr,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppConst.black,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              _paymentChip('payment.cash'.tr, 'Cash'),
                              SizedBox(width: 8.w),
                              _paymentChip('payment.card'.tr, 'Card'),
                              SizedBox(width: 8.w),
                              _paymentChip('payment.wallet'.tr, 'Wallet'),
                            ],
                          ),
                          SizedBox(height: 14.h),
                          Row(
                            children: [
                              _tipChip('2'),
                              SizedBox(width: 8.w),
                              _tipChip('5'),
                              SizedBox(width: 8.w),
                              _tipChip('10'),
                              SizedBox(width: 8.w),
                              _tipChip('15'),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          TextField(
                            controller: _tipController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppConst.cardLight,
                              hintText: 'ride.tip_amount_hint'.tr,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 10.h,
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          TextField(
                            controller: _promoController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppConst.cardLight,
                              hintText: 'food.enter_promo'.tr,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 10.h,
                              ),
                            ),
                          ),
                          SizedBox(height: 18.h),
                          GestureDetector(
                            onTap: _isRequestingRide ? null : _onConfirmRide,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              decoration: BoxDecoration(
                                color: _isRequestingRide
                                    ? AppConst.accentWithOpacity(0.55)
                                    : AppConst.accent,
                                borderRadius: AppConst.buttonRadius,
                              ),
                              child: Center(
                                child: _isRequestingRide
                                    ? SizedBox(
                                        width: 20.w,
                                        height: 20.w,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppConst.black,
                                        ),
                                      )
                                    : Text(
                                        'ride.confirm_request'.tr,
                                        style: TextStyle(
                                          color: AppConst.black,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



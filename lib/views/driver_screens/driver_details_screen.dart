import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;
import 'package:t_ride_rider_app/core/config/stripe_config.dart';
import 'package:t_ride_rider_app/data/firestore/active_rides_firestore_service.dart';
import 'package:t_ride_rider_app/data/repositories/stripe_payment_repository.dart';
import 'package:t_ride_rider_app/views/location/nearby_driver_model.dart';
import '../../consts/appConst.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_appbar.dart';
import '../courier_service/courier_otp_screen.dart';
import '../custom_navbar/home_screen.dart';
import '../location/select_location_screen.dart';
import 'package:t_ride_rider_app/data/repositories/rides_repository.dart';

class DriverDetailsScreen extends StatefulWidget {
  final bool isCourierService;

  const DriverDetailsScreen({super.key, this.isCourierService = false});

  @override
  State<DriverDetailsScreen> createState() => _DriverDetailsScreenState();
}

class _DriverDetailsScreenState extends State<DriverDetailsScreen> {
  static const String _googleApiKey = 'AIzaSyDuAloVADiL2L-pa1Dg7OIkjPLl-lAE6eA';

  GoogleMapController? _mapController;
  LatLng? _pickup;
  LatLng? _dropoff;
  String? _pickupAddress;
  String? _dropoffAddress;
  String? _routeDurationText;
  Polyline? _routePolyline;
  bool _isLoadingRoute = false;
  NearbyDriver? _driver;
  String? _rideType;
  String? _paymentMethod;
  num? _fare;
  num _tipAmount = 0;
  int? _rideId;
  int? _courierId;
  bool _isCourierFlow = false;
  final RidesRepository _ridesRepository = RidesRepository();
  bool _isCancelling = false;
  Timer? _driverPollTimer;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _activeOrderSub;
  DocumentReference<Map<String, dynamic>>? _activeOrderDocRef;
  LatLng? _driverLocation;
  Polyline? _driverTripPolyline;
  String? _failedDriverPhotoUrl;
  BitmapDescriptor _driverMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
    BitmapDescriptor.hueViolet,
  );
  bool _completionHandled = false;
  bool _isPresentingCardPayment = false;
  final StripePaymentRepository _stripePaymentRepository =
      StripePaymentRepository();

  /// Ride flow with no assigned driver yet (open booking / matching).
  bool get _waitingOnDriverAssignment =>
      !_isCourierFlow && (_driver == null || _driver!.id <= 0);

  void _goToHome() {
    _driverPollTimer?.cancel();
    _activeOrderSub?.cancel();
    Get.offAll(() => const HomeScreen());
  }

  @override
  void initState() {
    super.initState();
    _initFromArgs();
    _prepareDriverMarkerIcon();
  }

  @override
  void dispose() {
    _driverPollTimer?.cancel();
    _activeOrderSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _initFromArgs() {
    final raw = Get.arguments;
    final args = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};

    final d = args['driver'];
    final rideResp = args['ride_request'] as Map<String, dynamic>?;
    final rideIdArg = args['ride_id'];
    if (rideIdArg is num) {
      _rideId = rideIdArg.toInt();
    } else if (rideIdArg != null) {
      _rideId = int.tryParse('$rideIdArg');
    }
    final courierIdArg = args['courier_id'];
    if (courierIdArg is num) {
      _courierId = courierIdArg.toInt();
    } else if (courierIdArg != null) {
      _courierId = int.tryParse('$courierIdArg');
    }
    if (rideResp != null) {
      final data = rideResp['data'];
      if (data is Map<String, dynamic>) {
        final idVal = data['id'];
        if (idVal is num) {
          _rideId = idVal.toInt();
        }
      }
    }
    _driver = d is NearbyDriver ? d : null;
    _pickupAddress = (args['pickup_address'] as String?)?.trim();
    _dropoffAddress = (args['dropoff_address'] as String?)?.trim();
    _rideType = (args['ride_type'] as String?)?.trim();
    _paymentMethod = (args['payment_method'] as String?)?.trim();
    final fareRaw = args['fare'];
    _fare = fareRaw is num ? fareRaw : num.tryParse('$fareRaw');
    final tipRaw = args['tip_amount'];
    if (tipRaw is num) {
      _tipAmount = tipRaw < 0 ? 0 : tipRaw;
    } else if (tipRaw != null) {
      final p = num.tryParse('$tipRaw');
      if (p != null) _tipAmount = p < 0 ? 0 : p;
    }
    _isCourierFlow = widget.isCourierService;

    final serviceTypeRaw = (args['service_type'] as String?)?.trim();
    if (serviceTypeRaw != null && serviceTypeRaw.isNotEmpty) {
      _isCourierFlow = serviceTypeRaw.toLowerCase() != 'ride';
    } else {
      final rideTypeLower = (_rideType ?? '').toLowerCase();
      if (rideTypeLower == 'ride' || rideTypeLower.startsWith('t-')) {
        _isCourierFlow = false;
      } else if (rideTypeLower.contains('courier')) {
        _isCourierFlow = true;
      }
    }

    final pLat = args['pickup_lat'];
    final pLng = args['pickup_lng'];
    final dLat = args['dropoff_lat'];
    final dLng = args['dropoff_lng'];

    final pickupLat = pLat is num ? pLat.toDouble() : double.tryParse('$pLat');
    final pickupLng = pLng is num ? pLng.toDouble() : double.tryParse('$pLng');
    final dropLat = dLat is num ? dLat.toDouble() : double.tryParse('$dLat');
    final dropLng = dLng is num ? dLng.toDouble() : double.tryParse('$dLng');

    if (pickupLat != null && pickupLng != null) {
      _pickup = LatLng(pickupLat, pickupLng);
    }
    if (dropLat != null && dropLng != null) {
      _dropoff = LatLng(dropLat, dropLng);
    }

    if (_pickup != null && _dropoff != null) {
      _fetchRoute();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startRealtimeOrderSync();
      }
    });
  }

  NearbyDriver? _driverFromActiveRideData(Map<String, dynamic> data) {
    final driverObj = data['driver'];
    if (driverObj is! Map) return null;
    final driverMap = Map<String, dynamic>.from(driverObj);
    final driverId = (driverMap['id'] as num?)?.toInt() ?? 0;
    if (driverId <= 0) return null;
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

  Future<void> _refreshDriverFromActiveRide() async {
    if (!mounted || _isCourierFlow) return;
    if (_driver != null && _driver!.id > 0) {
      _driverPollTimer?.cancel();
      return;
    }
    try {
      final resp = await _ridesRepository.getActiveRide();
      if (!mounted) return;
      if (resp['status'] == true && resp['data'] is Map<String, dynamic>) {
        final data = Map<String, dynamic>.from(resp['data'] as Map);
        final parsed = _driverFromActiveRideData(data);
        final idVal = data['id'];
        setState(() {
          if (idVal is num) {
            _rideId = idVal.toInt();
          }
          if (parsed != null) {
            _driver = parsed;
          }
        });
        if (_driver != null && _driver!.id > 0) {
          _driverPollTimer?.cancel();
        }
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _startPollingIfSearchingForDriver() async {
    if (!mounted || !_waitingOnDriverAssignment) return;
    _driverPollTimer?.cancel();
    _driverPollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _refreshDriverFromActiveRide();
    });
    await _refreshDriverFromActiveRide();
  }

  Future<void> _prepareDriverMarkerIcon() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(96, 96);

      final bgPaint = Paint()..color = const Color(0xFF111111);
      canvas.drawCircle(const Offset(48, 48), 36, bgPaint);

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;
      canvas.drawCircle(const Offset(48, 48), 36, borderPaint);

      final iconText = String.fromCharCode(Icons.directions_car.codePoint);
      final painter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: iconText,
          style: TextStyle(
            fontSize: 44,
            color: Colors.white,
            fontFamily: Icons.directions_car.fontFamily,
            package: Icons.directions_car.fontPackage,
          ),
        ),
      )..layout();

      painter.paint(
        canvas,
        Offset(
          (size.width - painter.width) / 2,
          (size.height - painter.height) / 2,
        ),
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted || bytes == null) return;

      setState(() {
        _driverMarkerIcon = BitmapDescriptor.bytes(bytes.buffer.asUint8List());
      });
    } catch (_) {
      // Keep default marker fallback.
    }
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  LatLng? _latLngFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final geoPoint = map['geo_point'];
    if (geoPoint is GeoPoint) {
      return LatLng(geoPoint.latitude, geoPoint.longitude);
    }
    final lat =
        _toDouble(map['latitude']) ??
        _toDouble(map['lat']) ??
        _toDouble(map['pickup_lat']) ??
        _toDouble(map['dropoff_lat']);
    final lng =
        _toDouble(map['longitude']) ??
        _toDouble(map['lng']) ??
        _toDouble(map['pickup_lng']) ??
        _toDouble(map['dropoff_lng']);
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  NearbyDriver? _driverFromFirestoreData(Map<String, dynamic> data) {
    final driverObj = data['driver'];
    if (driverObj is Map) {
      return _driverFromActiveRideData({
        'driver': Map<String, dynamic>.from(driverObj),
      });
    }

    final driverIdVal =
        data['driver_id'] ??
        data['assigned_driver_id'] ??
        data['accepted_by_user_id'];
    final driverId = driverIdVal is num
        ? driverIdVal.toInt()
        : int.tryParse('$driverIdVal');
    if (driverId == null || driverId <= 0) return null;

    final driverName =
        (data['driver_name']?.toString().trim().isNotEmpty == true)
        ? data['driver_name'].toString().trim()
        : (_driver?.name ?? 'Driver');

    return NearbyDriver(
      id: driverId,
      name: driverName,
      rating: data['driver_rating']?.toString() ?? (_driver?.rating ?? '0.0'),
      vehicle: data['driver_vehicle']?.toString() ?? _driver?.vehicle,
      photo: data['driver_photo']?.toString() ?? _driver?.photo,
      eta: _driver?.eta ?? '',
      distance: _driver?.distance ?? '',
    );
  }

  void _refreshDriverTripPolyline() {
    if (_driverLocation == null || _pickup == null || _dropoff == null) {
      _driverTripPolyline = null;
      return;
    }
    _driverTripPolyline = Polyline(
      polylineId: const PolylineId('driver_trip_route'),
      points: [_driverLocation!, _pickup!, _dropoff!],
      width: 5,
      color: Colors.deepOrange,
      patterns: [PatternItem.dot, PatternItem.gap(8)],
    );
  }

  void _applyFirestoreDoc(Map<String, dynamic> data) {
    final pickupMap = data['pickup'] is Map
        ? Map<String, dynamic>.from(data['pickup'] as Map)
        : null;
    final dropoffMap = data['dropoff'] is Map
        ? Map<String, dynamic>.from(data['dropoff'] as Map)
        : null;
    final driverLocationMap = data['driver_location'] is Map
        ? Map<String, dynamic>.from(data['driver_location'] as Map)
        : null;

    final pickupFromDoc = _latLngFromMap(pickupMap);
    final dropoffFromDoc = _latLngFromMap(dropoffMap);
    final driverLocationFromDoc = _latLngFromMap(driverLocationMap);
    final driverFromDoc = _driverFromFirestoreData(data);

    setState(() {
      final rideIdVal = data['ride_id'];
      if (rideIdVal is num) _rideId = rideIdVal.toInt();
      final courierIdVal = data['courier_id'];
      if (courierIdVal is num) _courierId = courierIdVal.toInt();

      _pickup = pickupFromDoc ?? _pickup;
      _dropoff = dropoffFromDoc ?? _dropoff;
      _pickupAddress =
          pickupMap?['address']?.toString().trim().isNotEmpty == true
          ? pickupMap!['address'].toString().trim()
          : _pickupAddress;
      _dropoffAddress =
          dropoffMap?['address']?.toString().trim().isNotEmpty == true
          ? dropoffMap!['address'].toString().trim()
          : _dropoffAddress;

      final serviceType = data['service_type']?.toString().trim().toLowerCase();
      if (serviceType != null && serviceType.isNotEmpty) {
        _isCourierFlow = serviceType == 'courier';
      }

      final fareVal = data['fare'] ?? data['estimated_fare'];
      final parsedFare = fareVal is num ? fareVal : num.tryParse('$fareVal');
      _fare = parsedFare ?? _fare;
      final tipVal = data['tip_amount'];
      final parsedTip = tipVal is num ? tipVal : num.tryParse('$tipVal');
      _tipAmount = parsedTip ?? _tipAmount;
      _paymentMethod = data['payment_method']?.toString() ?? _paymentMethod;
      _rideType = data['ride_type']?.toString() ?? _rideType;

      if (driverFromDoc != null) {
        _driver = driverFromDoc;
      }

      if (driverLocationFromDoc != null) {
        _driverLocation = driverLocationFromDoc;
      }
      _refreshDriverTripPolyline();
    });

    _handleCompletionFromFirestore(data);
  }

  bool _isOrderMarkedCompleted(Map<String, dynamic> data) {
    final markCompleted = data['mark_as_completed'] == true;
    final completionStatus = data['completion_status']
        ?.toString()
        .trim()
        .toLowerCase();
    final hasCompletedAt = data['completed_at'] != null;
    return markCompleted ||
        completionStatus == 'completed' ||
        completionStatus == 'complete' ||
        hasCompletedAt;
  }

  bool _isCardPayment(String? method) {
    final m = method?.trim().toLowerCase() ?? '';
    return m == 'card';
  }

  num _toNum(dynamic value, {num fallback = 0}) {
    if (value is num) return value;
    final parsed = num.tryParse('$value');
    return parsed ?? fallback;
  }

  void _handleCompletionFromFirestore(Map<String, dynamic> data) {
    if (!mounted || _completionHandled || _isPresentingCardPayment) return;
    if (!_isOrderMarkedCompleted(data)) return;

    final payment = data['payment_method']?.toString() ?? _paymentMethod;
    if (_isCardPayment(payment)) {
      final fareAmount = _toNum(
        data['fare'] ?? data['estimated_fare'],
        fallback: _fare ?? 0,
      );
      final tipAmount = _toNum(data['tip_amount'], fallback: _tipAmount);
      final totalPayable = fareAmount + tipAmount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _presentCompletionCardPaymentSheet(totalPayable);
      });
      return;
    }
    // Cash keeps current flow unchanged.
    _completionHandled = true;
  }

  Future<void> _presentCompletionCardPaymentSheet(num totalPayable) async {
    if (_isPresentingCardPayment || _rideId == null || totalPayable <= 0) {
      return;
    }
    _isPresentingCardPayment = true;
    try {
      final response = await _stripePaymentRepository
          .createRideCompletionPaymentIntent(
            rideId: _rideId!,
            amount: totalPayable,
          );

      final data = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'] as Map)
          : <String, dynamic>{};

      final clientSecret =
          (data['payment_intent_client_secret'] ?? data['client_secret'])
              ?.toString();
      final customerId = data['customer_id']?.toString();
      final ephemeralKey =
          (data['customer_ephemeral_key'] ?? data['ephemeral_key'])?.toString();

      if (clientSecret == null || clientSecret.isEmpty) {
        throw Exception('Missing Stripe client secret.');
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: StripeConfig.merchantDisplayName,
          customerId: (customerId?.isNotEmpty == true) ? customerId : null,
          customerEphemeralKeySecret: (ephemeralKey?.isNotEmpty == true)
              ? ephemeralKey
              : null,
          style: ThemeMode.light,
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      _completionHandled = true;
      if (mounted) {
        AppSnackBar.show(
          'common.success'.tr,
          'Payment of Rs ${totalPayable.toStringAsFixed(2)} successful.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DriverDetailsScreen Stripe completion payment error: $e');
      }
      if (mounted) {
        AppSnackBar.show(
          'common.error'.tr,
          'Unable to complete card payment right now.',
        );
      }
    } finally {
      _isPresentingCardPayment = false;
    }
  }

  Future<void> _startRealtimeOrderSync() async {
    _activeOrderSub?.cancel();

    final collectionName = _isCourierFlow ? 'active_courier' : 'active_rides';
    final idField = _isCourierFlow ? 'courier_id' : 'ride_id';
    final lookupId = _isCourierFlow ? _courierId : _rideId;

    if (lookupId == null || lookupId <= 0) {
      await _startPollingIfSearchingForDriver();
      return;
    }

    _activeOrderSub = FirebaseFirestore.instance
        .collection(collectionName)
        .where(idField, isEqualTo: lookupId)
        .limit(1)
        .snapshots()
        .listen(
          (snapshot) async {
            if (!mounted || snapshot.docs.isEmpty) return;
            _activeOrderDocRef = snapshot.docs.first.reference;
            _applyFirestoreDoc(snapshot.docs.first.data());
            if (_pickup != null && _dropoff != null && _routePolyline == null) {
              await _fetchRoute();
            }
          },
          onError: (_) async {
            // Fallback for older data not yet mirrored to Firestore.
            await _startPollingIfSearchingForDriver();
          },
        );
  }

  Future<void> _fetchRoute() async {
    if (_pickup == null || _dropoff == null) return;

    setState(() {
      _isLoadingRoute = true;
    });

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${_pickup!.latitude},${_pickup!.longitude}'
      '&destination=${_dropoff!.latitude},${_dropoff!.longitude}'
      '&mode=driving&key=$_googleApiKey',
    );

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['status'] == 'OK') {
        final routes = data['routes'] as List<dynamic>;
        if (routes.isNotEmpty) {
          final overviewPolyline =
              (routes.first as Map<String, dynamic>)['overview_polyline']
                  as Map<String, dynamic>;
          final encoded = overviewPolyline['points'] as String;
          final points = _decodePolyline(encoded);

          String? durationText;
          final legs =
              (routes.first as Map<String, dynamic>)['legs'] as List<dynamic>?;
          if (legs != null && legs.isNotEmpty) {
            final leg = legs.first as Map<String, dynamic>;
            final duration = leg['duration'] as Map<String, dynamic>?;
            if (duration != null && duration['text'] is String) {
              durationText = duration['text'] as String;
            }
          }

          setState(() {
            _routePolyline = Polyline(
              polylineId: const PolylineId('route'),
              points: points,
              width: 4,
              color: AppConst.black,
            );
            _routeDurationText = durationText;
          });
        }
      } else {
        // ignore: avoid_print
        print(
          'DriverDetailsScreen directions error: ${data['status']} - ${data['error_message']}',
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('DriverDetailsScreen _fetchRoute error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
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

      final dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  Set<Marker> get _markers {
    final markers = <Marker>{};
    if (_pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickup!,
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }
    if (_dropoff != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: _dropoff!,
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    if (_driverLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver_live'),
          position: _driverLocation!,
          infoWindow: const InfoWindow(title: 'Driver'),
          icon: _driverMarkerIcon,
        ),
      );
    }
    return markers;
  }

  CameraPosition get _initialCamera => CameraPosition(
    target: _pickup ?? const LatLng(24.8607, 67.0011),
    zoom: 14,
  );

  @override
  Widget build(BuildContext context) {
    final driverName = _driver?.name ?? 'Driver';
    final driverRating = _driver?.rating ?? '0.0';
    final driverEta = _driver?.eta ?? '';
    final driverDistance = _driver?.distance ?? '';
    final driverPhotoUrl = _driver?.photo?.trim();
    final hasValidDriverPhoto =
        !_waitingOnDriverAssignment &&
        driverPhotoUrl != null &&
        driverPhotoUrl.isNotEmpty &&
        driverPhotoUrl != _failedDriverPhotoUrl;
    final rideType = (_rideType != null && _rideType!.isNotEmpty)
        ? _rideType!
        : (_isCourierFlow ? 'T-Go' : 'Ride');

    return WillPopScope(
      onWillPop: () async {
        _goToHome();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppConst.background,
        body: Column(
          children: [
            // Top Header
            CustomAppBar(
              title: _isCourierFlow
                  ? 'appbar.courier_details'.tr
                  : 'appbar.ride_details'.tr,
              onBackPressed: _goToHome,
            ),
            // Map Section
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: _initialCamera,
                    onMapCreated: (c) => _mapController = c,
                    markers: _markers,
                    polylines: {
                      if (_routePolyline != null) _routePolyline!,
                      if (_driverTripPolyline != null) _driverTripPolyline!,
                    },
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                  ),
                  if (_isLoadingRoute)
                    Center(
                      child: CircularProgressIndicator(color: AppConst.black),
                    ),
                  // Location Details Card
                  Positioned(
                    top: 35.h,
                    left: 16.w,
                    right: 16.w,
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppConst.cardLight,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppConst.blackWithOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pickup Location
                          Row(
                            children: [
                              Container(
                                width: 12.w,
                                height: 12.w,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  _pickupAddress?.isNotEmpty == true
                                      ? _pickupAddress!
                                      : 'common.pickup'.tr,
                                  style: TextStyle(
                                    color: AppConst.black,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          // Divider
                          Container(
                            height: 1.h,
                            color: AppConst.grey.withOpacity(0.3),
                          ),
                          SizedBox(height: 12.h),
                          // Drop-off Location
                          Row(
                            children: [
                              Container(
                                width: 12.w,
                                height: 12.w,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  _dropoffAddress?.isNotEmpty == true
                                      ? _dropoffAddress!
                                      : 'common.destination'.tr,
                                  style: TextStyle(
                                    color: AppConst.black,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                _routeDurationText != null
                                    ? '~$_routeDurationText'
                                    : '',
                                style: TextStyle(
                                  color: AppConst.grey,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Arrival Time Indicator

                  // Driver is waiting text
                  // Positioned(
                  //   bottom: 180.h,
                  //   left: 0,
                  //   right: 0,
                  //   child: Center(
                  //     child: Text(
                  //       'Driver is on the way',
                  //       style: TextStyle(
                  //         color: AppConst.black,
                  //         fontSize: 14.sp,
                  //         fontWeight: FontWeight.w500,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // Current Location Button
                  // Positioned(
                  //   bottom: 20.h,
                  //   right: 20.w,
                  //   child: GestureDetector(
                  //     onTap: () {
                  //       // TODO: Handle current location
                  //     },
                  //     child: Container(
                  //       width: 48.w,
                  //       height: 48.w,
                  //       decoration: BoxDecoration(
                  //         color: AppConst.black,
                  //         borderRadius: BorderRadius.circular(8.r),
                  //         boxShadow: [
                  //           BoxShadow(
                  //             color: AppConst.blackWithOpacity(0.2),
                  //             blurRadius: 8,
                  //             offset: const Offset(0, 2),
                  //           ),
                  //         ],
                  //       ),
                  //       child: Icon(
                  //         Icons.near_me,
                  //         color: AppConst.white,
                  //         size: 24.sp,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  DraggableScrollableSheet(
                    initialChildSize: 0.32,
                    minChildSize: 0.2,
                    maxChildSize: 0.8,
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
                        child: SafeArea(
                          top: false,
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 16.h,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Drag Handle
                                  Center(
                                    child: Container(
                                      margin: EdgeInsets.only(bottom: 16.h),
                                      width: 40.w,
                                      height: 4.h,
                                      decoration: BoxDecoration(
                                        color: AppConst.grey.withValues(
                                          alpha: 0.4,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          2.r,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Driver Profile Section
                                  Row(
                                    children: [
                                      // Profile Picture
                                      CircleAvatar(
                                        radius: 44.r,
                                        backgroundColor:
                                            _waitingOnDriverAssignment
                                            ? AppConst.grey.withValues(
                                                alpha: 0.28,
                                              )
                                            : AppConst.black,
                                        backgroundImage: hasValidDriverPhoto
                                            ? NetworkImage(driverPhotoUrl)
                                            : null,
                                        onBackgroundImageError:
                                            hasValidDriverPhoto
                                            ? (_, __) {
                                                if (!mounted ||
                                                    driverPhotoUrl ==
                                                        _failedDriverPhotoUrl) {
                                                  return;
                                                }
                                                setState(() {
                                                  _failedDriverPhotoUrl =
                                                      driverPhotoUrl;
                                                });
                                              }
                                            : null,
                                        child: _waitingOnDriverAssignment
                                            ? SizedBox(
                                                width: 26.w,
                                                height: 26.w,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: AppConst.black,
                                                    ),
                                              )
                                            : (!hasValidDriverPhoto
                                                  ? Text(
                                                      (_driver?.initials ?? 'D')
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                        color: AppConst.white,
                                                        fontSize: 22.sp,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    )
                                                  : null),
                                      ),
                                      SizedBox(width: 16.w),
                                      // Driver Info
                                      Expanded(
                                        child: _waitingOnDriverAssignment
                                            ? Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'ride.finding_driver'.tr,
                                                    style: TextStyle(
                                                      color: AppConst.black,
                                                      fontSize: 20.sp,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 8.h),
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Icon(
                                                        Icons.search,
                                                        color: AppConst.grey,
                                                        size: 18.sp,
                                                      ),
                                                      SizedBox(width: 6.w),
                                                      Expanded(
                                                        child: Text(
                                                          'ride.searching_nearby'
                                                              .tr,
                                                          style: TextStyle(
                                                            color:
                                                                AppConst.grey,
                                                            fontSize: 14.sp,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (_paymentMethod != null &&
                                                      _fare != null) ...[
                                                    SizedBox(height: 8.h),
                                                    Text(
                                                      '${_paymentMethod!} • Rs ${_fare!.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        color: AppConst.black,
                                                        fontSize: 12.sp,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              )
                                            : Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    driverName,
                                                    style: TextStyle(
                                                      color: AppConst.black,
                                                      fontSize: 20.sp,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4.h),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.star,
                                                        color: Colors.black,
                                                        size: 18.sp,
                                                      ),
                                                      SizedBox(width: 4.w),
                                                      Expanded(
                                                        child: Text(
                                                          '$driverRating • $driverEta • $driverDistance',
                                                          style: TextStyle(
                                                            color:
                                                                AppConst.black,
                                                            fontSize: 14.sp,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 4.h),
                                                  Text(
                                                    _paymentMethod != null &&
                                                            _fare != null
                                                        ? '${_paymentMethod!} • \$ ${_fare!.toStringAsFixed(2)}'
                                                        : '',
                                                    style: TextStyle(
                                                      color: AppConst.black,
                                                      fontSize: 12.sp,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20.h),
                                  // Car Details
                                  Text(
                                    rideType,
                                    style: TextStyle(
                                      color: AppConst.black,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    _driver?.vehicle ??
                                        'ride.vehicle_unavailable'.tr,
                                    style: TextStyle(
                                      color: AppConst.black,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    _driver != null
                                        ? 'Driver ID: ${_driver!.id}'
                                        : '',
                                    style: TextStyle(
                                      color: AppConst.grey,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  SizedBox(height: 20.h),
                                  // Call and Chat Buttons
                                  // Row(
                                  //   children: [
                                  //     Expanded(
                                  //       child: GestureDetector(
                                  //         onTap: () {
                                  //           // TODO: Handle call
                                  //         },
                                  //         child: Container(
                                  //           padding: EdgeInsets.symmetric(
                                  //             vertical: 12.h,
                                  //           ),
                                  //           decoration: BoxDecoration(
                                  //             color: AppConst.white,
                                  //             borderRadius: BorderRadius.circular(
                                  //               12.r,
                                  //             ),
                                  //           ),
                                  //           child: Row(
                                  //             mainAxisAlignment:
                                  //                 MainAxisAlignment.center,
                                  //             children: [
                                  //               Icon(
                                  //                 Icons.phone,
                                  //                 color: AppConst.black,
                                  //                 size: 20.sp,
                                  //               ),
                                  //               SizedBox(width: 8.w),
                                  //               Text(
                                  //                 'Call',
                                  //                 style: TextStyle(
                                  //                   color: AppConst.black,
                                  //                   fontSize: 14.sp,
                                  //                   fontWeight: FontWeight.w500,
                                  //                 ),
                                  //               ),
                                  //             ],
                                  //           ),
                                  //         ),
                                  //       ),
                                  //     ),
                                  //     SizedBox(width: 12.w),
                                  //     Expanded(
                                  //       child: GestureDetector(
                                  //         onTap: () {
                                  //           // TODO: Handle chat
                                  //         },
                                  //         child: Container(
                                  //           padding: EdgeInsets.symmetric(
                                  //             vertical: 12.h,
                                  //           ),
                                  //           decoration: BoxDecoration(
                                  //             color: AppConst.white,
                                  //             borderRadius: BorderRadius.circular(
                                  //               12.r,
                                  //             ),
                                  //           ),
                                  //           child: Row(
                                  //             mainAxisAlignment:
                                  //                 MainAxisAlignment.center,
                                  //             children: [
                                  //               Icon(
                                  //                 Icons.chat_bubble_outline,
                                  //                 color: AppConst.black,
                                  //                 size: 20.sp,
                                  //               ),
                                  //               SizedBox(width: 8.w),
                                  //               Text(
                                  //                 'Chat',
                                  //                 style: TextStyle(
                                  //                   color: AppConst.black,
                                  //                   fontSize: 14.sp,
                                  //                   fontWeight: FontWeight.w500,
                                  //                 ),
                                  //               ),
                                  //             ],
                                  //           ),
                                  //         ),
                                  //       ),
                                  //     ),
                                  //   ],
                                  // ),
                                  // SizedBox(height: 20.h),
                                  // Courier confirm button, or ride searching state button.
                                  if (_isCourierFlow ||
                                      _waitingOnDriverAssignment)
                                    GestureDetector(
                                      onTap: _isCourierFlow
                                          ? () {
                                              Get.to(
                                                () => const CourierOtpScreen(),
                                              );
                                            }
                                          : null,
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppConst.black,
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _isCourierFlow
                                                ? 'courier.confirm'.tr
                                                : 'ride.waiting_driver'.tr,
                                            style: TextStyle(
                                              color: AppConst.white,
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (_isCourierFlow ||
                                      _waitingOnDriverAssignment)
                                    SizedBox(height: 12.h),
                                  // Cancel Ride Button
                                  GestureDetector(
                                    onTap: () async {
                                      if (_isCancelling) return;
                                      if (_rideId == null) {
                                        AppSnackBar.show(
                                          'ride.cannot_cancel'.tr,
                                          'Ride id is missing.',
                                        );
                                        return;
                                      }
                                      setState(() {
                                        _isCancelling = true;
                                      });
                                      try {
                                        final resp = await _ridesRepository
                                            .cancelRide(rideId: _rideId!);
                                        if (resp['status'] == true) {
                                          try {
                                            final activeDoc =
                                                _activeOrderDocRef;
                                            if (activeDoc != null) {
                                              await activeDoc.delete();
                                            } else if (!_isCourierFlow) {
                                              await ActiveRidesFirestoreService()
                                                  .deleteActiveRideByRideId(
                                                    _rideId!,
                                                  );
                                            }
                                          } catch (e) {
                                            if (kDebugMode) {
                                              debugPrint(
                                                'DriverDetailsScreen Firestore delete after cancel: $e',
                                              );
                                            }
                                          }
                                          AppSnackBar.show(
                                            'Ride cancelled',
                                            (resp['message']?.toString() ??
                                                'Your ride has been cancelled.'),
                                          );
                                          // Move back to step 1 (SelectLocationScreen)
                                          Get.offAll(
                                            () => const SelectLocationScreen(),
                                          );
                                        } else {
                                          AppSnackBar.show(
                                            'common.error'.tr,
                                            (resp['message']?.toString() ??
                                                'Unable to cancel ride.'),
                                          );
                                        }
                                      } catch (e) {
                                        // ignore: avoid_print
                                        print(
                                          'DriverDetailsScreen cancelRide error: $e',
                                        );
                                        AppSnackBar.show(
                                          'common.error'.tr,
                                          e.toString(),
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            _isCancelling = false;
                                          });
                                        }
                                      }
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      child: Center(
                                        child: _isCancelling
                                            ? SizedBox(
                                                width: 20.w,
                                                height: 20.w,
                                                child:
                                                    const CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : Text(
                                                'ride.cancel'.tr,
                                                style: TextStyle(
                                                  color: Colors.white,
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
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for triangle pointer
class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



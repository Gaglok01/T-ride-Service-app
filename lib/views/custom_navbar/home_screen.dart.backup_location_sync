import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:t_ride_rider_app/core/config/api_urls.dart';
import 'package:t_ride_rider_app/data/local/secure_storage_service.dart';
import 'package:t_ride_rider_app/localization/app_translations.dart';
import 'package:t_ride_rider_app/data/models/user_profile_model.dart';
import 'package:t_ride_rider_app/data/models/wallet_model.dart';
import 'package:t_ride_rider_app/data/repositories/profile_repository.dart';
import 'package:t_ride_rider_app/data/repositories/wallet_repository.dart';
import 'package:t_ride_rider_app/widgets/app_snackbar.dart';
import 'package:t_ride_rider_app/views/courier_service/courier_request_details_screen.dart';
import 'package:t_ride_rider_app/views/wallet/add_to_wallet/add_to_wallet_view.dart';
import '../../consts/appConst.dart';
import '../auth_screens/login_screen.dart';
import '../setting/setting_screen.dart';
import '../location/select_location_screen.dart';
import '../food_dilivery/food_delivery_view.dart';
import '../rental_service/rental_home/rental_home_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _RecentActivityItem {
  const _RecentActivityItem({
    required this.type,
    required this.id,
    required this.reference,
    required this.status,
    required this.pickup,
    required this.dropoff,
    required this.date,
  });

  final String type;
  final int id;
  final String reference;
  final String status;
  final String pickup;
  final String dropoff;
  final DateTime? date;

  factory _RecentActivityItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['date']?.toString();
    if (rawDate != null && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate);
    }
    return _RecentActivityItem(
      type: (json['type'] as String?)?.trim() ?? '',
      id: (json['id'] as num?)?.toInt() ?? 0,
      reference: (json['reference'] as String?)?.trim() ?? '',
      status: (json['status'] as String?)?.trim() ?? '',
      pickup: (json['pickup'] as String?)?.trim() ?? '',
      dropoff: (json['dropoff'] as String?)?.trim() ?? '',
      date: parsedDate,
    );
  }
}

const int _kRecentHomePreviewCount = 3;

String _capitalizeLabel(String value) {
  final v = value.trim();
  if (v.isEmpty) return v;
  return '${v[0].toUpperCase()}${v.substring(1)}';
}

extension _RecentActivityDisplay on _RecentActivityItem {
  IconData get displayIcon {
    final t = type.trim().toLowerCase();
    if (t == 'courier') return Icons.local_shipping_outlined;
    if (t == 'ride') return Icons.directions_car_filled_outlined;
    if (t == 'food' || t == 'delivery') return Icons.restaurant_outlined;
    if (t == 'rental') return Icons.directions_bike_outlined;
    return Icons.history;
  }

  String get displayTitle {
    if (reference.isNotEmpty) return reference;
    if (type.isNotEmpty) return _capitalizeLabel(type);
    return 'home.recent_activity_fallback'.tr;
  }

  String get displaySubtitle {
    if (pickup.isNotEmpty && dropoff.isNotEmpty) return '$pickup → $dropoff';
    if (pickup.isNotEmpty) return pickup;
    if (dropoff.isNotEmpty) return dropoff;
    return status.isNotEmpty ? _capitalizeLabel(status) : '—';
  }
}

List<BoxShadow> _homeCardShadow() => [
  BoxShadow(
    color: AppConst.blackWithOpacity(0.07),
    blurRadius: 14,
    offset: const Offset(0, 5),
  ),
];

class _HomeScreenState extends State<HomeScreen> {
  static const String _sosEmergencyNumber = '911';
  static const String _sosTRideNumber = '87344';
  final ProfileRepository _profileRepository = ProfileRepository();
  final WalletRepository _walletRepository = WalletRepository();
  final SecureStorageService _storageService = SecureStorageService();
  UserProfile? _userProfile;
  bool _isLoadingProfile = true;
  WalletData? _walletData;
  bool _isLoadingWallet = true;
  bool _isCheckingCourierActive = false;
  bool _isLoadingRecent = true;
  String? _recentErrorMessage;
  List<_RecentActivityItem> _recentActivity = [];
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  LatLng _currentLatLng = const LatLng(41.2565, -95.9345);
  bool _isMapReady = false;
  bool _hasLocationPermission = false;
  final Set<Marker> _mapMarkers = {};


  final List<Map<String, String>> _languages = const [
    {'code': 'en', 'labelKey': 'lang.english'},
    {'code': 'ar', 'labelKey': 'lang.arabic'},
    {'code': 'es', 'labelKey': 'lang.spanish'},
    {'code': 'fr', 'labelKey': 'lang.french'},
    {'code': 'zh', 'labelKey': 'lang.mandarin'},
  ];
  String _currentLanguageCode = Get.locale?.languageCode ?? 'en';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchWallet();
    _fetchRecentActivity();
    _initializeLiveMap();
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      AppSnackBar.show('common.error'.tr, 'settings.sos_call_failed'.tr);
    }
  }

  Future<void> _onSosPressed() async {
    await Get.dialog<void>(
      AlertDialog(
        backgroundColor: AppConst.cardLight,
        title: Text(
          'settings.sos_title'.tr,
          style: TextStyle(
            color: AppConst.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'settings.sos_confirm_body'.tr,
          style: TextStyle(
            color: AppConst.black,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'common.cancel'.tr,
              style: TextStyle(
                color: AppConst.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (Get.isDialogOpen == true) Get.back();
              await _callNumber(_sosEmergencyNumber);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('settings.sos_call_911'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              if (Get.isDialogOpen == true) Get.back();
              await _callNumber(_sosTRideNumber);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConst.black,
              foregroundColor: AppConst.white,
            ),
            child: Text('settings.sos_call_tride'.tr),
          ),
        ],
      ),
    );
  }

  String _greetingLine() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'greeting.morning'.tr;
    if (h < 17) return 'greeting.afternoon'.tr;
    if (h < 21) return 'greeting.evening'.tr;
    return 'greeting.night'.tr;
  }

  Future<void> _onLanguageChanged(String? code) async {
    if (code == null || code == _currentLanguageCode) return;
    final locale = AppTranslations.localeForLanguageCode(code);
    setState(() {
      _currentLanguageCode = code;
    });
    await _storageService.saveAppLocaleLanguageCode(code);
    Get.updateLocale(locale);
  }

  Widget _buildHeaderLanguageDropdown() {
    final itemStyle = TextStyle(
      color: Colors.white,
      fontSize: 12.sp,
      fontWeight: FontWeight.w600,
    );

    return DropdownButtonHideUnderline(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: DropdownButton<String>(
          value: _currentLanguageCode,
          borderRadius: BorderRadius.circular(14.r),
          elevation: 0,
          isDense: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
            size: 18.sp,
          ),
          iconEnabledColor: Colors.white,
          style: itemStyle,
          dropdownColor: AppConst.black,
          menuMaxHeight: 220,
          items: _languages.map((lang) {
            final code = lang['code']!;
            final labelKey = lang['labelKey']!;
            return DropdownMenuItem<String>(
              value: code,
              child: Text(labelKey.tr, style: itemStyle),
            );
          }).toList(),
          onChanged: _onLanguageChanged,
        ),
      ),
    );
  }

  Future<void> _signOutUnauthorized() async {
    await _storageService.clearAuthToken();
    if (!mounted) return;
    Get.offAll(() => const LoginScreen());
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });
    try {
      final profile = await _profileRepository.getProfile();
      if (!mounted) return;
      setState(() {
        _userProfile = profile;
      });
    } on ProfileRepositoryException catch (e) {
      // ignore: avoid_print
      print('HomeScreen _fetchProfile error: $e');
      if (e.statusCode == 401) await _signOutUnauthorized();
    } catch (e) {
      // ignore: avoid_print
      print('HomeScreen _fetchProfile error: $e');
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _fetchWallet() async {
    setState(() {
      _isLoadingWallet = true;
    });
    try {
      final wallet = await _walletRepository.getWallet();
      if (!mounted) return;
      setState(() {
        _walletData = wallet;
      });
    } on WalletRepositoryException catch (e) {
      // ignore: avoid_print
      print('HomeScreen _fetchWallet error: $e');
      if (e.statusCode == 401) await _signOutUnauthorized();
    } catch (e) {
      // ignore: avoid_print
      print('HomeScreen _fetchWallet error: $e');
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWallet = false;
        });
      }
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _fetchProfile(),
      _fetchWallet(),
      _fetchRecentActivity(),
    ]);
  }

  String? _resolveMediaUrl(String? path) {
    if (path == null) return null;
    final v = path.trim();
    if (v.isEmpty) return null;
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    final cleaned = v.startsWith('/') ? v.substring(1) : v;
    return '${ApiUrls.baseUrl}$cleaned';
  }

  double? _tryParseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  Future<void> _fetchRecentActivity() async {
    setState(() {
      _isLoadingRecent = true;
      _recentErrorMessage = null;
    });

    final token = await _storageService.getAuthToken();
    if (token == null || token.isEmpty) {
      // ignore: avoid_print
      print('HomeScreen _fetchRecentActivity: missing auth token');
      if (mounted) {
        setState(() {
          _recentActivity = [];
          _recentErrorMessage = null;
          _isLoadingRecent = false;
        });
      }
      return;
    }

    final uri = Uri.parse(
      '${ApiUrls.baseUrl}${ApiUrls.recentActivity}',
    ).replace(queryParameters: {'limit': '3'});

    http.Response response;
    try {
      response = await http
          .get(
            uri,
            headers: <String, String>{
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // ignore: avoid_print
      print('HomeScreen _fetchRecentActivity timeout');
      if (mounted) {
        setState(() {
          _recentErrorMessage = 'home.error.timeout'.tr;
          _recentActivity = [];
          _isLoadingRecent = false;
        });
      }
      return;
    } catch (e) {
      // ignore: avoid_print
      print('HomeScreen _fetchRecentActivity error: $e');
      if (mounted) {
        setState(() {
          _recentErrorMessage = 'home.error.load_recent'.tr;
          _recentActivity = [];
          _isLoadingRecent = false;
        });
      }
      return;
    }

    final bodyTrim = response.body.trim();
    if (response.statusCode != 200 && response.statusCode != 201) {
      // ignore: avoid_print
      print(
        'HomeScreen _fetchRecentActivity error: '
        'statusCode=${response.statusCode}, body=$bodyTrim',
      );
      String message = 'home.error.load_recent'.tr;
      if (bodyTrim.startsWith('{')) {
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final msg = decoded['message']?.toString();
          if (msg != null && msg.trim().isNotEmpty) message = msg.trim();
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _recentErrorMessage = message;
          _recentActivity = [];
          _isLoadingRecent = false;
        });
      }
      return;
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['status'] != true) {
        final msg = decoded['message']?.toString();
        if (mounted) {
          setState(() {
            _recentErrorMessage = (msg != null && msg.trim().isNotEmpty)
                ? msg.trim()
                : 'home.error.load_recent'.tr;
            _recentActivity = [];
            _isLoadingRecent = false;
          });
        }
        return;
      }

      final data = decoded['data'];
      final items = <_RecentActivityItem>[];
      if (data is List) {
        for (final e in data) {
          if (e is Map<String, dynamic>) {
            items.add(_RecentActivityItem.fromJson(e));
          }
        }
      }
      if (mounted) {
        setState(() {
          _recentActivity = items;
          _recentErrorMessage = null;
          _isLoadingRecent = false;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('HomeScreen _fetchRecentActivity parse error: $e');
      if (mounted) {
        setState(() {
          _recentErrorMessage = 'home.error.invalid_response'.tr;
          _recentActivity = [];
          _isLoadingRecent = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchActiveCourier() async {
    final token = await _storageService.getAuthToken();
    if (token == null || token.isEmpty) {
      // ignore: avoid_print
      print('HomeScreen _fetchActiveCourier: missing auth token');
      return null;
    }

    final uri = Uri.parse('${ApiUrls.baseUrl}${ApiUrls.courierActive}');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    http.Response response;
    try {
      response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // ignore: avoid_print
      print('HomeScreen _fetchActiveCourier timeout');
      return null;
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      // ignore: avoid_print
      print(
        'HomeScreen _fetchActiveCourier error: '
        'statusCode=${response.statusCode}, body=${response.body}',
      );
      return null;
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['status'] != true) {
      return null;
    }

    final data = decoded['data'];
    if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
      return data.first as Map<String, dynamic>;
    }

    return null;
  }

  Future<void> _handleCourierTap() async {
    if (_isCheckingCourierActive) return;

    setState(() {
      _isCheckingCourierActive = true;
    });

    Get.dialog(
      Material(
        color: Colors.black.withValues(alpha: 0.35),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: AppConst.cardLight,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                SizedBox(height: 12.h),
                Text(
                  'home.checking_courier'.tr,
                  style: TextStyle(
                    color: AppConst.black,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final active = await _fetchActiveCourier();

      if (!mounted) return;

      if (active != null) {
        // Map API response to courier details screen args
        final pickupAddress =
            (active['pickup_address'] as String?)?.trim() ?? '';
        final dropoffAddress =
            (active['dropoff_address'] as String?)?.trim() ?? '';

        final pickupLat = _tryParseDouble(active['pickup_lat']);
        final pickupLng = _tryParseDouble(active['pickup_lng']);
        final dropLat = _tryParseDouble(active['dropoff_lat']);
        final dropLng = _tryParseDouble(active['dropoff_lng']);

        final paymentMethod =
            (active['payment_method'] as String?)?.trim() ?? 'Cash';
        final fareRaw = active['fare'];
        final fare = (fareRaw is num) ? fareRaw : num.tryParse('$fareRaw');
        final estimatedFareText = fare != null
            ? '\$ ${fare.toStringAsFixed(2)}'
            : '\$ 0.00';

        final courier = <String, dynamic>{
          'name': (active['receiver_name'] as String?)?.trim() ?? 'Courier',
          'rating': '0.0',
          'vehicle': active['vehicle_type']?['name'],
          'photo': null,
          'eta': '',
          'distance': '',
        };

        // Close dialog first, so it doesn't remain visible after navigation.
        if (Get.isDialogOpen == true) Get.back();

        Get.off(
          () => const CourierRequestDetailsScreen(),
          arguments: {
            'courier': courier,
            'pickup_address': pickupAddress,
            'dropoff_address': dropoffAddress,
            'estimated_fare': estimatedFareText,
            'payment_method': paymentMethod,
            'pickup_lat': pickupLat,
            'pickup_lng': pickupLng,
            'dropoff_lat': dropLat,
            'dropoff_lng': dropLng,
            'courier_id': (active['id'] as num?)?.toInt(),
          },
        );
      } else {
        // No active courier: go to normal courier flow
        if (Get.isDialogOpen == true) Get.back();
        Get.to(() => const SelectLocationScreen(isCourierService: true));
      }
    } catch (e) {
      // ignore: avoid_print
      print('HomeScreen _handleCourierTap error: $e');
      if (mounted) {
        if (Get.isDialogOpen == true) Get.back();
        Get.to(() => const SelectLocationScreen(isCourierService: true));
      }
    } finally {
      // Ensure dialog is dismissed even if navigation didn't happen.
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      if (mounted) {
        setState(() {
          _isCheckingCourierActive = false;
        });
      }
    }
  }


  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLiveMap() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setMapMarkers(_currentLatLng);
        return;
      }

      if (mounted) setState(() => _hasLocationPermission = true);

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _currentLatLng = latLng);
      _setMapMarkers(latLng);
      _moveMap(latLng, zoom: 15.2);

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 25,
        ),
      ).listen((position) {
        final next = LatLng(position.latitude, position.longitude);
        if (!mounted) return;
        setState(() => _currentLatLng = next);
        _setMapMarkers(next);
      });
    } catch (_) {
      _setMapMarkers(_currentLatLng);
    }
  }

  void _setMapMarkers(LatLng center) {
    final nearbyDriver1 = LatLng(center.latitude + 0.006, center.longitude + 0.004);
    final nearbyDriver2 = LatLng(center.latitude - 0.005, center.longitude - 0.006);
    final nearbyDriver3 = LatLng(center.latitude + 0.003, center.longitude - 0.007);
    if (!mounted) return;
    setState(() {
      _mapMarkers
        ..clear()
        ..add(Marker(
          markerId: const MarkerId('current_user'),
          position: center,
          infoWindow: const InfoWindow(title: 'You are here'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ))
        ..add(Marker(
          markerId: const MarkerId('nearby_driver_1'),
          position: nearbyDriver1,
          infoWindow: const InfoWindow(title: 'Nearby driver'),
        ))
        ..add(Marker(
          markerId: const MarkerId('nearby_driver_2'),
          position: nearbyDriver2,
          infoWindow: const InfoWindow(title: 'Nearby driver'),
        ))
        ..add(Marker(
          markerId: const MarkerId('nearby_driver_3'),
          position: nearbyDriver3,
          infoWindow: const InfoWindow(title: 'Nearby driver'),
        ));
    });
  }

  Future<void> _moveMap(LatLng target, {double zoom = 14.5}) async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  Future<void> _showScheduleRideSheet() async {
    DateTime scheduled = DateTime.now().add(const Duration(hours: 1));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 22.h + MediaQuery.paddingOf(context).bottom),
              decoration: BoxDecoration(
                color: AppConst.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3E4E8),
                        borderRadius: BorderRadius.circular(99.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Text('Schedule a ride', style: TextStyle(color: AppConst.black, fontSize: 22.sp, fontWeight: FontWeight.w900)),
                  SizedBox(height: 6.h),
                  Text('Choose when you want your driver to arrive.', style: TextStyle(color: AppConst.textSecondary, fontSize: 13.sp)),
                  SizedBox(height: 18.h),
                  _schedulePickerTile(
                    icon: Icons.calendar_today_outlined,
                    title: 'Date',
                    value: '${scheduled.month}/${scheduled.day}/${scheduled.year}',
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: scheduled,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setSheetState(() => scheduled = DateTime(picked.year, picked.month, picked.day, scheduled.hour, scheduled.minute));
                      }
                    },
                  ),
                  SizedBox(height: 10.h),
                  _schedulePickerTile(
                    icon: Icons.access_time_rounded,
                    title: 'Time',
                    value: TimeOfDay.fromDateTime(scheduled).format(context),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(scheduled),
                      );
                      if (picked != null) {
                        setSheetState(() => scheduled = DateTime(scheduled.year, scheduled.month, scheduled.day, picked.hour, picked.minute));
                      }
                    },
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Get.to(() => const SelectLocationScreen(), arguments: {'scheduled_at': scheduled.toIso8601String()});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConst.black,
                        foregroundColor: AppConst.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                      ),
                      child: const Text('Continue booking'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _schedulePickerTile({required IconData icon, required String title, required String value, required VoidCallback onTap}) {
    return Material(
      color: const Color(0xFFF5F6F8),
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          child: Row(
            children: [
              Icon(icon, color: AppConst.black, size: 21.sp),
              SizedBox(width: 12.w),
              Expanded(child: Text(title, style: TextStyle(color: AppConst.black, fontSize: 14.sp, fontWeight: FontWeight.w800))),
              Text(value, style: TextStyle(color: AppConst.textSecondary, fontSize: 13.sp, fontWeight: FontWeight.w700)),
              SizedBox(width: 6.w),
              Icon(Icons.chevron_right_rounded, color: AppConst.textSecondary, size: 22.sp),
            ],
          ),
        ),
      ),
    );
  }



  Future<void> _showNearbySheet() async {
    final items = [
      {'icon': Icons.local_taxi_rounded, 'title': 'T-Ride Economy', 'subtitle': '3 drivers nearby • 4 min pickup'},
      {'icon': Icons.local_shipping_outlined, 'title': 'Courier partner', 'subtitle': '2 couriers available • 6 min'},
      {'icon': Icons.restaurant_outlined, 'title': 'Restaurants', 'subtitle': 'Open delivery options near your location'},
      {'icon': Icons.car_rental_rounded, 'title': 'Rental cars', 'subtitle': 'Daily and hourly vehicles nearby'},
    ];
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _buildActionSheet(
        title: 'Near you',
        subtitle: 'Live options around your current location.',
        children: [
          for (final item in items)
            _sheetActionTile(
              icon: item['icon'] as IconData,
              title: item['title'] as String,
              subtitle: item['subtitle'] as String,
              onTap: () {
                Navigator.pop(context);
                final title = item['title'] as String;
                if (title.contains('Restaurant')) Get.to(() => const FoodDeliveryView());
                if (title.contains('Rental')) Get.to(() => const RentalHomeView());
              },
            ),
        ],
      ),
    );
  }

  Future<void> _showRideCourierSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _buildActionSheet(
        title: 'What do you need?',
        subtitle: 'Choose a service to start a realistic booking flow.',
        children: [
          _sheetActionTile(
            icon: Icons.local_taxi_rounded,
            title: 'Book a ride',
            subtitle: 'Pickup, destination, fare estimate, and vehicle options.',
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const SelectLocationScreen());
            },
          ),
          _sheetActionTile(
            icon: Icons.local_shipping_outlined,
            title: 'Send a package',
            subtitle: 'Courier pickup, drop-off, tracking, and proof of delivery.',
            onTap: () {
              Navigator.pop(context);
              _handleCourierTap();
            },
          ),
          _sheetActionTile(
            icon: Icons.schedule_rounded,
            title: 'Schedule for later',
            subtitle: 'Reserve a pickup time before you book.',
            onTap: () {
              Navigator.pop(context);
              _showScheduleRideSheet();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionSheet({required String title, required String subtitle, required List<Widget> children}) {
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.all(12.w),
        padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 18.h),
        decoration: BoxDecoration(
          color: AppConst.white,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: _homeCardShadow(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44.w,
                height: 4.h,
                decoration: BoxDecoration(color: const Color(0xFFE2E4E8), borderRadius: BorderRadius.circular(99.r)),
              ),
            ),
            SizedBox(height: 14.h),
            Text(title, style: TextStyle(color: AppConst.black, fontSize: 21.sp, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            SizedBox(height: 4.h),
            Text(subtitle, style: TextStyle(color: AppConst.textSecondary, fontSize: 12.sp, fontWeight: FontWeight.w500)),
            SizedBox(height: 14.h),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _sheetActionTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(18.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(13.w),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(color: const Color(0xFFFFC107), borderRadius: BorderRadius.circular(15.r)),
                  child: Icon(icon, color: AppConst.black, size: 22.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: AppConst.black, fontSize: 14.sp, fontWeight: FontWeight.w900)),
                      SizedBox(height: 3.h),
                      Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppConst.textSecondary, fontSize: 11.sp, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppConst.textSecondary, size: 24.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _isLoadingProfile
        ? 'common.loading'.tr
        : (_userProfile?.name?.isNotEmpty == true
            ? _userProfile!.name!
            : 'common.guest'.tr);

    final firstName = displayName.trim().split(' ').first;
    final avatarPhotoUrl = _isLoadingProfile ? null : _resolveMediaUrl(_userProfile?.photo);
    final hasAvatarPhoto = avatarPhotoUrl != null && avatarPhotoUrl.isNotEmpty;

    final walletBalance = _walletData?.balance ??
        (_userProfile?.walletBalance != null && _userProfile!.walletBalance != ''
            ? num.tryParse(_userProfile!.walletBalance!)
            : null);

    final walletBalanceText = _isLoadingWallet
        ? '…'
        : walletBalance != null
            ? '\$${walletBalance.toString()}'
            : '\$0.00';

    return Scaffold(
      backgroundColor: const Color(0xffF7F7F7),
      body: RefreshIndicator(
        color: AppConst.black,
        backgroundColor: AppConst.white,
        onRefresh: _refreshAll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeroHeader(
                displayName: displayName,
                firstName: firstName,
                avatarPhotoUrl: avatarPhotoUrl,
                hasAvatarPhoto: hasAvatarPhoto,
                walletBalanceText: walletBalanceText,
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildMapDashboardCard(),
                  SizedBox(height: 16.h),
                  _buildQuickActionsRow(),
                  SizedBox(height: 22.h),
                  _buildSectionHeader(
                    title: 'home.services'.tr,
                    actionText: 'home.see_all'.tr,
                    onActionTap: () {},
                  ),
                  SizedBox(height: 10.h),
                  _buildServicesStrip(),
                  SizedBox(height: 22.h),
                  _buildSectionHeader(
                    title: 'home.recent'.tr,
                    actionText: (!_isLoadingRecent &&
                            _recentErrorMessage == null &&
                            _recentActivity.length > _kRecentHomePreviewCount)
                        ? 'home.see_all'.tr
                        : null,
                    onActionTap: () {
                      Get.to(
                        () => _RecentActivityAllScreen(
                          items: List<_RecentActivityItem>.from(_recentActivity),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 10.h),
                  _buildRecentPreview(),
                  SizedBox(height: 18.h),
                  _buildPromoBanner(),
                  SizedBox(height: MediaQuery.paddingOf(context).bottom + 24.h),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader({
    required String displayName,
    required String firstName,
    required String? avatarPhotoUrl,
    required bool hasAvatarPhoto,
    required String walletBalanceText,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 22.h),
      decoration: BoxDecoration(
        color: AppConst.black,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.r),
          bottomRight: Radius.circular(28.r),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: AppConst.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppConst.white.withValues(alpha: 0.15)),
                  ),
                  child: ClipOval(
                    child: hasAvatarPhoto
                        ? CachedNetworkImage(
                            imageUrl: avatarPhotoUrl!,
                            width: 50.w,
                            height: 50.w,
                            fit: BoxFit.cover,
                            placeholder: (context, _) => Icon(Icons.person_rounded, color: AppConst.white, size: 28.sp),
                            errorWidget: (context, _, __) => Icon(Icons.person_rounded, color: AppConst.white, size: 28.sp),
                          )
                        : Icon(Icons.person_rounded, color: AppConst.white, size: 28.sp),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greetingLine(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppConst.white.withValues(alpha: 0.72),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        firstName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppConst.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildHeaderIconButton(
                  icon: Icons.settings_outlined,
                  onTap: () => Get.to(() => const SettingScreen()),
                ),
                SizedBox(width: 8.w),
                _buildHeaderIconButton(
                  icon: Icons.shield_outlined,
                  onTap: _onSosPressed,
                  foregroundColor: Colors.redAccent,
                ),
              ],
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(child: _buildMiniWallet(walletBalanceText)),
                SizedBox(width: 10.w),
                _buildHeaderLanguageDropdown(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? foregroundColor,
  }) {
    return Material(
      color: AppConst.white.withValues(alpha: 0.10),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42.w,
          height: 42.w,
          child: Icon(icon, color: foregroundColor ?? AppConst.white, size: 21.sp),
        ),
      ),
    );
  }

  Widget _buildMiniWallet(String walletBalanceText) {
    return Material(
      color: AppConst.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(18.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.to(() => AddToWalletView()),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: AppConst.primaryColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.account_balance_wallet_outlined, size: 18.sp, color: AppConst.black),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wallet',
                      style: TextStyle(
                        color: AppConst.white.withValues(alpha: 0.66),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      walletBalanceText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppConst.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.add_rounded, color: AppConst.primaryColor, size: 20.sp),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildMapDashboardCard() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: _homeCardShadow(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        child: SizedBox(
          height: 260.h,
          child: Stack(
            children: [
              Positioned.fill(
                child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLatLng,
                      zoom: 14.2,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _isMapReady = true;
                      _moveMap(_currentLatLng);
                    },
                    markers: _mapMarkers,
                    myLocationEnabled: _hasLocationPermission,
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                    liteModeEnabled: false,
                  ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.10),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14.h,
                left: 14.w,
                right: 14.w,
                child: Material(
                  color: AppConst.white,
                  borderRadius: BorderRadius.circular(22.r),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Get.to(() => const SelectLocationScreen()),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                      child: Row(
                        children: [
                          Container(
                            width: 38.w,
                            height: 38.w,
                            decoration: BoxDecoration(
                              color: const Color(0xffF2F2F2),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Icon(Icons.search_rounded, color: AppConst.black, size: 22.sp),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Where to?',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppConst.black,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Choose pickup and destination',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppConst.textSecondary,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_rounded, color: AppConst.black, size: 20.sp),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14.w,
                right: 14.w,
                bottom: 14.h,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMapInfoPill(
                        icon: Icons.my_location_rounded,
                        label: 'Near you',
                        onTap: _showNearbySheet,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _buildMapInfoPill(
                        icon: Icons.local_taxi_outlined,
                        label: 'Ride or courier',
                        onTap: _showRideCourierSheet,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildMapFallbackCanvas() {
    return Container(
      color: const Color(0xFFE9EDF2),
      child: Stack(
        children: [
          Positioned(left: -40.w, top: 18.h, child: _mapRoad(width: 230.w, rotate: -0.42)),
          Positioned(right: -30.w, top: 45.h, child: _mapRoad(width: 260.w, rotate: 0.34)),
          Positioned(left: 20.w, bottom: 48.h, child: _mapRoad(width: 320.w, rotate: -0.05)),
          Positioned(right: 36.w, bottom: 88.h, child: _mapDot(Icons.local_taxi_rounded, AppConst.black)),
          Positioned(left: 54.w, top: 108.h, child: _mapDot(Icons.location_on_rounded, AppConst.primaryColor)),
          Positioned(right: 86.w, top: 138.h, child: _mapDot(Icons.delivery_dining_rounded, AppConst.black)),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppConst.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, color: AppConst.black, size: 16.sp),
                  SizedBox(width: 6.w),
                  Text(
                    'Map preview',
                    style: TextStyle(color: AppConst.black, fontSize: 11.sp, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapRoad({required double width, required double rotate}) {
    return Transform.rotate(
      angle: rotate,
      child: Container(
        width: width,
        height: 18.h,
        decoration: BoxDecoration(
          color: AppConst.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(99.r),
          border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        ),
      ),
    );
  }

  Widget _mapDot(IconData icon, Color color) {
    return Container(
      width: 38.w,
      height: 38.w,
      decoration: BoxDecoration(
        color: AppConst.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Icon(icon, color: color, size: 20.sp),
    );
  }

  Widget _buildMapInfoPill({required IconData icon, required String label, VoidCallback? onTap}) {
    return Material(
      color: AppConst.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(16.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppConst.black, size: 17.sp),
              SizedBox(width: 7.w),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppConst.black, fontSize: 11.sp, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimarySearchCard() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: _homeCardShadow(),
      ),
      child: Material(
        color: AppConst.white,
        borderRadius: BorderRadius.circular(24.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Get.to(() => const SelectLocationScreen()),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              children: [
                Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    color: const Color(0xffF2F2F2),
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Icon(Icons.search_rounded, color: AppConst.black, size: 24.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Where to?',
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Book a ride or send a package',
                        style: TextStyle(
                          color: AppConst.textSecondary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: AppConst.grey, size: 16.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            icon: Icons.home_outlined,
            title: 'Home',
            subtitle: 'Ride home',
            onTap: () => Get.to(() => const SelectLocationScreen()),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.schedule_rounded,
            title: 'Schedule',
            subtitle: 'Book later',
            onTap: _showScheduleRideSheet,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppConst.white,
      borderRadius: BorderRadius.circular(18.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              Icon(icon, color: AppConst.black, size: 22.sp),
              SizedBox(width: 9.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: AppConst.black, fontSize: 13.sp, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2.h),
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppConst.grey, fontSize: 10.sp, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, String? actionText, VoidCallback? onActionTap}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppConst.black,
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              foregroundColor: AppConst.black,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionText, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  Widget _buildServicesStrip() {
    final services = [
      _ServiceAction(icon: 'assets/Vector.png', title: 'home.service.ride'.tr, onTap: () => Get.to(() => const SelectLocationScreen())),
      _ServiceAction(icon: 'assets/Vector (2).png', title: 'home.service.courier'.tr, onTap: _handleCourierTap),
      _ServiceAction(icon: 'assets/Group.png', title: 'home.service.delivery'.tr, onTap: () => Get.to(() => const FoodDeliveryView())),
      _ServiceAction(icon: 'assets/Vector (1).png', title: 'home.service.rental'.tr, onTap: () => Get.to(() => const RentalHomeView())),
    ];

    return SizedBox(
      height: 106.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: services.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          final item = services[index];
          return SizedBox(
            width: 94.w,
            child: _buildServicePill(icon: item.icon, title: item.title, onTap: item.onTap),
          );
        },
      ),
    );
  }

  Widget _buildServicePill({required String icon, required String title, required VoidCallback onTap}) {
    return Material(
      color: AppConst.white,
      borderRadius: BorderRadius.circular(22.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Center(
                  child: Image.asset(icon, width: 24.w, height: 24.w, fit: BoxFit.contain),
                ),
              ),
              SizedBox(height: 9.h),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppConst.black, fontSize: 12.sp, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPreview() {
    if (_isLoadingRecent) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18.h),
          child: SizedBox(
            width: 22.w,
            height: 22.w,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppConst.black),
          ),
        ),
      );
    }
    if (_recentErrorMessage != null) {
      return _homeInfoPanel(icon: Icons.info_outline_rounded, message: _recentErrorMessage!);
    }
    if (_recentActivity.isEmpty) {
      return _homeInfoPanel(icon: Icons.history_rounded, message: 'home.recent_empty'.tr);
    }
    return Column(
      children: [
        for (final item in _recentActivity.take(3)) ...[
          _recentActivityListCard(
            icon: item.displayIcon,
            title: item.displayTitle,
            address: item.displaySubtitle,
          ),
          SizedBox(height: 8.h),
        ],
      ],
    );
  }

  Widget _buildPromoBanner() {
    return Material(
      color: AppConst.black,
      borderRadius: BorderRadius.circular(24.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.to(() => const SelectLocationScreen()),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Row(
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: AppConst.primaryColor,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(Icons.local_offer_outlined, color: AppConst.black, size: 23.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'home.promo_title'.tr,
                      style: TextStyle(color: AppConst.white, fontSize: 15.sp, fontWeight: FontWeight.w800, height: 1.15),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'home.promo_subtitle'.tr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppConst.white.withValues(alpha: 0.72), fontSize: 11.sp, height: 1.25),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: AppConst.white, size: 20.sp),
            ],
          ),
        ),
      ),
    );
  }

  Widget _homeInfoPanel({required IconData icon, required String message}) {
    return Material(
      color: AppConst.white,
      borderRadius: BorderRadius.circular(20.r),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppConst.grey, size: 22.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: AppConst.grey, fontSize: 13.sp, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceAction {
  const _ServiceAction({required this.icon, required this.title, required this.onTap});

  final String icon;
  final String title;
  final VoidCallback onTap;
}

class _RecentActivityAllScreen extends StatelessWidget {
  const _RecentActivityAllScreen({required this.items});

  final List<_RecentActivityItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F7F7),
      appBar: AppBar(
        backgroundColor: AppConst.black,
        foregroundColor: AppConst.white,
        elevation: 0,
        title: Text(
          'home.recent_activity_title'.tr,
          style: TextStyle(color: AppConst.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.separated(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(height: 8.h),
        itemBuilder: (context, index) {
          final item = items[index];
          return _recentActivityListCard(
            icon: item.displayIcon,
            title: item.displayTitle,
            address: item.displaySubtitle,
          );
        },
      ),
    );
  }
}

Widget _recentActivityListCard({
  required IconData icon,
  required String title,
  required String address,
  VoidCallback? onTap,
}) {
  final tap = onTap ?? () {};

  return Material(
    color: AppConst.white,
    borderRadius: BorderRadius.circular(20.r),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: tap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: AppConst.primaryColor,
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: Icon(icon, color: AppConst.black, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppConst.black, fontSize: 14.sp, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppConst.grey, fontSize: 12.sp, height: 1.25),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppConst.grey, size: 22.sp),
          ],
        ),
      ),
    ),
  );
}

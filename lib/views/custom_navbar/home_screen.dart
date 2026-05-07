import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
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

const int _kRecentHomePreviewCount = 5;

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
    ).replace(queryParameters: {'limit': '10'});

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
  Widget build(BuildContext context) {
    final displayName = _isLoadingProfile
        ? 'common.loading'.tr
        : (_userProfile?.name?.isNotEmpty == true
              ? _userProfile!.name!
              : 'common.guest'.tr);

    final avatarPhotoUrl = _isLoadingProfile
        ? null
        : _resolveMediaUrl(_userProfile?.photo);
    final hasAvatarPhoto =
        avatarPhotoUrl != null && avatarPhotoUrl.isNotEmpty == true;

    final walletBalance =
        _walletData?.balance ??
        (_userProfile?.walletBalance != null &&
                _userProfile!.walletBalance != ''
            ? num.tryParse(_userProfile!.walletBalance!)
            : null);

    final walletBalanceText = _isLoadingWallet
        ? 'common.loading'.tr
        : walletBalance != null
        ? '\$${walletBalance.toString()}'
        : '\$0.00';

    return Scaffold(
      backgroundColor: AppConst.background,
      body: RefreshIndicator(
        color: AppConst.black,
        backgroundColor: AppConst.white,
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Top Header (Black Background)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20.r),
                    bottomRight: Radius.circular(20.r),
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Column(
                  children: [
                    // Top Row: Time, Profile, Settings
                    Row(
                      children: [
                        // Time
                        // Profile Section
                        Expanded(
                          child: SafeArea(
                            child: Row(
                              children: [
                                // Profile Picture
                                Container(
                                  width: 60.w,
                                  height: 60.w,
                                  decoration: BoxDecoration(
                                    color: AppConst.cardLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: hasAvatarPhoto
                                        ? CachedNetworkImage(
                                            imageUrl: avatarPhotoUrl,
                                            width: 60.w,
                                            height: 60.w,
                                            fit: BoxFit.cover,
                                            placeholder: (context, _) => Center(
                                              child: Icon(
                                                Icons.person,
                                                color: AppConst.grey,
                                                size: 30.sp,
                                              ),
                                            ),
                                            errorWidget: (context, _, __) =>
                                                Center(
                                                  child: Icon(
                                                    Icons.person,
                                                    color: AppConst.grey,
                                                    size: 30.sp,
                                                  ),
                                                ),
                                          )
                                        : Center(
                                            child: Icon(
                                              Icons.person,
                                              color: AppConst.grey,
                                              size: 30.sp,
                                            ),
                                          ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                // Name Section
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _greetingLine(),
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.85,
                                          ),
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        displayName,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Settings Icon
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 16.h),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Get.to(() => const SettingScreen());
                                },
                                borderRadius: BorderRadius.circular(22.r),
                                splashColor: Colors.white.withValues(
                                  alpha: 0.12,
                                ),
                                highlightColor: Colors.white.withValues(
                                  alpha: 0.06,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(10.w),
                                  child: Icon(
                                    Icons.settings_outlined,
                                    color: Colors.white,
                                    size: 22.sp,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            _buildHeaderLanguageDropdown(),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: AppConst.borderRadius,
                        boxShadow: _homeCardShadow(),
                      ),
                      child: Material(
                        color: AppConst.cardLight,
                        borderRadius: AppConst.borderRadius,
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 12.h,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'home.wallet_balance'.tr,
                                    style: TextStyle(
                                      color: AppConst.grey,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    walletBalanceText,
                                    style: TextStyle(
                                      color: AppConst.black,
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                              Material(
                                color: AppConst.black,
                                borderRadius: BorderRadius.circular(10.r),
                                child: InkWell(
                                  onTap: () {
                                    Get.to(() => AddToWalletView());
                                  },
                                  borderRadius: BorderRadius.circular(10.r),
                                  splashColor: AppConst.primaryColorWithOpacity(
                                    0.35,
                                  ),
                                  child: SizedBox(
                                    width: 40.w,
                                    height: 40.w,
                                    child: Icon(
                                      Icons.add_rounded,
                                      color: AppConst.primaryColor,
                                      size: 22.sp,
                                    ),
                                  ),
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
              // Content Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search — opens delivery home (search & browse).
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: AppConst.borderRadius,
                              boxShadow: _homeCardShadow(),
                            ),
                            child: Material(
                              color: AppConst.cardLight,
                              borderRadius: AppConst.borderRadius,
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () {
                                  Get.to(() => const SelectLocationScreen());
                                },
                                borderRadius: AppConst.borderRadius,
                                splashColor: AppConst.primaryColorWithOpacity(
                                  0.2,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 16.h,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.search_rounded,
                                        color: AppConst.grey,
                                        size: 22.sp,
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'home.search_title'.tr,
                                              style: TextStyle(
                                                color: AppConst.black,
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(height: 2.h),
                                            Text(
                                              'home.search_book_ride_home'.tr,
                                              style: TextStyle(
                                                color: AppConst.grey,
                                                fontSize: 12.sp,
                                                height: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14.sp,
                                        color: AppConst.grey.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: _homeCardShadow(),
                              ),
                              child: Material(
                                color: Colors.red,
                                shape: const CircleBorder(),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: _onSosPressed,
                                  customBorder: const CircleBorder(),
                                  splashColor: Colors.white.withValues(
                                    alpha: 0.22,
                                  ),
                                  child: SizedBox(
                                    width: 74.w,
                                    height: 74.w,
                                    child: Center(
                                      child: Text(
                                        'SOS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 22.h),
                    Text(
                      'home.services'.tr,
                      style: TextStyle(
                        color: AppConst.black,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                        height: 0.3,
                      ),
                    ),
                    // Service Categories Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12.h,
                      crossAxisSpacing: 12.w,
                      // Taller than wide: content is icon circle + label; too low overflows.
                      childAspectRatio: 1.48,
                      children: [
                        _buildServiceCard(
                          icon: 'assets/Vector.png',
                          title: 'home.service.ride'.tr,
                          onTap: () {
                            Get.to(() => const SelectLocationScreen());
                          },
                        ),
                        _buildServiceCard(
                          icon: 'assets/Vector (2).png',
                          title: 'home.service.courier'.tr,
                          onTap: _handleCourierTap,
                        ),
                        _buildServiceCard(
                          icon: 'assets/Group.png',
                          title: 'home.service.delivery'.tr,
                          onTap: () {
                            Get.to(() => const FoodDeliveryView());
                          },
                        ),
                        _buildServiceCard(
                          icon: 'assets/Vector (1).png',
                          title: 'home.service.rental'.tr,
                          onTap: () {
                            Get.to(() => const RentalHomeView());
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    // Recent Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'home.recent'.tr,
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (!_isLoadingRecent &&
                            _recentErrorMessage == null &&
                            _recentActivity.length > _kRecentHomePreviewCount)
                          TextButton(
                            onPressed: () {
                              Get.to(
                                () => _RecentActivityAllScreen(
                                  items: List<_RecentActivityItem>.from(
                                    _recentActivity,
                                  ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppConst.black,
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 8.h,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'home.see_all'.tr,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    if (_isLoadingRecent)
                      Center(
                        child: SizedBox(
                          width: 22.w,
                          height: 22.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppConst.black,
                          ),
                        ),
                      )
                    else if (_recentErrorMessage != null)
                      _homeInfoPanel(
                        icon: Icons.info_outline_rounded,
                        message: _recentErrorMessage!,
                      )
                    else if (_recentActivity.isEmpty)
                      _homeInfoPanel(
                        icon: Icons.history_rounded,
                        message: 'home.recent_empty'.tr,
                      )
                    else ...[
                      for (final item in _recentActivity.take(
                        _kRecentHomePreviewCount,
                      )) ...[
                        _recentActivityListCard(
                          icon: item.displayIcon,
                          title: item.displayTitle,
                          address: item.displaySubtitle,
                        ),
                        SizedBox(height: 8.h),
                      ],
                    ],
                    SizedBox(height: 12.h),
                    // Promotional Banner
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: AppConst.borderRadius,
                        boxShadow: [
                          BoxShadow(
                            color: AppConst.blackWithOpacity(0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: AppConst.black,
                        borderRadius: AppConst.borderRadius,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Get.to(() => const SelectLocationScreen());
                          },
                          splashColor: AppConst.primaryColorWithOpacity(0.2),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'home.promo_title'.tr,
                                        style: TextStyle(
                                          color: AppConst.white,
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w700,
                                          height: 1.2,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        'home.promo_subtitle'.tr,
                                        style: TextStyle(
                                          color: AppConst.white.withValues(
                                            alpha: 0.82,
                                          ),
                                          fontSize: 12.sp,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Container(
                                  width: 44.w,
                                  height: 44.w,
                                  decoration: BoxDecoration(
                                    color: AppConst.primaryColor,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '%',
                                      style: TextStyle(
                                        color: AppConst.black,
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.paddingOf(context).bottom + 20.h,
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

  Widget _homeInfoPanel({required IconData icon, required String message}) {
    final radius = AppConst.borderRadius;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: _homeCardShadow(),
      ),
      child: Material(
        color: AppConst.cardLight,
        borderRadius: radius,
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
                  style: TextStyle(
                    color: AppConst.grey,
                    fontSize: 13.sp,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required String icon,
    required String title,
    VoidCallback? onTap,
  }) {
    final radius = AppConst.borderRadius;
    final tap = onTap ?? () {};

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: _homeCardShadow(),
      ),
      child: Material(
        color: AppConst.cardLight,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: tap,
          borderRadius: radius,
          splashColor: AppConst.primaryColorWithOpacity(0.22),
          highlightColor: AppConst.primaryColorWithOpacity(0.08),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: AppConst.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      icon,
                      width: 28.w,
                      height: 28.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppConst.black,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentActivityAllScreen extends StatelessWidget {
  const _RecentActivityAllScreen({required this.items});

  final List<_RecentActivityItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      appBar: AppBar(
        backgroundColor: AppConst.black,
        foregroundColor: AppConst.white,
        elevation: 0,
        title: Text(
          'home.recent_activity_title'.tr,
          style: TextStyle(
            color: AppConst.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
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
  final radius = AppConst.borderRadius;
  final tap = onTap ?? () {};

  return DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: radius,
      boxShadow: _homeCardShadow(),
    ),
    child: Material(
      color: AppConst.cardLight,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tap,
        borderRadius: radius,
        splashColor: AppConst.primaryColorWithOpacity(0.22),
        highlightColor: AppConst.primaryColorWithOpacity(0.08),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          child: Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: AppConst.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppConst.black, size: 19.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppConst.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppConst.grey,
                        fontSize: 12.sp,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

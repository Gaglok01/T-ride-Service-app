import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:t_ride_rider_app/core/config/api_urls.dart';
import 'package:t_ride_rider_app/data/local/secure_storage_service.dart';
import 'package:t_ride_rider_app/data/models/dilivery_home_data.dart';
import 'package:t_ride_rider_app/data/models/vendor_model.dart';
import 'package:t_ride_rider_app/data/network/api_client.dart';
import 'package:t_ride_rider_app/widgets/app_snackbar.dart';
import '../../consts/appConst.dart';
import '../food_menu/food_menu_view.dart';

class FoodDeliveryView extends StatefulWidget {
  const FoodDeliveryView({super.key});

  @override
  State<FoodDeliveryView> createState() => _FoodDeliveryViewState();
}

class _FoodDeliveryViewState extends State<FoodDeliveryView> {
  /// Flip to `false` to use device location for `api/app/food/home` again.
  static const bool _kTempFixedFoodHomeCoords = true;
  static const double _kTempFoodHomeLat = 24.8607;
  static const double _kTempFoodHomeLng = 67.0011;

  final TextEditingController _searchController = TextEditingController();
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = true;
  String? _errorMessage;
  List<Category> _categories = [];
  List<Vendor> _vendors = [];
  int? _selectedCategoryId;
  String _locationLabel = 'food.loading_location'.tr;

  /// Last coordinates used for `api/app/food/home` (refetch when changing category).
  double _foodHomeLat = _kTempFoodHomeLat;
  double _foodHomeLng = _kTempFoodHomeLng;

  Timer? _searchDebounceTimer;
  int _foodHomeFetchSeq = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    _loadScreen();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  String? _trimmedSearchQuery() {
    final t = _searchController.text.trim();
    return t.isEmpty ? null : t;
  }

  void _onSearchTextChanged() {
    setState(() {});
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _isLoading = true);
      _fetchFoodHome(
        _foodHomeLat,
        _foodHomeLng,
        categoryId: _selectedCategoryId,
        search: _trimmedSearchQuery(),
      );
    });
  }

  List<Vendor> get _visibleVendors => _vendors;

  String? _resolveMediaUrl(String? path) {
    if (path == null) return null;
    final v = path.trim();
    if (v.isEmpty) return null;
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    final cleaned = v.startsWith('/') ? v.substring(1) : v;
    return '${ApiUrls.baseUrl}$cleaned';
  }

  String _formatDistanceKm(double? km) {
    if (km == null) return '—';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  /// Shown while food home API data is loading (`_isLoading` and lists empty).
  Widget _buildLoadingDataIndicator({required bool compact}) {
    if (compact) {
      return Center(
        child: SizedBox(
          width: 26.w,
          height: 26.w,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppConst.white,
          ),
        ),
      );
    }
    return Center(
      child: SizedBox(
        width: 36.w,
        height: 36.w,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppConst.white,
        ),
      ),
    );
  }

  Widget _vendorCardHeroImage(String? imageUrl) {
    final bg = AppConst.grey.withValues(alpha: 0.2);
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return ColoredBox(
        color: bg,
        child: Center(
          child: Icon(
            Icons.restaurant_menu_outlined,
            size: 44.sp,
            color: AppConst.grey,
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, _) => ColoredBox(
        color: bg,
        child: Center(
          child: SizedBox(
            width: 28.w,
            height: 28.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppConst.primaryColor,
            ),
          ),
        ),
      ),
      errorWidget: (context, _, __) => ColoredBox(
        color: bg,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 40.sp,
            color: AppConst.grey,
          ),
        ),
      ),
    );
  }

  Future<void> _setAddressLabel(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) {
        if (mounted) {
          setState(
            () => _locationLabel =
                '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
          );
        }
        return;
      }
      final p = placemarks.first;
      final street = (p.street?.isNotEmpty == true)
          ? p.street
          : (p.name?.isNotEmpty == true ? p.name : null);
      final city = p.locality;
      final parts = <String>[];
      if (street != null && street.isNotEmpty) parts.add(street);
      if (city != null && city.isNotEmpty && !parts.contains(city)) {
        parts.add(city);
      }
      final label = parts.isNotEmpty
          ? parts.join(', ')
          : '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      if (mounted) setState(() => _locationLabel = label);
    } catch (_) {
      if (mounted) {
        setState(
          () => _locationLabel =
              '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
        );
      }
    }
  }

  Future<({double lat, double lng})> _getPositionOrFallback() async {
    const fallbackLat = 24.8607;
    const fallbackLng = 67.0011;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(
            () => _locationLabel = 'Location off — showing default area',
          );
        }
        await _setAddressLabel(fallbackLat, fallbackLng);
        AppSnackBar.error(
          'Location',
          'Services disabled. Using default coordinates for food listings.',
        );
        return (lat: fallbackLat, lng: fallbackLng);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        if (mounted) {
          setState(() => _locationLabel = 'Location denied — default area');
        }
        await _setAddressLabel(fallbackLat, fallbackLng);
        AppSnackBar.error(
          'Location',
          'Permission denied. Using default coordinates.',
        );
        return (lat: fallbackLat, lng: fallbackLng);
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _setAddressLabel(position.latitude, position.longitude);
      return (lat: position.latitude, lng: position.longitude);
    } catch (e) {
      // ignore: avoid_print
      print('FoodDeliveryView _getPositionOrFallback: $e');
      if (mounted) {
        setState(() => _locationLabel = 'Could not get location');
      }
      await _setAddressLabel(fallbackLat, fallbackLng);
      AppSnackBar.error(
        'Location',
        'Could not read GPS. Using default coordinates.',
      );
      return (lat: fallbackLat, lng: fallbackLng);
    }
  }

  Future<void> _loadScreen() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_kTempFixedFoodHomeCoords) {
      await _setAddressLabel(_kTempFoodHomeLat, _kTempFoodHomeLng);
      await _fetchFoodHome(_kTempFoodHomeLat, _kTempFoodHomeLng);
      return;
    }

    final coords = await _getPositionOrFallback();
    await _fetchFoodHome(coords.lat, coords.lng);
  }

  /// Refetches food home; optional [categoryId] and [search] map to query params
  /// (`.../api/app/food/home?lat=&lng=&category_id=&search=`).
  Future<void> _fetchFoodHome(
    double lat,
    double lng, {
    int? categoryId,
    String? search,
  }) async {
    final seq = ++_foodHomeFetchSeq;
    _foodHomeLat = lat;
    _foodHomeLng = lng;
    try {
      final storage = SecureStorageService();
      final token = await storage.getAuthToken();
      final headers = <String, String>{'Accept': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final query = <String, String>{
        'lat': lat.toStringAsFixed(6),
        'lng': lng.toStringAsFixed(6),
      };
      if (categoryId != null) {
        query['category_id'] = categoryId.toString();
      }
      if (search != null && search.isNotEmpty) {
        query['search'] = search;
      }

      final response = await _apiClient.get(
        ApiUrls.foodHome,
        query: query,
        headers: headers,
      );

      final bodyTrim = response.body.trim();

      if (response.statusCode != 200 && response.statusCode != 201) {
        var message = 'Failed to load food home.';
        if (bodyTrim.startsWith('{')) {
          try {
            final decoded = jsonDecode(response.body) as Map<String, dynamic>;
            if (decoded['message'] != null) {
              message = decoded['message'].toString();
            }
          } catch (_) {}
        }
        if (mounted && seq == _foodHomeFetchSeq) {
          setState(() {
            _errorMessage = message;
            _categories = [];
            _vendors = [];
          });
          AppSnackBar.error('common.error'.tr, message);
        }
        return;
      }

      if (!(bodyTrim.startsWith('{') || bodyTrim.startsWith('['))) {
        if (mounted && seq == _foodHomeFetchSeq) {
          setState(() {
            _errorMessage = 'Invalid response from server.';
            _categories = [];
            _vendors = [];
          });
        }
        return;
      }

      final parsed = DiliveryHomeData.fromJsonString(response.body);
      if (parsed.data == null) {
        if (mounted && seq == _foodHomeFetchSeq) {
          setState(() {
            _errorMessage = 'No data available.';
            _categories = [];
            _vendors = [];
          });
        }
        return;
      }

      final payload = parsed.data!;
      if (mounted && seq == _foodHomeFetchSeq) {
        setState(() {
          _categories = List<Category>.from(payload.categories ?? []);
          _vendors = List<Vendor>.from(payload.vendors ?? []);
          _selectedCategoryId = categoryId;
          _errorMessage = null;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('FoodDeliveryView _fetchFoodHome: $e');
      if (mounted && seq == _foodHomeFetchSeq) {
        setState(() {
          _errorMessage = 'Something went wrong while loading.';
          _categories = [];
          _vendors = [];
        });
        AppSnackBar.error(
          'common.error'.tr,
          'Something went wrong while loading.',
        );
      }
    } finally {
      if (mounted && seq == _foodHomeFetchSeq) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Data?> _fetchVendorDetailsData(int vendorId) async {
    final storage = SecureStorageService();
    final token = await storage.getAuthToken();
    final headers = <String, String>{'Accept': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _apiClient.get(
      '${ApiUrls.foodVendor}/$vendorId',
      headers: headers,
    );

    final bodyTrim = response.body.trim();
    if (response.statusCode != 200 && response.statusCode != 201) {
      // ignore: avoid_print
      print(
        'FoodDeliveryView _fetchVendorDetailsData error statusCode=${response.statusCode} body=$bodyTrim',
      );
      return null;
    }

    if (!(bodyTrim.startsWith('{') || bodyTrim.startsWith('['))) {
      return null;
    }

    final parsed = VendorDetails.fromJsonString(response.body);
    if (parsed.status != true) return null;
    return parsed.data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header (Black Background)
            Container(
              decoration: BoxDecoration(
                color: AppConst.black,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20.r),
                  bottomRight: Radius.circular(20.r),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: 8.h),
                    // Navigation Bar with Location
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Icon(
                            Directionality.of(context) == TextDirection.rtl
                                ? Icons.arrow_forward
                                : Icons.arrow_back,
                            color: AppConst.white,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Icon(
                          Icons.location_on,
                          color: AppConst.primaryColor,
                          size: 25.sp,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            _locationLabel,
                            style: TextStyle(
                              color: AppConst.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // TODO: Handle settings
                          },
                          child: Icon(
                            Icons.settings,
                            color: AppConst.white,
                            size: 24.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'food.search_hint'.tr,
                        hintStyle: TextStyle(
                          color: AppConst.grey,
                          fontSize: 14.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppConst.grey,
                          size: 20.sp,
                        ),
                        filled: true,
                        fillColor: AppConst.cardLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 12.h,
                        ),
                      ),
                      style: TextStyle(color: AppConst.black, fontSize: 14.sp),
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome! Enjoy Discounts',
                                style: TextStyle(
                                  color: AppConst.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'on your First Order',
                                style: TextStyle(
                                  color: AppConst.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5.h),
                              // Text(
                              //   'Use Code: FIRST10',
                              //   style: TextStyle(
                              //     color: AppConst.white,
                              //     fontSize: 12.sp,
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16.w),
                        // Food illustration placeholder
                        Container(
                          width: 80.w,
                          height: 80.w,
                          decoration: BoxDecoration(
                            color: AppConst.black.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Image.asset(
                            'assets/pngimg.com - pasta_PNG86 1.png',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Promotional Banner
            SizedBox(height: 10.h),
            // Category Buttons (from API)
            SizedBox(
              height: 60.h,
              child: _isLoading && _categories.isEmpty
                  ? _buildLoadingDataIndicator(compact: true)
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 5.h,
                      ),
                      itemCount: _categories.length + 1,
                      separatorBuilder: (_, __) => SizedBox(width: 12.w),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildCategoryButton(
                            icon: Icons.grid_view_rounded,
                            title: 'common.all'.tr,
                            isSelected: _selectedCategoryId == null,
                            onTap: () async {
                              if (_selectedCategoryId == null) return;
                              setState(() {
                                _selectedCategoryId = null;
                                _isLoading = true;
                              });
                              await _fetchFoodHome(
                                _foodHomeLat,
                                _foodHomeLng,
                                search: _trimmedSearchQuery(),
                              );
                            },
                          );
                        }
                        final c = _categories[index - 1];
                        final id = c.id;
                        return _buildCategoryButton(
                          icon: Icons.restaurant_menu,
                          title: c.name ?? 'Category',
                          iconUrl: _resolveMediaUrl(c.icon),
                          isSelected: _selectedCategoryId == c.id,
                          onTap: () async {
                            if (id == null) return;
                            if (_selectedCategoryId == id) return;
                            setState(() {
                              _selectedCategoryId = id;
                              _isLoading = true;
                            });
                            await _fetchFoodHome(
                              _foodHomeLat,
                              _foodHomeLng,
                              categoryId: id,
                              search: _trimmedSearchQuery(),
                            );
                          },
                        );
                      },
                    ),
            ),
            SizedBox(height: 24.h),
            // Explore Nearby Vendors Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Explore Nearby Restraunt',
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'See All',
                    style: TextStyle(
                      color: AppConst.primaryColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            if (_errorMessage != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: AppConst.grey, fontSize: 13.sp),
                ),
              ),
            if (_errorMessage != null) SizedBox(height: 8.h),
            // Vendor Cards (Horizontal Scroll)
            SizedBox(
              height: 265.h,
              child: _isLoading && _vendors.isEmpty
                  ? _buildLoadingDataIndicator(compact: false)
                  : _visibleVendors.isEmpty
                  ? Center(child: _buildNoNearbyRestaurantsEmptyState())
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 10,
                      ),
                      itemCount: _visibleVendors.length,
                      separatorBuilder: (_, __) => SizedBox(width: 16.w),
                      itemBuilder: (context, index) {
                        return _buildVendorCard(_visibleVendors[index]);
                      },
                    ),
            ),
            SizedBox(height: 24.h),
            // Flash Deals Banner
            Container(
              height: 159.h,
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              decoration: BoxDecoration(
                borderRadius: AppConst.borderRadius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppConst.black, AppConst.black.withOpacity(0.8)],
                ),
              ),
              child: Stack(
                children: [
                  // Background image placeholder
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        color: AppConst.black.withOpacity(0.3),
                      ),
                      child: Icon(
                        Icons.local_offer,
                        color: AppConst.white.withOpacity(0.2),
                        size: 100.sp,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Flash Deals Today!',
                              style: TextStyle(
                                color: AppConst.white,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              'Up to 40% off on selected restaurants',
                              style: TextStyle(
                                color: AppConst.white,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                        // GestureDetector(
                        //   onTap: () {
                        //     // TODO: Handle order now
                        //   },
                        //   child: Container(
                        //     padding: EdgeInsets.symmetric(
                        //       horizontal: 24.w,
                        //       vertical: 12.h,
                        //     ),
                        //     decoration: BoxDecoration(
                        //       color: AppConst.primaryColor,
                        //       borderRadius: BorderRadius.circular(12.r),
                        //     ),
                        //     child: Text(
                        //       'Order Now',
                        //       style: TextStyle(
                        //         color: AppConst.black,
                        //         fontSize: 14.sp,
                        //         fontWeight: FontWeight.bold,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildNoNearbyRestaurantsEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(22.w),
            decoration: BoxDecoration(
              color: AppConst.grey.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 44.sp,
              color: AppConst.grey,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'No nearby restaurant found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppConst.black.withValues(alpha: 0.55),
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton({
    required IconData icon,
    required String title,
    String? iconUrl,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected ? AppConst.black : AppConst.white,
          borderRadius: AppConst.borderRadius,
          boxShadow: [
            BoxShadow(
              color: AppConst.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: CachedNetworkImage(
                  imageUrl: iconUrl,
                  width: 20.sp,
                  height: 20.sp,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => SizedBox(
                    width: 20.sp,
                    height: 20.sp,
                    child: Center(
                      child: SizedBox(
                        width: 14.w,
                        height: 14.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppConst.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Icon(
                    Icons.broken_image_outlined,
                    color: AppConst.grey,
                    size: 20.sp,
                  ),
                ),
              )
            else
              Icon(
                icon,
                color: isSelected ? AppConst.white : AppConst.black,
                size: 20.sp,
              ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppConst.white : AppConst.black,
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorCard(Vendor v) {
    final name = v.name ?? 'Restaurant';
    final rating = double.tryParse(v.rating ?? '') ?? 0.0;
    final reviews = v.totalOrders ?? 0;
    final time = v.businessTimings ?? '—';
    final distance = _formatDistanceKm(v.distance);
    final minOrder = v.minOrderAmount;
    final priceRange = (minOrder != null && minOrder.isNotEmpty)
        ? 'Min $minOrder'
        : '—';
    final feeRaw = v.deliveryFee ?? '—';
    final deliveryFee = '\$. $feeRaw';
    final hasFastDelivery = v.isAvailableForDelivery == 1;
    final imageUrl = _resolveMediaUrl(v.logo);

    return GestureDetector(
      onTap: () async {
        final vendorId = v.id;
        if (vendorId == null) {
          Get.to(
            () => FoodMenuView(
              restaurantName: name,
              rating: rating,
              reviews: reviews,
              deliveryTime: time,
              deliveryFee: deliveryFee,
              products: null,
            ),
          );
          return;
        }

        Get.dialog(
          Center(
            child: CircularProgressIndicator(color: AppConst.primaryColor),
          ),
          barrierDismissible: false,
        );

        try {
          final vendorDetailsData = await _fetchVendorDetailsData(vendorId);
          if (!mounted) return;
          if (Get.isDialogOpen == true) Get.back();

          if (vendorDetailsData == null) {
            AppSnackBar.error(
              'common.error'.tr,
              'Failed to load vendor details.',
            );
            Get.to(
              () => FoodMenuView(
                restaurantName: name,
                rating: rating,
                reviews: reviews,
                deliveryTime: time,
                deliveryFee: deliveryFee,
                products: null,
              ),
            );
            return;
          }

          final vendorRating =
              double.tryParse(vendorDetailsData.rating ?? '') ?? 0.0;
          final vendorReviews = vendorDetailsData.totalOrders ?? reviews;
          final vendorTime = vendorDetailsData.businessTimings ?? time;
          final vendorFeeRaw = vendorDetailsData.deliveryFee ?? v.deliveryFee;
          final vendorFee = '\$. ${vendorFeeRaw ?? '—'}';

          Get.to(
            () => FoodMenuView(
              restaurantName: vendorDetailsData.name ?? name,
              rating: vendorRating,
              reviews: vendorReviews,
              deliveryTime: vendorTime,
              deliveryFee: vendorFee,
              products: vendorDetailsData.products,
            ),
          );
        } catch (e) {
          if (Get.isDialogOpen == true) Get.back();
          // ignore: avoid_print
          print('FoodDeliveryView vendor tap error: $e');
          AppSnackBar.error(
            'common.error'.tr,
            'Failed to load vendor details.',
          );
        }
      },
      child: Container(
        width: 280.w,
        decoration: BoxDecoration(
          color: AppConst.cardLight,
          borderRadius: AppConst.borderRadius,
          boxShadow: [
            BoxShadow(
              color: AppConst.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (API logo via CachedNetworkImage, or icon if missing/error)
            Container(
              height: 120.h,
              decoration: BoxDecoration(
                color: AppConst.grey.withValues(alpha: 0.2),
                borderRadius: AppConst.borderRadius,
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: AppConst.borderRadius,
                      child: _vendorCardHeroImage(imageUrl),
                    ),
                  ),
                  if (hasFastDelivery)
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppConst.primaryColor,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flash_on,
                              color: AppConst.black,
                              size: 12.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Fast Delivery',
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: AppConst.primaryColor,
                        size: 14.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '$rating ($reviews+)',
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          '$time . $distance . $priceRange',
                          style: TextStyle(
                            color: AppConst.grey,
                            fontSize: 11.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      // ConstrainedBox(
                      //   constraints: BoxConstraints(maxWidth: 96.w),
                      //   child: Container(
                      //     padding: EdgeInsets.symmetric(
                      //       horizontal: 6.w,
                      //       vertical: 2.h,
                      //     ),
                      //     decoration: BoxDecoration(
                      //       color: AppConst.primaryColor.withValues(alpha: 0.2),
                      //       borderRadius: BorderRadius.circular(4.r),
                      //     ),
                      //     child: Text(
                      //       category,
                      //       style: TextStyle(
                      //         color: AppConst.black,
                      //         fontSize: 10.sp,
                      //         fontWeight: FontWeight.w500,
                      //       ),
                      //       maxLines: 1,
                      //       overflow: TextOverflow.ellipsis,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Delivery: $deliveryFee',
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasFastDelivery) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppConst.primaryColor,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flash_on,
                                color: AppConst.black,
                                size: 10.sp,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                'Fast',
                                style: TextStyle(
                                  color: AppConst.black,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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

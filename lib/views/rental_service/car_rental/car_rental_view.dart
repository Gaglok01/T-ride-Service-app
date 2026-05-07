import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:t_ride_rider_app/core/config/api_urls.dart';
import 'package:t_ride_rider_app/data/models/rental_items_model.dart';
import 'package:t_ride_rider_app/data/models/rental_item_details_model.dart';
import 'package:t_ride_rider_app/data/local/secure_storage_service.dart';
import 'package:t_ride_rider_app/data/network/api_client.dart';
import 'package:t_ride_rider_app/widgets/custom_appbar.dart';
import 'package:t_ride_rider_app/widgets/app_snackbar.dart';
import '../../../consts/appConst.dart';
import '../rental_details/rental_details_view.dart';

class CarRentalView extends StatefulWidget {
  final String title;
  final String description;
  final String category;

  const CarRentalView({
    super.key,
    this.title = 'Car Rental',
    this.description = 'Rent a car easily for daily or long-term use.',
    this.category = 'Car',
  });

  @override
  State<CarRentalView> createState() => _CarRentalViewState();
}

class _CarRentalViewState extends State<CarRentalView> {
  final TextEditingController _searchController = TextEditingController();
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  String? _errorMessage;
  List<Datum> _items = [];

  String? _resolveImageUrl(String? image) {
    if (image == null) return null;
    final v = image.trim();
    if (v.isEmpty) return null;

    if (v.startsWith('http://') || v.startsWith('https://')) return v;

    // Backend likely returns only the filename (e.g. "civic_rs.jpg").
    // Build full URL from baseUrl so CachedNetworkImage can fetch it.
    final cleaned = v.startsWith('/') ? v.substring(1) : v;
    return '${ApiUrls.baseUrl}$cleaned';
  }

  String _getHeaderImageAsset() {
    // Keep the same image assets as the category cards on `RentalHomeView`.
    switch (widget.category.toLowerCase()) {
      case 'car':
        return 'assets/Frame 73.png';
      case 'apartment':
        return 'assets/Group 344.png';
      case 'house':
        return 'assets/Group 344.png';
      default:
        return 'assets/Frame 73.png';
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchRentalItems();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    // Rebuild so `_buildContent()` filtering updates as the user types.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          // Top Header (Black Background)
          CustomAppBar(title: widget.title),
          // Car Collage Section
          Container(
            height: 120.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppConst.cardLight,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20.r),
                bottomRight: Radius.circular(20.r),
              ),
            ),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20.r),
                  bottomRight: Radius.circular(20.r),
                ),
                child: Image.asset(
                  _getHeaderImageAsset(),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.directions_car,
                      color: AppConst.grey.withOpacity(0.8),
                      size: 50.sp,
                    );
                  },
                ),
              ),
            ),
          ),
          // Main Content (Yellow Background)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppConst.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Rating
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: AppConst.black,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    // Row(
                    //   children: [
                    //     Icon(Icons.star, color: AppConst.black, size: 18.sp),
                    //     SizedBox(width: 4.w),
                    //     Text(
                    //       '4.8 (13000+)',
                    //       style: TextStyle(
                    //         color: AppConst.black,
                    //         fontSize: 12.sp,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    SizedBox(height: 20.h),
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppConst.cardLight,
                        hintText: 'Search ${widget.category} model',
                        hintStyle: TextStyle(
                          color: AppConst.grey,
                          fontSize: 14.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppConst.grey,
                          size: 20.sp,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: AppConst.borderRadius,
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 15.h,
                        ),
                      ),
                      style: TextStyle(color: AppConst.black, fontSize: 14.sp),
                    ),
                    // SizedBox(height: 20.h),
                    // Navigation Tabs
                    // SizedBox(
                    //   height: 40.h,
                    //   child: ListView(
                    //     scrollDirection: Axis.horizontal,
                    //     children: [
                    //       _buildTab('Special offers for you', 0),
                    //       SizedBox(width: 16.w),
                    //       _buildTab('Popular', 1),
                    //       SizedBox(width: 16.w),
                    //       _buildTab('Newly Added', 2),
                    //     ],
                    //   ),
                    // ),
                    // Car Listings Grid
                    _buildContent(),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchRentalItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final storage = SecureStorageService();
      final token = await storage.getAuthToken();

      final headers = <String, String>{'Accept': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        // ignore: avoid_print
        print('CarRentalView: missing auth token (trying without it).');
      }

      final response = await _apiClient.get(
        ApiUrls.rentalItems,
        query: {'category': widget.category},
        headers: headers,
      );

      // Always print response details to diagnose API issues.
      // ignore: avoid_print
      print(
        'CarRentalView _fetchRentalItems statusCode: ${response.statusCode}',
      );
      // ignore: avoid_print
      print(
        'CarRentalView _fetchRentalItems response headers: ${response.headers}',
      );
      // ignore: avoid_print
      print('CarRentalView _fetchRentalItems response body:\n${response.body}');

      final bodyTrim = response.body.trim();

      if (response.statusCode != 200 && response.statusCode != 201) {
        String message = 'Failed to load cars.';
        if (bodyTrim.startsWith('{') || bodyTrim.startsWith('[')) {
          try {
            final decoded = jsonDecode(response.body) as Map<String, dynamic>;
            if (decoded['message'] != null) {
              message = decoded['message'].toString();
            }
          } catch (_) {}
        }

        setState(() {
          _errorMessage = message;
        });
        AppSnackBar.error('Error', message);
        return;
      }

      // If we got HTML (e.g. <!DOCTYPE html>), avoid jsonDecode crash.
      if (!(bodyTrim.startsWith('{') || bodyTrim.startsWith('['))) {
        setState(() {
          _errorMessage = 'Server returned a non-JSON response.';
        });
        AppSnackBar.error(
          'Error',
          'Server returned a non-JSON response.',
        );
        return;
      }

      try {
        final items = RentalItems.fromJsonString(response.body);
        setState(() {
          _items = items.data ?? [];
        });
      } catch (e) {
        // ignore: avoid_print
        print('CarRentalView JSON parse error: $e');
        // ignore: avoid_print
        print('CarRentalView JSON parse raw response body:\n${response.body}');

        setState(() {
          _errorMessage =
              'Could not parse cars response. Please check console logs.';
        });
        AppSnackBar.error(
          'Error',
          'Could not parse cars response. Please check console logs.',
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('CarRentalView _fetchRentalItems error: $e');
      const message = 'Something went wrong while loading cars.';
      setState(() {
        _errorMessage = message;
      });
      AppSnackBar.error('Error', message);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openRentalItemDetails(int itemId) async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final storage = SecureStorageService();
      final token = await storage.getAuthToken();

      final headers = <String, String>{'Accept': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final responseWithId = await _apiClient.get(
        '${ApiUrls.rentalItemDetails}/$itemId',
        headers: headers,
      );

      // Prefer the response with id.
      final res = responseWithId;

      // ignore: avoid_print
      print(
        'CarRentalView _openRentalItemDetails statusCode: ${res.statusCode}',
      );
      // ignore: avoid_print
      print('CarRentalView _openRentalItemDetails body:\n${res.body}');

      final bodyTrim = res.body.trim();

      if (res.statusCode != 200 && res.statusCode != 201) {
        String message = 'Failed to load rental details.';
        if (bodyTrim.startsWith('{') || bodyTrim.startsWith('[')) {
          try {
            final decoded = jsonDecode(res.body) as Map<String, dynamic>;
            if (decoded['message'] != null) {
              message = decoded['message'].toString();
            }
          } catch (_) {}
        }
        if (Get.isDialogOpen == true) Get.back();
        Future.microtask(() {
          AppSnackBar.error('Error', message);
        });
        return;
      }

      if (!(bodyTrim.startsWith('{') || bodyTrim.startsWith('['))) {
        if (Get.isDialogOpen == true) Get.back();
        Future.microtask(() {
          AppSnackBar.error(
            'Error',
            'Server returned a non-JSON response for rental details.',
          );
        });
        return;
      }

      final details = RentalItemsDetails.fromJsonString(res.body);
      final data = details.data;
      if (data == null) {
        if (Get.isDialogOpen == true) Get.back();
        Future.microtask(() {
          AppSnackBar.error('Error', 'Rental item details not found.');
        });
        return;
      }

      if (Get.isDialogOpen == true) Get.back();
      Get.to(() => RentalDetailsView(item: data, rentalType: widget.title));
    } catch (e) {
      // ignore: avoid_print
      print('CarRentalView _openRentalItemDetails error: $e');
      if (Get.isDialogOpen == true) Get.back();
      Future.microtask(() {
        AppSnackBar.error(
          'Error',
          'Something went wrong while loading details.',
        );
      });
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.only(top: 40.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: EdgeInsets.only(top: 40.h),
        child: Column(
          children: [
            Text(
              _errorMessage!,
              style: TextStyle(color: AppConst.black, fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: _fetchRentalItems,
              child: Text(
                'Retry',
                style: TextStyle(
                  color: AppConst.black,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 40.h),
        child: Center(
          child: Text(
            'No cars available at the moment.',
            style: TextStyle(color: AppConst.black, fontSize: 14.sp),
          ),
        ),
      );
    }

    final filtered = _searchController.text.trim().isEmpty
        ? _items
        : _items
              .where(
                (item) =>
                    (item.name ?? '').toLowerCase().contains(
                      _searchController.text.trim().toLowerCase(),
                    ) ||
                    (item.location ?? '').toLowerCase().contains(
                      _searchController.text.trim().toLowerCase(),
                    ),
              )
              .toList();

    if (filtered.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 40.h),
        child: Center(
          child: Text(
            'No cars match your search.',
            style: TextStyle(color: AppConst.black, fontSize: 14.sp),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16.h,
        crossAxisSpacing: 16.w,
        childAspectRatio: 0.75,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final priceText = (item.price != null && item.priceUnit != null)
            ? '\$ ${item.price}/${item.priceUnit}'
            : (item.price != null ? '\$ ${item.price}' : 'Price N/A');

        final imageFromApi = (item.images != null && item.images!.isNotEmpty)
            ? item.images!.first
            : null;

        return _buildCarCard(
          brand: item.name ?? 'Car',
          price: priceText,
          imageUrl: _resolveImageUrl(imageFromApi),
          itemId: item.id ?? 0,
        );
      },
    );
  }

  Widget _buildCarCard({
    required String brand,
    required String price,
    required int itemId,
    String? originalPrice,
    bool hasDiscount = false,
    String? imageUrl,
  }) {
    return GestureDetector(
      onTap: () {
        if (itemId <= 0) {
          AppSnackBar.show('Error', 'Invalid rental item id.');
          return;
        }
        _openRentalItemDetails(itemId);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            // BoxShadow(
            //   color: AppConst.black.withOpacity(0.08),
            //   blurRadius: 8,
            //   offset: const Offset(0, 2),
            // ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car Image Section
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppConst.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.all(Radius.circular(15.r)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(15.r)),
                        child: (imageUrl == null)
                            ? Icon(
                                Icons.broken_image,
                                color: AppConst.grey,
                                size: 60.sp,
                              )
                            : CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.broken_image,
                                  color: AppConst.grey,
                                  size: 60.sp,
                                ),
                              ),
                      ),
                    ),
                    // Add Button
                    Positioned(
                      bottom: 8.h,
                      right: 8.w,
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Handle add to cart/favorites
                        },
                        child: Container(
                          width: 28.w,
                          height: 28.w,
                          decoration: BoxDecoration(
                            color: AppConst.black,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: AppConst.white,
                            size: 18.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Brand and Price Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      brand,
                      style: TextStyle(
                        color: AppConst.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          price,
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (hasDiscount && originalPrice != null) ...[
                          SizedBox(width: 6.w),
                          Text(
                            originalPrice,
                            style: TextStyle(
                              color: AppConst.grey,
                              fontSize: 10.sp,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

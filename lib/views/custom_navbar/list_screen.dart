import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:t_ride_rider_app/core/config/api_urls.dart';
import 'package:t_ride_rider_app/data/local/secure_storage_service.dart';

import '../../consts/appConst.dart';
import '../courier_service/courier_request_details_screen.dart';
import '../food_dilivery/food_delivery_view.dart';
import '../location/select_location_screen.dart';
import '../rental_service/rental_home/rental_home_view.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final SecureStorageService _storageService = SecureStorageService();
  bool _isCheckingCourierActive = false;

  double? _tryParseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  Future<Map<String, dynamic>?> _fetchActiveCourier() async {
    final token = await _storageService.getAuthToken();
    if (token == null || token.isEmpty) {
      // ignore: avoid_print
      print('ListScreen _fetchActiveCourier: missing auth token');
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
      print('ListScreen _fetchActiveCourier timeout');
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('ListScreen _fetchActiveCourier error: $e');
      return null;
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      // ignore: avoid_print
      print(
        'ListScreen _fetchActiveCourier error: '
        'statusCode=${response.statusCode}, body=${response.body}',
      );
      return null;
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['status'] != true) return null;

    final data = decoded['data'];
    if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
      return data.first as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> _handleCourierTap() async {
    if (_isCheckingCourierActive) return;

    setState(() => _isCheckingCourierActive = true);

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
        if (Get.isDialogOpen == true) Get.back();
        Get.to(() => const SelectLocationScreen(isCourierService: true));
      }
    } catch (e) {
      // ignore: avoid_print
      print('ListScreen _handleCourierTap error: $e');
      if (mounted) {
        if (Get.isDialogOpen == true) Get.back();
        Get.to(() => const SelectLocationScreen(isCourierService: true));
      }
    } finally {
      if (Get.isDialogOpen == true) Get.back();
      if (mounted) setState(() => _isCheckingCourierActive = false);
    }
  }

  Widget _serviceTile({
    required IconData leadingIcon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? accent,
    String? badge,
  }) {
    final a = accent ?? AppConst.black;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFEDEEF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: a.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Icon(leadingIcon, color: a, size: 27.sp),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badge != null) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppConst.primaryColor.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  color: AppConst.black,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppConst.textSecondary,
                          fontSize: 13.sp,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F7),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppConst.black,
                    size: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18.r),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: const Color(0xFFEDEEF2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24.sp, color: AppConst.black),
                SizedBox(height: 6.h),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: AppConst.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 26.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: AppConst.black,
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                    child: Icon(
                      Icons.grid_view_rounded,
                      color: AppConst.white,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Services',
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Choose what you need today',
                          style: TextStyle(
                            color: AppConst.textSecondary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.r),
                      border: Border.all(color: const Color(0xFFEDEEF2)),
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: AppConst.black,
                      size: 22.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppConst.black,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book faster with T‑Ride',
                            style: TextStyle(
                              color: AppConst.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Ride, courier, delivery and rentals in one simple app.',
                            style: TextStyle(
                              color: AppConst.white.withValues(alpha: 0.72),
                              fontSize: 12.sp,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      width: 54.w,
                      height: 54.w,
                      decoration: BoxDecoration(
                        color: AppConst.primaryColor,
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: AppConst.black,
                        size: 28.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  _quickChip(
                    icon: Icons.directions_car_filled_rounded,
                    label: 'Ride',
                    onTap: () => Get.to(() => const SelectLocationScreen()),
                  ),
                  SizedBox(width: 10.w),
                  _quickChip(
                    icon: Icons.local_shipping_rounded,
                    label: 'Courier',
                    onTap: _handleCourierTap,
                  ),
                  SizedBox(width: 10.w),
                  _quickChip(
                    icon: Icons.restaurant_rounded,
                    label: 'Delivery',
                    onTap: () => Get.to(() => const FoodDeliveryView()),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Text(
                'Choose a service',
                style: TextStyle(
                  color: AppConst.black,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 12.h),
              _serviceTile(
                leadingIcon: Icons.directions_car_filled_rounded,
                title: 'home.service.ride'.tr,
                subtitle: 'Fast pickup anywhere with live ETA tracking.',
                accent: const Color(0xFF0B1320),
                badge: 'Popular',
                onTap: () => Get.to(() => const SelectLocationScreen()),
              ),
              _serviceTile(
                leadingIcon: Icons.local_shipping_rounded,
                title: 'home.service.courier'.tr,
                subtitle: 'Send packages instantly with real-time tracking.',
                accent: const Color(0xFF1A3E8A),
                onTap: _handleCourierTap,
              ),
              _serviceTile(
                leadingIcon: Icons.restaurant_rounded,
                title: 'home.service.delivery'.tr,
                subtitle: 'Order food and essentials from nearby stores.',
                accent: const Color(0xFF0E6B3A),
                onTap: () => Get.to(() => const FoodDeliveryView()),
              ),
              _serviceTile(
                leadingIcon: Icons.key_rounded,
                title: 'home.service.rental'.tr,
                subtitle: 'Rent vehicles or places when you need them.',
                accent: const Color(0xFF7A3B00),
                onTap: () => Get.to(() => const RentalHomeView()),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }
}

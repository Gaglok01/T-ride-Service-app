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
  }) {
    final a = accent ?? AppConst.black;
    return Material(
      color: AppConst.cardLight,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: a.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(leadingIcon, color: a, size: 22.sp),
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
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      style: TextStyle(color: AppConst.grey, fontSize: 12.sp),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Icon(Icons.chevron_right, color: AppConst.grey, size: 22.sp),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      appBar: AppBar(
        backgroundColor: AppConst.black,
        foregroundColor: AppConst.white,
        title: Text(
          'list.services'.tr,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'list.choose_service'.tr,
                style: TextStyle(
                  color: AppConst.black,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10.h),
              _serviceTile(
                leadingIcon: Icons.directions_car_filled_outlined,
                title: 'home.service.ride'.tr,
                subtitle: 'list.ride_subtitle'.tr,
                accent: const Color(0xFF0B1320),
                onTap: () => Get.to(() => const SelectLocationScreen()),
              ),
              SizedBox(height: 10.h),
              _serviceTile(
                leadingIcon: Icons.local_shipping_outlined,
                title: 'home.service.courier'.tr,
                subtitle: 'list.courier_subtitle'.tr,
                accent: const Color(0xFF1A3E8A),
                onTap: _handleCourierTap,
              ),
              SizedBox(height: 10.h),
              _serviceTile(
                leadingIcon: Icons.restaurant_outlined,
                title: 'home.service.delivery'.tr,
                subtitle: 'list.delivery_subtitle'.tr,
                accent: const Color(0xFF0E6B3A),
                onTap: () => Get.to(() => const FoodDeliveryView()),
              ),
              SizedBox(height: 10.h),
              _serviceTile(
                leadingIcon: Icons.directions_bike_outlined,
                title: 'home.service.rental'.tr,
                subtitle: 'list.rental_subtitle'.tr,
                accent: const Color(0xFF7A3B00),
                onTap: () => Get.to(() => const RentalHomeView()),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}

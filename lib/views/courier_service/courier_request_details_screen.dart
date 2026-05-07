import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:t_ride_rider_app/views/setting/setting_screen.dart';
import 'dart:convert';

import '../../consts/appConst.dart';
import '../../core/config/api_urls.dart';
import '../../data/local/secure_storage_service.dart';
import '../../widgets/app_snackbar.dart';
import '../custom_navbar/navbar.dart';

class CourierRequestDetailsScreen extends StatelessWidget {
  const CourierRequestDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final courier = args['courier'] as Map<String, dynamic>? ?? {};

    final String name = courier['name']?.toString() ?? 'Courier';
    final String rating = courier['rating']?.toString() ?? '0.0';
    final String eta = courier['eta']?.toString() ?? '';
    final String distance = courier['distance']?.toString() ?? '';

    final String pickupAddress =
        args['pickup_address']?.toString() ?? 'Pickup address not set';
    final String dropoffAddress =
        args['dropoff_address']?.toString() ?? 'Dropoff address not set';
    final String estimatedFare = args['estimated_fare']?.toString() ?? 'N/A';
    final String paymentMethod = args['payment_method']?.toString() ?? 'N/A';
    final int? courierId = (args['courier_id'] as num?)?.toInt();

    final pickupLat = (args['pickup_lat'] as num?)?.toDouble();
    final pickupLng = (args['pickup_lng'] as num?)?.toDouble();
    final dropoffLat = (args['dropoff_lat'] as num?)?.toDouble();
    final dropoffLng = (args['dropoff_lng'] as num?)?.toDouble();

    LatLng? pickupLatLng;
    LatLng? dropoffLatLng;
    if (pickupLat != null && pickupLng != null) {
      pickupLatLng = LatLng(pickupLat, pickupLng);
    }
    if (dropoffLat != null && dropoffLng != null) {
      dropoffLatLng = LatLng(dropoffLat, dropoffLng);
    }

    final initialCameraPosition = CameraPosition(
      target: pickupLatLng ?? const LatLng(24.8607, 67.0011),
      zoom: 14,
    );

    return Scaffold(
      backgroundColor: AppConst.white,
      body: Stack(
        children: [
          // Map / route area
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            width: double.infinity,
            child: pickupLatLng != null || dropoffLatLng != null
                ? GoogleMap(
                    initialCameraPosition: initialCameraPosition,
                    markers: {
                      if (pickupLatLng != null)
                        Marker(
                          markerId: const MarkerId('pickup'),
                          position: pickupLatLng,
                          infoWindow: const InfoWindow(title: 'Pickup'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen,
                          ),
                        ),
                      if (dropoffLatLng != null)
                        Marker(
                          markerId: const MarkerId('dropoff'),
                          position: dropoffLatLng,
                          infoWindow: const InfoWindow(title: 'Dropoff'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        ),
                    },
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    onMapCreated: (_) {},
                  )
                : Container(
                    color: AppConst.primaryColor.withOpacity(0.2),
                    child: Center(
                      child: Text(
                        'Map & Route',
                        style: TextStyle(
                          color: AppConst.black.withOpacity(0.5),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
          ),
          // Top "Trip In Progress" header card
          Positioned(
            top: MediaQuery.of(context).padding.top + 8.h,
            left: 12.w,
            right: 12.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppConst.black,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              // ignore: avoid_print
                              print(
                                'CourierRequestDetailsScreen: settings tapped -> Navbar',
                              );
                              Get.offAll(() => const Navbar());
                            },
                            child: Icon(
                              Directionality.of(context) == TextDirection.rtl
                                  ? Icons.arrow_forward
                                  : Icons.arrow_back,
                              color: AppConst.white,
                              size: 20.sp,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Trip In Progress',
                            style: TextStyle(
                              color: AppConst.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Get.offAll(() => const SettingScreen());
                        },
                        child: Padding(
                          padding: EdgeInsets.all(8.w),
                          child: Icon(
                            Icons.settings,
                            color: AppConst.white,
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 10.sp,
                              color: Colors.green,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                pickupAddress,
                                style: TextStyle(
                                  color: AppConst.black,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Icon(Icons.circle, size: 10.sp, color: Colors.red),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                dropoffAddress,
                                style: TextStyle(
                                  color: AppConst.black,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom sheet with courier details / controls
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 16.h,
                bottom: 24.h + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: AppConst.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: AppConst.cardLight,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26.r,
                        backgroundColor: AppConst.white,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'C',
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
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
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  rating,
                                  style: TextStyle(
                                    color: AppConst.black,
                                    fontSize: 13.sp,
                                  ),
                                ),
                                if (eta.isNotEmpty || distance.isNotEmpty) ...[
                                  SizedBox(width: 8.w),
                                  Text(
                                    [
                                      eta,
                                      distance,
                                    ].where((e) => e.isNotEmpty).join(' • '),
                                    style: TextStyle(
                                      color: AppConst.grey,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppConst.black.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppConst.black,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Waiting for driver...',
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estimated fare',
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        estimatedFare,
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment',
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        paymentMethod,
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (courierId == null) {
                          AppSnackBar.error(
                            'common.error'.tr,
                            'Unable to cancel courier. Missing courier ID.',
                          );
                          return;
                        }

                        Get.dialog(
                          Material(
                            color: Colors.black.withOpacity(0.35),
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20.w,
                                  vertical: 16.h,
                                ),
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
                                      'courier.cancelling'.tr,
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
                          final storage = SecureStorageService();
                          final token = await storage.getAuthToken();
                          if (token == null || token.isEmpty) {
                            if (Get.isDialogOpen == true) Get.back();
                            AppSnackBar.error(
                              'common.error'.tr,
                              'You must be logged in to cancel courier.',
                            );
                            return;
                          }

                          final uri = Uri.parse(
                            '${ApiUrls.baseUrl}api/app/courier/$courierId/cancel',
                          );
                          final headers = <String, String>{
                            'Accept': 'application/json',
                            'Authorization': 'Bearer $token',
                          };

                          final response = await http.post(
                            uri,
                            headers: headers,
                          );

                          if (response.statusCode != 200 &&
                              response.statusCode != 201) {
                            String message = 'courier.cancel_failed'.tr;
                            try {
                              final decoded =
                                  jsonDecode(response.body)
                                      as Map<String, dynamic>;
                              if (decoded['message'] != null) {
                                message = decoded['message'].toString();
                              }
                            } catch (_) {}

                            if (Get.isDialogOpen == true) Get.back();
                            AppSnackBar.error('common.error'.tr, message);
                            return;
                          }

                          // Close dialog then route first to avoid Get.back() closing snackbar
                          if (Get.isDialogOpen == true) Get.back();
                          Get.back();
                          // Show snackbar on previous screen after route is popped
                          Future.microtask(() {
                            AppSnackBar.success(
                              'common.success'.tr,
                              'Courier has been cancelled.',
                            );
                          });
                        } catch (e) {
                          // ignore: avoid_print
                          print('CourierRequestDetailsScreen cancel error: $e');
                          if (Get.isDialogOpen == true) Get.back();
                          AppSnackBar.error(
                            'common.error'.tr,
                            'Something went wrong while cancelling courier.',
                          );
                        } finally {
                          if (Get.isDialogOpen == true) {
                            Get.back();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      child: Text(
                        'courier.cancel_ride'.tr,
                        style: TextStyle(
                          color: AppConst.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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

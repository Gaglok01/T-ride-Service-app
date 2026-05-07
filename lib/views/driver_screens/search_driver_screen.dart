import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../consts/appConst.dart';

class SearchDriverScreen extends StatefulWidget {
  const SearchDriverScreen({super.key});

  @override
  State<SearchDriverScreen> createState() => _SearchDriverScreenState();
}

class _SearchDriverScreenState extends State<SearchDriverScreen> {
  int _secondsElapsed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.white,
      body: Column(
        children: [
          // Top Header (Black Background)
          Container(
            decoration: BoxDecoration(color: AppConst.black),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10.h,
              bottom: 16.h,
              left: 20.w,
              right: 20.w,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                GestureDetector(
                  onTap: () {
                    _timer?.cancel();
                    Get.back();
                  },
                  child: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_forward
                        : Icons.arrow_back,
                    color: AppConst.white,
                    size: 24.sp,
                  ),
                ),
                // Title
                Text(
                  'ride.search_driver'.tr,
                  style: TextStyle(
                    color: AppConst.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Settings Icon
                Icon(Icons.settings, color: AppConst.white, size: 24.sp),
              ],
            ),
          ),
          // Location Details Card (White Card)
          Container(
            margin: EdgeInsets.all(16.w),
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
                    Text(
                      'Plot 504',
                      style: TextStyle(
                        color: AppConst.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppConst.black,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'Entrance',
                        style: TextStyle(
                          color: AppConst.white,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Add Button
                    GestureDetector(
                      onTap: () {
                        // TODO: Handle add location
                      },
                      child: Icon(
                        Icons.add,
                        color: AppConst.black,
                        size: 20.sp,
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
                    Text(
                      'Street 2',
                      style: TextStyle(
                        color: AppConst.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '~24 min.',
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
          // Map Section
          Expanded(
            child: Stack(
              children: [
                // Map Placeholder (Replace with actual map widget)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 64.sp, color: AppConst.grey),
                        SizedBox(height: 8.h),
                        Text(
                          'Map View',
                          style: TextStyle(
                            color: AppConst.grey,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Driver Icons (Green Cars)
                Positioned(
                  top: 100.h,
                  left: MediaQuery.of(context).size.width / 2 - 50.w,
                  child: Icon(
                    Icons.directions_car,
                    color: Colors.green,
                    size: 32.sp,
                  ),
                ),
                Positioned(
                  top: 250.h,
                  left: MediaQuery.of(context).size.width / 2 + 30.w,
                  child: Icon(
                    Icons.directions_car,
                    color: Colors.green,
                    size: 32.sp,
                  ),
                ),
                // Current Location Button (Bottom Right)
                Positioned(
                  bottom: 20.h,
                  right: 20.w,
                  child: GestureDetector(
                    onTap: () {
                      // TODO: Handle current location
                    },
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
              ],
            ),
          ),
          // Bottom Panel (Yellow Background)
          Container(
            decoration: BoxDecoration(
              color: AppConst.primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Container(
                    margin: EdgeInsets.only(top: 8.h),
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
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
                        // Finding Driver Text with Timer
                        Text(
                          '${'ride.finding_driver'.tr} ${_formatTime(_secondsElapsed)}',
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        // Cancel Ride Button
                        GestureDetector(
                          onTap: () {
                            _timer?.cancel();
                            Get.back();
                            // TODO: Handle cancel ride
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Center(
                              child: Text(
                                'ride.cancel'.tr,
                                style: TextStyle(
                                  color: AppConst.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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


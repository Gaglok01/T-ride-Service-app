import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_ride_rider_app/widgets/custom_appbar.dart';
import '../../consts/appConst.dart';
import 'rider_profile_screen.dart';

class Driver {
  final String name;
  final String distanceAway;
  final String pickupTime;
  final String dropoffTime;
  final String pickupLocation;
  final String dropoffLocation;
  final int filledSeats;
  final int totalSeats;

  Driver({
    required this.name,
    required this.distanceAway,
    required this.pickupTime,
    required this.dropoffTime,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.filledSeats,
    required this.totalSeats,
  });
}

class SelectDriverScreen extends StatefulWidget {
  const SelectDriverScreen({super.key});

  @override
  State<SelectDriverScreen> createState() => _SelectDriverScreenState();
}

class _SelectDriverScreenState extends State<SelectDriverScreen> {
  int? selectedDriverIndex = 0; // First driver selected by default

  final List<Driver> drivers = [
    Driver(
      name: 'Olive Rio',
      distanceAway: '10 mins away',
      pickupTime: '05:00PM',
      dropoffTime: '07:00PM',
      pickupLocation: 'Plot 505',
      dropoffLocation: 'Street 2',
      filledSeats: 2,
      totalSeats: 3,
    ),
    Driver(
      name: 'Tom Harry',
      distanceAway: '10 mins away',
      pickupTime: '05:00 PM',
      dropoffTime: '07:00 PM',
      pickupLocation: 'Plot 505',
      dropoffLocation: 'Street 2',
      filledSeats: 2,
      totalSeats: 3,
    ),
    Driver(
      name: 'John Leo',
      distanceAway: '10 mins away',
      pickupTime: '05:00 PM',
      dropoffTime: '07:00 PM',
      pickupLocation: 'Plot 505',
      dropoffLocation: 'Street 2',
      filledSeats: 2,
      totalSeats: 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          // Top Header (Black Background)
          CustomAppBar(title: 'appbar.select_driver'.tr),
          // Container(
          //   decoration: BoxDecoration(color: AppConst.black),
          //   padding: EdgeInsets.only(
          //     top: MediaQuery.of(context).padding.top + 10.h,
          //     bottom: 16.h,
          //     left: 20.w,
          //     right: 20.w,
          //   ),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       // Back Button
          //       GestureDetector(
          //         onTap: () {
          //           Get.back();
          //         },
          //         child: Icon(
          //           Icons.arrow_back,
          //           color: AppConst.white,
          //           size: 24.sp,
          //         ),
          //       ),
          //       // Title
          //       Text(
          //         '',
          //         style: TextStyle(
          //           color: AppConst.white,
          //           fontSize: 18.sp,
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //       // Settings Icon
          //       Icon(Icons.settings, color: AppConst.white, size: 24.sp),
          //     ],
          //   ),
          // ),
          // Driver List
          Expanded(
            child: Container(
              color: AppConst.background,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                itemCount: drivers.length,
                itemBuilder: (context, index) {
                  final driver = drivers[index];
                  final isSelected = selectedDriverIndex == index;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: _buildDriverCard(driver, index, isSelected),
                  );
                },
              ),
            ),
          ),
          // Confirm Button
          Container(
            padding: EdgeInsets.all(20.w),
            child: GestureDetector(
              onTap: () {
                if (selectedDriverIndex != null) {
                  Get.to(() => const RiderProfileScreen());
                }
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: AppConst.accent,
                  borderRadius: AppConst.buttonRadius,
                ),
                child: Center(
                  child: Text(
                    'ride.confirm_rider'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(Driver driver, int index, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDriverIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppConst.cardLight,
          borderRadius: AppConst.borderRadius,
          border: isSelected
              ? Border.all(color: AppConst.accent, width: 3)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture
            Column(
              children: [
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: AppConst.grey.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: AppConst.grey, size: 32.sp),
                ),
                SizedBox(height: 8.h),
                Text(
                  driver.name,
                  style: TextStyle(
                    color: AppConst.black,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  driver.distanceAway,
                  style: TextStyle(color: AppConst.grey, fontSize: 12.sp),
                ),
              ],
            ),
            SizedBox(width: 20.w),
            // Route Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route with Pickup and Drop-off
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Route Line
                      Column(
                        children: [
                          // Pickup Circle
                          Container(
                            width: 12.w,
                            height: 12.w,
                            decoration: BoxDecoration(
                              color: AppConst.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          // Vertical Line
                          Container(
                            width: 2.w,
                            height: 80.h,
                            color: AppConst.primaryColor,
                          ),
                          // Drop-off Circle
                          Container(
                            width: 12.w,
                            height: 12.w,
                            decoration: BoxDecoration(
                              color: AppConst.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 12.w),
                      // Route Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pickup Details
                            Text(
                              driver.pickupTime,
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              driver.pickupLocation,
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            // Seat Icons
                            Row(
                              children: List.generate(
                                driver.totalSeats,
                                (seatIndex) => Padding(
                                  padding: EdgeInsets.only(right: 6.w),
                                  child: Icon(
                                    Icons.chair,
                                    color: seatIndex < driver.filledSeats
                                        ? AppConst.primaryColor
                                        : AppConst.grey,
                                    size: 18.sp,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            // Drop-off Details
                            Text(
                              driver.dropoffTime,
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              driver.dropoffLocation,
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
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
    );
  }
}

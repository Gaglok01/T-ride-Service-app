import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../widgets/custom_appbar.dart';
import '../../consts/appConst.dart';
import '../driver_screens/rider_profile_screen.dart';

class Courier {
  final String name;
  final String distanceAway;
  final String pickupTime;
  final String dropoffTime;
  final String pickupLocation;
  final String dropoffLocation;

  Courier({
    required this.name,
    required this.distanceAway,
    required this.pickupTime,
    required this.dropoffTime,
    required this.pickupLocation,
    required this.dropoffLocation,
  });
}

class SelectCourierScreen extends StatefulWidget {
  const SelectCourierScreen({super.key});

  @override
  State<SelectCourierScreen> createState() => _SelectCourierScreenState();
}

class _SelectCourierScreenState extends State<SelectCourierScreen> {
  int? selectedCourierIndex = 0; // First courier selected by default

  final List<Courier> couriers = [
    Courier(
      name: 'Olive Rio',
      distanceAway: '10 mins away',
      pickupTime: '05:00PM',
      dropoffTime: '07:00PM',
      pickupLocation: 'Plot 505',
      dropoffLocation: 'Street 2',
    ),
    Courier(
      name: 'Tom Harry',
      distanceAway: '10 mins away',
      pickupTime: '05:00PM',
      dropoffTime: '07:00PM',
      pickupLocation: 'Plot 505',
      dropoffLocation: 'Street 2',
    ),
    Courier(
      name: 'John Leo',
      distanceAway: '10 mins away',
      pickupTime: '05:00PM',
      dropoffTime: '07:00PM',
      pickupLocation: 'Plot 505',
      dropoffLocation: 'Street 2',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          // Top Header (Black Background)
          CustomAppBar(title: 'appbar.select_courier'.tr),
          // Courier List
          Expanded(
            child: Container(
              color: AppConst.background,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                itemCount: couriers.length,
                itemBuilder: (context, index) {
                  final courier = couriers[index];
                  final isSelected = selectedCourierIndex == index;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: _buildCourierCard(courier, index, isSelected),
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
                if (selectedCourierIndex != null) {
                  Get.to(
                    () => const RiderProfileScreen(isCourierService: true),
                  );
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

  Widget _buildCourierCard(Courier courier, int index, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCourierIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppConst.cardLight,
          borderRadius: AppConst.borderRadius,
          border: isSelected
              ? Border.all(color: AppConst.black, width: 2)
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
                  courier.name,
                  style: TextStyle(
                    color: AppConst.black,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  courier.distanceAway,
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
                              courier.pickupTime,
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              courier.pickupLocation,
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            // Seat Icons (LLL)
                            Row(
                              children: List.generate(
                                3,
                                (seatIndex) => Padding(
                                  padding: EdgeInsets.only(right: 6.w),
                                  child: Icon(
                                    Icons.chair,
                                    color: AppConst.primaryColor,
                                    size: 18.sp,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            // Drop-off Details
                            Text(
                              courier.dropoffTime,
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              courier.dropoffLocation,
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

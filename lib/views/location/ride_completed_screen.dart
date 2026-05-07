import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../consts/appConst.dart';
import '../../widgets/custom_appbar.dart';
import '../custom_navbar/navbar.dart';

class RideCompletedScreen extends StatefulWidget {
  const RideCompletedScreen({super.key});

  @override
  State<RideCompletedScreen> createState() => _RideCompletedScreenState();
}

class _RideCompletedScreenState extends State<RideCompletedScreen> {
  int selectedRating = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          // Top Header
          CustomAppBar(title: 'appbar.ride_completed'.tr),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fare Summary Section
                  Text(
                    'ride.fare_summary'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: AppConst.borderRadius,
                    ),
                    child: Column(
                      children: [
                        _buildFareItem('Base Fare', '\$3.00'),
                        SizedBox(height: 12.h),
                        _buildFareItem('Distance Fare', '\$8.00'),
                        SizedBox(height: 12.h),
                        _buildFareItem('Time Fare', '\$2.00'),
                        SizedBox(height: 12.h),
                        _buildFareItem('Discount', '\$2.00'),
                        SizedBox(height: 12.h),
                        _buildFareItem('Tip', '50.00'),
                        SizedBox(height: 12.h),
                        Divider(
                          color: AppConst.grey.withOpacity(0.3),
                          thickness: 1,
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ride.total_fare'.tr,
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$15.00',
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  // Payment Status Section
                  Text(
                    'ride.payment_status'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: AppConst.borderRadius,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.money, color: AppConst.black, size: 24.sp),
                        SizedBox(width: 12.w),
                        Text(
                          'cash → Please pay your driver',
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  // Rate The Driver Section
                  Text(
                    'ride.rate_driver'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: AppConst.borderRadius,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Profile Picture
                            Container(
                              width: 60.w,
                              height: 60.w,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                color: AppConst.white,
                                size: 30.sp,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            // Driver Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Olive Rio',
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
                                        color: AppConst.primaryColor,
                                        size: 16.sp,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        '4.9 (2160+ rides)',
                                        style: TextStyle(
                                          color: AppConst.black,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'White Honda City',
                                    style: TextStyle(
                                      color: AppConst.black,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        // Rating Stars
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            5,
                            (index) => GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedRating = index + 1;
                                });
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.w),
                                child: Icon(
                                  index < selectedRating
                                      ? Icons.star
                                      : Icons.star_outline,
                                  color: AppConst.primaryColor,
                                  size: 32.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
          // Done Button
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(color: AppConst.transparent),
            child: GestureDetector(
              onTap: () {
                // Navigate back to Navbar, clearing all previous routes
                Get.offAll(() => const Navbar());
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: AppConst.black,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: AppConst.white,
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

  Widget _buildFareItem(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: AppConst.black, fontSize: 14.sp),
        ),
        Text(
          amount,
          style: TextStyle(color: AppConst.black, fontSize: 14.sp),
        ),
      ],
    );
  }
}

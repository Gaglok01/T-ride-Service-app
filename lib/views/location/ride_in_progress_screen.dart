import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../consts/appConst.dart';
import '../../widgets/custom_appbar.dart';
import 'ride_completed_screen.dart';

class RideInProgressScreen extends StatefulWidget {
  const RideInProgressScreen({super.key});

  @override
  State<RideInProgressScreen> createState() => _RideInProgressScreenState();
}

class _RideInProgressScreenState extends State<RideInProgressScreen> {
  int? selectedTip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.white,
      body: Column(
        children: [
          // Top Header
          CustomAppBar(title: 'appbar.ride_in_progress'.tr),
          // Map Section
          Expanded(
            child: Stack(
              children: [
                // Map Placeholder
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
                          'ride_progress.map_view'.tr,
                          style: TextStyle(
                            color: AppConst.grey,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Location Details Card
                Positioned(
                  top: 16.h,
                  left: 16.w,
                  child: Container(
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
                            Icon(Icons.add, color: AppConst.black, size: 20.sp),
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
                              '-24 min.',
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
                ),
                // Arrival Time Indicator
                Positioned(
                  bottom: 200.h,
                  left: 20.w,
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          '4 MIN',
                          style: TextStyle(
                            color: AppConst.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      CustomPaint(
                        size: Size(16.w, 8.h),
                        painter: TrianglePainter(color: Colors.orange),
                      ),
                    ],
                  ),
                ),
                // Estimated Arrival Text
                Positioned(
                  bottom: 180.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Estimated Arrival: 12 minutes',
                      style: TextStyle(
                        color: AppConst.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                // Car Icon on Route
                Positioned(
                  bottom: 250.h,
                  left: MediaQuery.of(context).size.width / 2,
                  child: Icon(
                    Icons.directions_car,
                    color: AppConst.black,
                    size: 32.sp,
                  ),
                ),
              ],
            ),
          ),
          // Driver Details Panel (Yellow Background)
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
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag Handle and Bell Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            margin: EdgeInsets.only(bottom: 16.h),
                            width: 40.w,
                            height: 4.h,
                            decoration: BoxDecoration(
                              color: AppConst.cardLight,
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                          Icon(
                            Icons.notifications,
                            color: Colors.red,
                            size: 24.sp,
                          ),
                        ],
                      ),
                      // Driver Profile Section
                      Row(
                        children: [
                          // Profile Picture
                          Container(
                            width: 80.w,
                            height: 80.w,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              color: AppConst.white,
                              size: 40.sp,
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
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: AppConst.primaryColor,
                                      size: 18.sp,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      '4.9 (2160+ rides)',
                                      style: TextStyle(
                                        color: AppConst.black,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'White Honda City',
                                  style: TextStyle(
                                    color: AppConst.black,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Call and Chat Buttons
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  // TODO: Handle call
                                },
                                child: Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: AppConst.cardLight,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Icon(
                                    Icons.phone,
                                    color: AppConst.black,
                                    size: 24.sp,
                                  ),
                                ),
                              ),
                              SizedBox(height: 12.h),
                              GestureDetector(
                                onTap: () {
                                  // TODO: Handle chat
                                },
                                child: Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: AppConst.cardLight,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline,
                                    color: AppConst.black,
                                    size: 24.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      // Select Tip Section
                      Text(
                        'ride_progress.tip_driver'.tr,
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(child: _buildTipButton(50, 0)),
                          SizedBox(width: 12.w),
                          Expanded(child: _buildTipButton(100, 1)),
                          SizedBox(width: 12.w),
                          Expanded(child: _buildTipButton(150, 2)),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      // Cancel Ride Button
                      GestureDetector(
                        onTap: () {
                          Get.to(() => const RideCompletedScreen());
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
                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipButton(int amount, int index) {
    final isSelected = selectedTip == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTip = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: AppConst.cardLight,
          borderRadius: BorderRadius.circular(12.r),
          border: isSelected
              ? Border.all(color: AppConst.black, width: 2)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.attach_money, color: AppConst.black, size: 18.sp),
            SizedBox(width: 4.w),
            Text(
              amount.toString(),
              style: TextStyle(
                color: AppConst.black,
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for triangle pointer
class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

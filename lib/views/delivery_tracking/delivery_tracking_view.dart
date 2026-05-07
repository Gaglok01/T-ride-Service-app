import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../consts/appConst.dart';
import '../../widgets/custom_appbar.dart';

class DeliveryTrackingView extends StatefulWidget {
  const DeliveryTrackingView({super.key});

  @override
  State<DeliveryTrackingView> createState() => _DeliveryTrackingViewState();
}

class _DeliveryTrackingViewState extends State<DeliveryTrackingView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade100,
      body: Stack(
        children: [
          Column(
            children: [
              // Top Header
              CustomAppBar(title: 'appbar.delivery_tracking'.tr),
              // Map Section - Takes full remaining space
              Expanded(
                child: Stack(
                  children: [
                    // Map Image
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.brown.shade100),
                      child: Image.asset(
                        'assets/map_placeholder.png', // You can replace this with your map image
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback if image doesn't exist
                          return Container(
                            color: Colors.brown.shade100,
                            child: Center(
                              child: Icon(
                                Icons.map,
                                color: Colors.brown.shade300,
                                size: 100.sp,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Current Location Pin with Time
                    Positioned(
                      top: 60.h,
                      left: 40.w,
                      child: Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.orange, width: 3),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Container(
                                width: 12.w,
                                height: 12.w,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -25.h,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  '4 MIN',
                                  style: TextStyle(
                                    color: AppConst.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Destination Icon
                    Positioned(
                      bottom: 100.h,
                      right: 60.w,
                      child: Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: AppConst.black,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Icon(
                          Icons.send,
                          color: AppConst.white,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Persistent Bottom Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppConst.primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.r),
                    topRight: Radius.circular(20.r),
                  ),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag Handle
                        Center(
                          child: Container(
                            width: 40.w,
                            height: 4.h,
                            margin: EdgeInsets.only(bottom: 16.h),
                            decoration: BoxDecoration(
                              color: AppConst.cardLight,
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                        ),
                        // Delivery Status
                        Text(
                          'Out for delivery',
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        // Timeline
                        _buildTimeline(),
                        SizedBox(height: 32.h),
                        // Estimated Delivery Time
                        Text(
                          'Estimated delivery time',
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '8:25pm - 8:30pm',
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 32.h),
                        // Driver Information
                        Row(
                          children: [
                            // Profile Picture
                            Container(
                              width: 60.w,
                              height: 60.w,
                              decoration: BoxDecoration(
                                color: AppConst.grey.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                color: AppConst.grey,
                                size: 40.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Olive Rio',
                                    style: TextStyle(
                                      color: AppConst.black,
                                      fontSize: 18.sp,
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
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Your rider',
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
                        SizedBox(height: 32.h),
                        // Contact Buttons
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // TODO: Handle call
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  decoration: BoxDecoration(
                                    color: AppConst.cardLight,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        color: AppConst.black,
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Call',
                                        style: TextStyle(
                                          color: AppConst.black,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // TODO: Handle chat
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  decoration: BoxDecoration(
                                    color: AppConst.cardLight,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        color: AppConst.black,
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Chat',
                                        style: TextStyle(
                                          color: AppConst.black,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: [
        // Timeline Circles with connecting lines
        Row(
          children: [
            _buildTimelineCircle(true),
            Expanded(
              child: Container(height: 2.h, color: AppConst.black),
            ),
            _buildTimelineCircle(true),
            Expanded(
              child: Container(height: 2.h, color: AppConst.black),
            ),
            _buildTimelineCircle(true),
            Expanded(
              child: Container(
                height: 2.h,
                color: AppConst.grey.withOpacity(0.3),
              ),
            ),
            _buildTimelineCircle(false),
          ],
        ),
        SizedBox(height: 8.h),
        // Timeline Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Ordered',
                style: TextStyle(
                  color: AppConst.black,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Text(
                'Preparing your meal',
                style: TextStyle(
                  color: AppConst.black,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                'Out for delivery',
                style: TextStyle(
                  color: AppConst.black,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                'Delivered',
                style: TextStyle(
                  color: AppConst.black,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineCircle(bool isCompleted) {
    return Container(
      width: 16.w,
      height: 16.w,
      decoration: BoxDecoration(
        color: isCompleted ? AppConst.black : AppConst.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppConst.black, width: 2),
      ),
    );
  }
}

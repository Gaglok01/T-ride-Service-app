import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../consts/appConst.dart';
import '../../widgets/custom_appbar.dart';
import 'courier_progress_screen.dart';

class CourierOtpScreen extends StatefulWidget {
  const CourierOtpScreen({super.key});

  @override
  State<CourierOtpScreen> createState() => _CourierOtpScreenState();
}

class _CourierOtpScreenState extends State<CourierOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.white,
      body: Column(
        children: [
          // Top Header
          CustomAppBar(title: 'appbar.courier_details'.tr),
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
                // Arriving Text
                Positioned(
                  bottom: 180.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'courier.arriving_in'.tr,
                      style: TextStyle(
                        color: AppConst.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                // Current Location Button
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
          // Courier Details Panel (Yellow Background)
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
                      // Drag Handle
                      Center(
                        child: Container(
                          margin: EdgeInsets.only(bottom: 16.h),
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: AppConst.cardLight,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                      // Courier Profile Section
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
                          // Courier Info
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
                                      '4.9 (2160+ couriers)',
                                      style: TextStyle(
                                        color: AppConst.black,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Platinum courier',
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
                      // Car Details
                      Text(
                        'T-Go',
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'White Honda City',
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Number: ABC-3456',
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Call and Chat Buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // TODO: Handle call
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
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
                                      'common.call'.tr,
                                      style: TextStyle(
                                        color: AppConst.black,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
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
                                padding: EdgeInsets.symmetric(vertical: 12.h),
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
                                      'common.chat'.tr,
                                      style: TextStyle(
                                        color: AppConst.black,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
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
                      // Pickup Code Section
                      Text(
                        'courier.pickup_code'.tr,
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Share this 4-digit code with the courier at pickup',
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      // OTP Input Fields
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          4,
                          (index) => Container(
                            width: 60.w,
                            height: 60.w,
                            decoration: BoxDecoration(
                              color: AppConst.cardLight,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: AppConst.grey.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) => _onCodeChanged(index, value),
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Confirm Courier Button
                      GestureDetector(
                        onTap: () {
                          Get.to(() => const CourierProgressScreen());
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
                              'courier.confirm'.tr,
                              style: TextStyle(
                                color: AppConst.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      // Cancel Courier Button
                      GestureDetector(
                        onTap: () {
                          // TODO: Handle cancel courier
                          Get.back();
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
                              'courier.cancel'.tr,
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


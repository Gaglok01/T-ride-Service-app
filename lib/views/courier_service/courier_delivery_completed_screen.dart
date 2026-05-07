import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../consts/appConst.dart';
import '../../widgets/custom_appbar.dart';
import '../custom_navbar/navbar.dart';

class CourierDeliveryCompletedScreen extends StatefulWidget {
  const CourierDeliveryCompletedScreen({super.key});

  @override
  State<CourierDeliveryCompletedScreen> createState() =>
      _CourierDeliveryCompletedScreenState();
}

class _CourierDeliveryCompletedScreenState
    extends State<CourierDeliveryCompletedScreen> {
  int selectedRating = 4;
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
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          // Top Header
          CustomAppBar(title: 'appbar.delivered_success'.tr),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery Proof Section
                  Text(
                    'courier.delivery_proof'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: AppConst.black,
                      borderRadius: AppConst.borderRadius,
                    ),
                    child: Center(
                      child: Container(
                        width: 70.w,
                        height: 70.w,
                        decoration: BoxDecoration(
                          color: AppConst.cardLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          color: AppConst.grey,
                          size: 30.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  // Delivery Code Verification Section
                  Text(
                    'courier.code_verification'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Ask the receiver for the delivery code',
                    style: TextStyle(color: AppConst.black, fontSize: 14.sp),
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
                  SizedBox(height: 16.h),
                  // Verify Code Button
                  GestureDetector(
                    onTap: () {
                      // TODO: Handle verify code
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        color: AppConst.cardLight,
                        borderRadius: AppConst.borderRadius,
                      ),
                      child: Center(
                        child: Text(
                          'courier.verify_code'.tr,
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  // Rate The Driver Section
                  Text(
                    'courier.rate_driver'.tr,
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
                                        '4.9 (2160+ couriers)',
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
                    'common.done'.tr,
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
}

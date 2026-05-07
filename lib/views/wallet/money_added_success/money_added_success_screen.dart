import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../consts/appConst.dart';

class MoneyAddedSuccessScreen extends StatelessWidget {
  const MoneyAddedSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: AppConst.black,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20.r),
                bottomRight: Radius.circular(20.r),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Get.back(result: false),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Directionality.of(context) == TextDirection.rtl
                              ? Icons.arrow_forward
                              : Icons.arrow_back,
                          color: AppConst.white,
                          size: 24.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'wallet.money_added'.tr,
                          style: TextStyle(
                            color: AppConst.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO: Handle settings
                    },
                    child: Icon(
                      Icons.settings,
                      color: AppConst.white,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Checkmark Icon
                  Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green, width: 3),
                    ),
                    child: Icon(Icons.check, color: Colors.green, size: 80.sp),
                  ),
                  SizedBox(height: 32.h),
                  // Main Message
                  Text(
                    'Money Added Successfully',
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  // Descriptive Message
                  Text(
                    'wallet.money_added_body'.tr,
                    style: TextStyle(color: AppConst.black, fontSize: 16.sp),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 60.h),
                ],
              ),
            ),
          ),
          // Continue Button
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppConst.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: AppConst.blackWithOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () {
                // Signal success to previous screen
                Get.back(result: true);
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
                    'common.continue'.tr,
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
}

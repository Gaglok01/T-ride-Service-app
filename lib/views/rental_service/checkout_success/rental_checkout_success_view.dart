import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_ride_rider_app/widgets/custom_appbar.dart';
import '../../../consts/appConst.dart';
import '../../custom_navbar/navbar.dart';

class RentalCheckoutSuccessView extends StatelessWidget {
  const RentalCheckoutSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          // Top Header
          CustomAppBar(title: 'appbar.checkout'.tr),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 60.h),
                  // Success Checkmark Icon
                  Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.green,
                        width: 4,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 80.sp,
                    ),
                  ),
                  SizedBox(height: 32.h),
                  // Success Message
                  Text(
                    'Thank you for submitting your details!',
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20.h),
                  // Detailed Message
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      'We have successfully received your information. Our team will review your submission and get in touch with you shortly. Please keep an eye on your email or phone for updates. Your request will be processed as soon as possible, and we appreciate your patience.',
                      style: TextStyle(
                        color: AppConst.black,
                        fontSize: 14.sp,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 60.h),
                ],
              ),
            ),
          ),
          // Done Button
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppConst.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: AppConst.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
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
}


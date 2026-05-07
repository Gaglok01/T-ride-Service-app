import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../consts/appConst.dart';
import '../../widgets/custom_appbar.dart';
import 'add_new_address_screen.dart';
import '../delivery_tracking/delivery_tracking_view.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address Cards
                  _buildAddressCard(
                    title: 'checkout.home'.tr,
                    address: 'Street 123, plot 7, City',
                    phoneNumber: '+123 456 67890',
                    icon: Icons.home,
                  ),
                  SizedBox(height: 16.h),
                  _buildAddressCard(
                    title: 'checkout.warehouse'.tr,
                    address: 'Street 123, plot 7, City',
                    phoneNumber: '+123 456 67890',
                    icon: Icons.home,
                  ),
                ],
              ),
            ),
          ),
          // Bottom Action Buttons
          Padding(
            padding: EdgeInsets.all(20.w),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Continue Button
                  GestureDetector(
                    onTap: () {
                      Get.to(() => const DeliveryTrackingView());
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
                  SizedBox(height: 12.h),
                  // Add New Address Button
                  GestureDetector(
                    onTap: () {
                      Get.to(() => const AddNewAddressScreen());
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        color: AppConst.grey,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Center(
                        child: Text(
                          'checkout.add_address'.tr,
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
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard({
    required String title,
    required String address,
    required String phoneNumber,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppConst.cardLight,
        borderRadius: AppConst.borderRadius,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppConst.black, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppConst.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Address: $address',
                  style: TextStyle(color: AppConst.black, fontSize: 14.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Phone number: $phoneNumber',
                  style: TextStyle(color: AppConst.black, fontSize: 14.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

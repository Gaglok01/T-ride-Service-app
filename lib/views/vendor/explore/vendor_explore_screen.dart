import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_ride_rider_app/widgets/custom_appbar.dart';
import '../../../consts/appConst.dart';
import '../upload_menu/vendor_upload_menu_screen.dart';
import '../upload_add_to_cart/vendor_upload_add_to_cart_screen.dart';
import '../orders/vendor_orders_screen.dart';
import '../earnings/vendor_earnings_screen.dart';
import '../registration/vendor_profile_setup.dart';

class VendorExploreScreen extends StatelessWidget {
  const VendorExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          CustomAppBar(title: 'appbar.explore'.tr),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
              child: Column(
                children: [
                  SizedBox(height: 40.h),
                  // Upload Menu Button
                  _buildExploreButton(
                    title: 'vendor.upload_menu'.tr,
                    onTap: () {
                      Get.to(() => const VendorUploadMenuScreen());
                    },
                  ),
                  SizedBox(height: 20.h),
                  // Upload add to cart Button
                  _buildExploreButton(
                    title: 'vendor.upload_cart'.tr,
                    onTap: () {
                      Get.to(() => const VendorUploadAddToCartScreen());
                    },
                  ),
                  SizedBox(height: 20.h),
                  // Check Orders Button
                  _buildExploreButton(
                    title: 'vendor.check_orders'.tr,
                    onTap: () {
                      Get.to(() => const VendorOrdersScreen());
                    },
                  ),
                  SizedBox(height: 20.h),
                  // Check Earnings Button
                  _buildExploreButton(
                    title: 'vendor.check_earnings'.tr,
                    onTap: () {
                      Get.to(() => const VendorEarningsScreen());
                    },
                  ),
                  SizedBox(height: 20.h),
                  // Profile Button
                  _buildExploreButton(
                    title: 'vendor.profile'.tr,
                    onTap: () {
                      Get.to(() => const VendorProfileSetup());
                    },
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreButton({
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: AppConst.cardLight,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(12.r),
            bottomLeft: Radius.circular(12.r),
          ),
          boxShadow: [
            BoxShadow(
              color: AppConst.blackWithOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: AppConst.black,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

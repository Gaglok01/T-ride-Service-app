import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../consts/appConst.dart';
import '../../widgets/custom_appbar.dart';

class AddNewAddressScreen extends StatefulWidget {
  const AddNewAddressScreen({super.key});

  @override
  State<AddNewAddressScreen> createState() => _AddNewAddressScreenState();
}

class _AddNewAddressScreenState extends State<AddNewAddressScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          // Top Header
          CustomAppBar(title: 'appbar.add_address'.tr),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Field
                  Text(
                    'common.name'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your full name (e.g. John Doe)',
                        hintStyle: TextStyle(
                          color: AppConst.grey,
                          fontSize: 14.sp,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16.w),
                      ),
                      style: TextStyle(color: AppConst.black, fontSize: 14.sp),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Phone Number Field
                  Text(
                    'common.phone'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Enter your phone number',
                        hintStyle: TextStyle(
                          color: AppConst.grey,
                          fontSize: 14.sp,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16.w),
                      ),
                      style: TextStyle(color: AppConst.black, fontSize: 14.sp),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Street & Plot no Field
                  Text(
                    'checkout.street_plot'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: TextField(
                      controller: _streetController,
                      decoration: InputDecoration(
                        hintText: 'Enter your Street & Plot no',
                        hintStyle: TextStyle(
                          color: AppConst.grey,
                          fontSize: 14.sp,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16.w),
                      ),
                      style: TextStyle(color: AppConst.black, fontSize: 14.sp),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // City Field
                  Text(
                    'common.city'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: TextField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        hintText: 'Enter your city',
                        hintStyle: TextStyle(
                          color: AppConst.grey,
                          fontSize: 14.sp,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16.w),
                      ),
                      style: TextStyle(color: AppConst.black, fontSize: 14.sp),
                    ),
                  ),
                  SizedBox(height: 100.h), // Space for bottom button
                ],
              ),
            ),
          ),
          // Bottom Action Button
          Padding(
            padding: EdgeInsets.all(20.w),
            child: SafeArea(
              child: GestureDetector(
                onTap: () {
                  // TODO: Save address and go back
                  Get.back();
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
                      'checkout.save_exit'.tr,
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
          ),
        ],
      ),
    );
  }
}

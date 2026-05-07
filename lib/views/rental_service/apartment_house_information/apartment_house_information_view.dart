import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_ride_rider_app/widgets/custom_appbar.dart';
import '../../../consts/appConst.dart';
import '../document_upload/document_upload_view.dart';

class ApartmentHouseInformationView extends StatefulWidget {
  const ApartmentHouseInformationView({super.key});

  @override
  State<ApartmentHouseInformationView> createState() =>
      _ApartmentHouseInformationViewState();
}

class _ApartmentHouseInformationViewState
    extends State<ApartmentHouseInformationView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _visitDateTimeController =
      TextEditingController();
  final TextEditingController _occupantsController = TextEditingController();
  final TextEditingController _moveInDateController = TextEditingController();
  final TextEditingController _specialRequestController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _visitDateTimeController.dispose();
    _occupantsController.dispose();
    _moveInDateController.dispose();
    _specialRequestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          // Top Header
          CustomAppBar(title: 'appbar.enter_information'.tr),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Field
                  Text(
                    'Name',
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
                    'Phone number',
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
                  // Preferred Visit Date & Time Slot Field
                  Text(
                    'Preferred Visit Date & Time Slot',
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
                      controller: _visitDateTimeController,
                      readOnly: true,
                      onTap: () {
                        // TODO: Show date and time picker
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter your preferred visit date/time slot',
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
                  // Number of Occupants Field
                  Text(
                    'Number of Occupants',
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
                      controller: _occupantsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter your number of occupants',
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
                  // Move-in Date (Expected) Field
                  Text(
                    'Move-in Date (Expected)',
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
                      controller: _moveInDateController,
                      readOnly: true,
                      onTap: () {
                        // TODO: Show date picker
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter your move-in date (expected)',
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
                  // Special Request Field
                  Text(
                    'Special Request:',
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
                      controller: _specialRequestController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Enter your special request',
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
                  SizedBox(height: 40.h),
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
                  color: AppConst.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () {
                Get.to(() => const DocumentUploadView());
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
                    'Continue',
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


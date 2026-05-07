import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_ride_rider_app/views/vendor/explore/vendor_explore_screen.dart';
import 'package:t_ride_rider_app/widgets/custom_appbar.dart';
import 'package:t_ride_rider_app/widgets/custom_textfield.dart';
import '../../../consts/appConst.dart';
import '../../custom_navbar/navbar.dart';

class VendorProfileSetup extends StatefulWidget {
  const VendorProfileSetup({super.key});

  @override
  State<VendorProfileSetup> createState() => _VendorProfileSetupState();
}

class _VendorProfileSetupState extends State<VendorProfileSetup> {
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _businessTimingsController =
      TextEditingController();

  String? _selectedStatusBadge = 'Active';
  String? _selectedDeliveryAvailability;

  @override
  void dispose() {
    _shopNameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _businessTimingsController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _shopNameController.text.isNotEmpty &&
        _contactController.text.isNotEmpty &&
        _cityController.text.isNotEmpty &&
        _businessTimingsController.text.isNotEmpty &&
        _selectedDeliveryAvailability != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          CustomAppBar(title: 'appbar.vendor_profile'.tr),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
              child: Column(
                children: [
                  SizedBox(height: 20.h),
                  // Profile Picture Section
                  Stack(
                    children: [
                      Container(
                        width: 120.w,
                        height: 120.w,
                        decoration: BoxDecoration(
                          color: AppConst.cardLight,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppConst.blackWithOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person,
                          size: 60.sp,
                          color: AppConst.grey,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            // TODO: Handle profile picture upload
                          },
                          child: Container(
                            width: 36.w,
                            height: 36.w,
                            decoration: BoxDecoration(
                              color: AppConst.black,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppConst.white,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: AppConst.white,
                              size: 18.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40.h),
                  // Shop / Business Name
                  _buildLabel('Shop / Business Name'),
                  SizedBox(height: 8.h),
                  CustomTextField(
                    controller: _shopNameController,
                    hintText: 'Enter your Shop / Business Name',
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 20.h),
                  // Contact
                  _buildLabel('Contact'),
                  SizedBox(height: 8.h),
                  CustomTextField(
                    controller: _contactController,
                    hintText: 'Enter your contact number',
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 20.h),
                  // Address
                  _buildLabel('Address'),
                  SizedBox(height: 8.h),
                  CustomTextField(
                    controller: _addressController,
                    hintText: 'Enter your address (optional)',
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 20.h),
                  // City
                  _buildLabel('City'),
                  SizedBox(height: 8.h),
                  CustomTextField(
                    controller: _cityController,
                    hintText: 'Enter your city',
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 20.h),
                  // Business Timings
                  _buildLabel('Business Timings'),
                  SizedBox(height: 8.h),
                  CustomTextField(
                    controller: _businessTimingsController,
                    hintText: 'Enter your business timings',
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 30.h),
                  // Status Badge
                  _buildLabel('Status Badge'),
                  SizedBox(height: 12.h),
                  _buildStatusBadgeSelector(),
                  SizedBox(height: 30.h),
                  // Delivery Availability
                  _buildLabel('Delivery Availability'),
                  SizedBox(height: 12.h),
                  _buildDeliveryAvailabilitySelector(),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
          // Save Profile Button
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
                // TODO: Save vendor profile
                // Navigate to home screen
                Get.offAll(() => const VendorExploreScreen());
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: _isFormValid()
                      ? AppConst.black
                      : AppConst.blackWithOpacity(0.5),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    'vendor.save_profile'.tr,
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

  Widget _buildLabel(String label) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppConst.black,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadgeSelector() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatusBadge = 'Active';
        });
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: AppConst.cardLight,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(12.r),
            bottomLeft: Radius.circular(12.r),
          ),
          border: Border.all(color: AppConst.black, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppConst.blackWithOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          _selectedStatusBadge ?? 'vendor.active'.tr,
          style: TextStyle(
            color: AppConst.black,
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            decoration: _selectedStatusBadge == 'Active'
                ? TextDecoration.underline
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryAvailabilitySelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDeliveryAvailability = 'Yes';
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
              decoration: BoxDecoration(
                color: AppConst.cardLight,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12.r),
                  bottomLeft: Radius.circular(12.r),
                ),
                border: _selectedDeliveryAvailability == 'Yes'
                    ? Border.all(color: AppConst.black, width: 2)
                    : null,
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
                  'Yes',
                  style: TextStyle(
                    color: AppConst.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    decoration: _selectedDeliveryAvailability == 'Yes'
                        ? TextDecoration.underline
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDeliveryAvailability = 'No';
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
              decoration: BoxDecoration(
                color: AppConst.cardLight,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12.r),
                  bottomLeft: Radius.circular(12.r),
                ),
                border: _selectedDeliveryAvailability == 'No'
                    ? Border.all(color: AppConst.black, width: 2)
                    : null,
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
                  'No',
                  style: TextStyle(
                    color: AppConst.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    decoration: _selectedDeliveryAvailability == 'No'
                        ? TextDecoration.underline
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

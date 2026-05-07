import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../consts/appConst.dart';

class VendorUploadAddToCartScreen extends StatefulWidget {
  const VendorUploadAddToCartScreen({super.key});

  @override
  State<VendorUploadAddToCartScreen> createState() =>
      _VendorUploadAddToCartScreenState();
}

class _VendorUploadAddToCartScreenState
    extends State<VendorUploadAddToCartScreen> {
  final TextEditingController _specialInstructionsController =
      TextEditingController();
  int _quantity = 1;
  bool _frequentlyBoughtItemSelected = false;

  @override
  void dispose() {
    _specialInstructionsController.dispose();
    super.dispose();
  }

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
                    onTap: () => Get.back(),
                    child: Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.arrow_forward
                          : Icons.arrow_back,
                      color: AppConst.white,
                      size: 24.sp,
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
          // Image Placeholder (White Section)
          Container(
            width: double.infinity,

            decoration: BoxDecoration(
              color: AppConst.cardLight,
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(20.r),
                bottomLeft: Radius.circular(20.r),
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 30.h),
            child: Center(
              child: Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: AppConst.black,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: AppConst.white,
                  size: 50.sp,
                ),
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Details Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Name',
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Text(
                                  'Price',
                                  style: TextStyle(
                                    color: AppConst.black,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Price',
                                  style: TextStyle(
                                    color: AppConst.grey,
                                    fontSize: 14.sp,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'Description',
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Quantity Selector
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppConst.cardLight,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: AppConst.black, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_quantity > 1) {
                                  setState(() {
                                    _quantity--;
                                  });
                                }
                              },
                              child: Icon(
                                Icons.remove,
                                color: AppConst.black,
                                size: 20.sp,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Text(
                              '$_quantity',
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _quantity++;
                                });
                              },
                              child: Icon(
                                Icons.add,
                                color: AppConst.black,
                                size: 20.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30.h),
                  // Frequently bought together Section
                  Text(
                    'Frequently bought together',
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Description',
                    style: TextStyle(color: AppConst.black, fontSize: 14.sp),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12.r),
                        bottomLeft: Radius.circular(12.r),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50.w,
                          height: 50.w,
                          decoration: BoxDecoration(
                            color: AppConst.black,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: AppConst.white,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Name',
                                style: TextStyle(
                                  color: AppConst.black,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '+ Price',
                                style: TextStyle(
                                  color: AppConst.black,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _frequentlyBoughtItemSelected =
                                  !_frequentlyBoughtItemSelected;
                            });
                          },
                          child: Container(
                            width: 24.w,
                            height: 24.w,
                            decoration: BoxDecoration(
                              color: _frequentlyBoughtItemSelected
                                  ? AppConst.black
                                  : AppConst.white,
                              border: Border.all(
                                color: AppConst.black,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: _frequentlyBoughtItemSelected
                                ? Icon(
                                    Icons.check,
                                    color: AppConst.white,
                                    size: 16.sp,
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30.h),
                  // Special instructions Section
                  Text(
                    'Special instructions',
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Description',
                    style: TextStyle(color: AppConst.black, fontSize: 14.sp),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppConst.white, width: 1),
                    ),
                    child: TextField(
                      controller: _specialInstructionsController,
                      maxLines: 4,
                      maxLength: 500,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'e.g. no mayo',
                        hintStyle: TextStyle(
                          color: AppConst.grey,
                          fontSize: 14.sp,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16.w),
                        counterText:
                            '${_specialInstructionsController.text.length}/500',
                        counterStyle: TextStyle(
                          color: AppConst.grey,
                          fontSize: 12.sp,
                        ),
                      ),
                      style: TextStyle(color: AppConst.black, fontSize: 14.sp),
                    ),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
          // Action Buttons
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
            child: Column(
              children: [
                // Add To Cart Button
                GestureDetector(
                  onTap: () {
                    // TODO: Handle add to cart
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      color: AppConst.black,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12.r),
                        bottomLeft: Radius.circular(12.r),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Add To Cart',
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
                // Cancel Button
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12.r),
                        bottomLeft: Radius.circular(12.r),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Cancel',
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
        ],
      ),
    );
  }
}

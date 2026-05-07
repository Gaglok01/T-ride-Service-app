import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_ride_rider_app/widgets/custom_appbar.dart';
import '../../consts/appConst.dart';
import '../../widgets/add_to_cart_view.dart';

class AddToCartView extends StatefulWidget {
  final String foodName;
  final double price;
  final double originalPrice;

  const AddToCartView({
    super.key,
    required this.foodName,
    required this.price,
    required this.originalPrice,
  });

  @override
  State<AddToCartView> createState() => _AddToCartViewState();
}

class _AddToCartViewState extends State<AddToCartView> {
  int quantity = 1;
  bool isSoftDrinkSelected = false;
  final TextEditingController _instructionsController = TextEditingController();

  static const double _softDrinkPrice = 2.05;

  double _calcTotalPrice() {
    final itemTotal = widget.price * quantity;
    final softDrinkTotal = isSoftDrinkSelected ? _softDrinkPrice : 0.0;
    return itemTotal + softDrinkTotal;
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _calcTotalPrice();
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          // Top Header (Black Background)
          CustomAppBar(title: 'appbar.add_to_cart'.tr),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food Image
                  Padding(
                    padding: EdgeInsets.all(8.w),
                    child: Container(
                      height: 250.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppConst.grey.withOpacity(0.2),
                        borderRadius: AppConst.borderRadius,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: ClipRRect(
                              borderRadius: AppConst.borderRadius,
                              child: Image.asset(
                                'assets/Rectangle 28.png',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Food Details Section
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Food Name and Price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.foodName,
                                    style: TextStyle(
                                      color: AppConst.black,
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Row(
                                    children: [
                                      Text(
                                        '\$${widget.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: AppConst.black,
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        '\$${widget.originalPrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: AppConst.grey,
                                          fontSize: 16.sp,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Total: \$${total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: AppConst.black,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 10.h),
                                  Text(
                                    'Creamy white sauce with parmesan & herbs',
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
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppConst.transparent,
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: AppConst.black,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints.tight(
                                      Size(34.w, 34.w),
                                    ),
                                    icon: Icon(
                                      Icons.remove,
                                      color: AppConst.black,
                                      size: 18.sp,
                                    ),
                                    onPressed: () {
                                      if (quantity > 1) {
                                        setState(() => quantity--);
                                      }
                                    },
                                  ),
                                  SizedBox(width: 14.w),
                                  Text(
                                    quantity.toString(),
                                    style: TextStyle(
                                      color: AppConst.black,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 14.w),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints.tight(
                                      Size(34.w, 34.w),
                                    ),
                                    icon: Icon(
                                      Icons.add,
                                      color: AppConst.black,
                                      size: 18.sp,
                                    ),
                                    onPressed: () {
                                      setState(() => quantity++);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32.h),
                        // Frequently bought together
                        Text(
                          'Frequently bought together',
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Other customers also ordered these.',
                          style: TextStyle(
                            color: AppConst.grey,
                            fontSize: 10.sp,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        // Soft Drink Item
                        Row(
                          children: [
                            // Drink Image Placeholder - Rounded
                            Container(
                              width: 70.w,
                              height: 70.w,
                              decoration: BoxDecoration(
                                color: AppConst.grey.withValues(alpha: 0.2),
                                borderRadius: AppConst.borderRadius,
                              ),
                              child: ClipRRect(
                                borderRadius: AppConst.borderRadius,
                                child: Image.asset(
                                  'assets/Rectangle 27 (2).png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'Soft drink',
                                style: TextStyle(
                                  color: AppConst.black,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '+ \$${_softDrinkPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isSoftDrinkSelected = !isSoftDrinkSelected;
                                });
                              },
                              child: Container(
                                width: 24.w,
                                height: 24.w,
                                decoration: BoxDecoration(
                                  color: isSoftDrinkSelected
                                      ? AppConst.black
                                      : AppConst.transparent,
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(
                                    color: AppConst.black,
                                    width: 1.5,
                                  ),
                                ),
                                child: isSoftDrinkSelected
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
                        // SizedBox(height: 32.h),
                        // Special instructions
                        Text(
                          'Special instructions',
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Kindly let us know if you are allergic to anything or if we need to avoid anything.',
                          style: TextStyle(
                            color: AppConst.grey,
                            fontSize: 10.sp,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        // Text Input Field
                        Container(
                          decoration: BoxDecoration(
                            color: AppConst.transparent,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: AppConst.white, width: 1),
                          ),
                          child: Stack(
                            children: [
                              TextField(
                                controller: _instructionsController,
                                maxLines: 4,
                                maxLength: 500,
                                decoration: InputDecoration(
                                  hintText: 'e.g. no mayo.',
                                  hintStyle: TextStyle(
                                    color: AppConst.black,
                                    fontSize: 14.sp,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(16.w),
                                  counterText: '',
                                ),
                                style: TextStyle(
                                  color: AppConst.black,
                                  fontSize: 14.sp,
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                              Positioned(
                                bottom: 8.h,
                                right: 12.w,
                                child: Text(
                                  '${_instructionsController.text.length}/500',
                                  style: TextStyle(
                                    color: AppConst.grey,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom Action Buttons
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppConst.transparent,
          boxShadow: [
            BoxShadow(
              color: AppConst.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add To Cart Button
              GestureDetector(
                onTap: () {
                  // Navigate to success screen
                  Get.to(() => const AddToCartSuccessView());
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
                      'Add To Cart (\$${total.toStringAsFixed(2)})',
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
                    borderRadius: BorderRadius.circular(12.r),
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
      ),
    );
  }
}

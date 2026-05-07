import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../consts/appConst.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> {
  String? _selectedCategory;

  List<String> get _categories => ['vendor.orders'.tr, 'vendor.ongoing'.tr, 'Completed'];

  final List<OrderItem> _orders = [
    OrderItem(
      itemName: 'vendor.item_name'.tr,
      quantity: 2,
      totalPrice: 25.99,
      status: 'Active',
    ),
    OrderItem(
      itemName: 'vendor.item_name'.tr,
      quantity: 2,
      totalPrice: 25.99,
      status: 'Active',
    ),
    OrderItem(
      itemName: 'vendor.item_name'.tr,
      quantity: 2,
      totalPrice: 25.99,
      status: 'Active',
    ),
  ];

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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chevron_left,
                          color: AppConst.white,
                          size: 24.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'vendor.orders'.tr,
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
          // Category Tabs
          Container(
            color: AppConst.background,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Row(
              children: _categories.map((category) {
                final isSelected = (_selectedCategory ?? _categories.first) == category;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 24.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          category,
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 16.sp,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (isSelected)
                          Container(
                            margin: EdgeInsets.only(top: 4.h),
                            height: 2.h,
                            width: category.length * 8.w,
                            color: AppConst.black,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Orders List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 16.h),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppConst.cardLight,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12.r),
                      bottomLeft: Radius.circular(12.r),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Name and Total Price Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              order.itemName,
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            'vendor.total_price'.tr,
                            style: TextStyle(
                              color: AppConst.black,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      // Quantity
                      Text(
                        'Quantity: x${order.quantity}',
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Status Badge
                      Text(
                        'Status badge: ${order.status}',
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      // View Details Button
                      GestureDetector(
                        onTap: () {
                          // TODO: Navigate to order details
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppConst.black,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'vendor.view_details'.tr,
                            style: TextStyle(
                              color: AppConst.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class OrderItem {
  final String itemName;
  final int quantity;
  final double totalPrice;
  final String status;

  OrderItem({
    required this.itemName,
    required this.quantity,
    required this.totalPrice,
    required this.status,
  });
}

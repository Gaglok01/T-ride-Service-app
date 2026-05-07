import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../consts/appConst.dart';
import '../../data/models/food_placed_order_model.dart';

/// Shown after a successful food order; displays API `data` payload.
class FoodOrderPlacedView extends StatelessWidget {
  const FoodOrderPlacedView({super.key, required this.order});

  final FoodPlacedOrderModel order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      appBar: AppBar(
        backgroundColor: AppConst.black,
        foregroundColor: AppConst.white,
        title: Text(
          'food.order_placed'.tr,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppConst.cardLight,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppConst.black, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'food.thank_you'.tr,
                      style: TextStyle(
                        color: AppConst.black,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'food.order_received'.tr,
                      style: TextStyle(color: AppConst.grey, fontSize: 13.sp),
                    ),
                    SizedBox(height: 16.h),
                    _rowLabel('food.order_code'.tr, order.orderCode, emphasize: true),
                    SizedBox(height: 10.h),
                    _rowLabel('food.status'.tr, order.status),
                    SizedBox(height: 8.h),
                    _rowLabel('common.total'.tr, '\$${order.totalAmount}'),
                    if (order.deliveryFee.isNotEmpty &&
                        order.deliveryFee != '0' &&
                        order.deliveryFee != '0.00')
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: _rowLabel('food.delivery_fee'.tr, '\$${order.deliveryFee}'),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'home.service.delivery'.tr,
                style: TextStyle(
                  color: AppConst.black,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              _infoCard(
                children: [
                  _rowLabel('Address', order.deliveryAddress),
                  SizedBox(height: 8.h),
                  _rowLabel('Phone', order.contactPhone),
                  if (order.deliveryInstructions != null &&
                      order.deliveryInstructions!.trim().isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    _rowLabel('Instructions', order.deliveryInstructions!),
                  ],
                  SizedBox(height: 8.h),
                  _rowLabel('Payment', order.paymentMethod),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                'Items',
                style: TextStyle(
                  color: AppConst.black,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              ...order.items.map(
                (line) => Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: _infoCard(
                    children: [
                      Text(
                        line.productName ?? 'food.item'.tr,
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      _rowLabel(
                        'common.qty'.tr,
                        '${line.quantity ?? 0} × \$${line.unitPrice ?? '0'}',
                      ),
                      if (line.total != null && line.total!.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        _rowLabel('food.line_total'.tr, '\$${line.total}'),
                      ],
                      if (line.specialInstructions != null &&
                          line.specialInstructions!.trim().isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Text(
                          line.specialInstructions!,
                          style: TextStyle(
                            color: AppConst.grey,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConst.black,
                    foregroundColor: AppConst.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'common.done'.tr,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
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

  Widget _infoCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppConst.cardLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppConst.grey.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _rowLabel(String label, String value, {bool emphasize = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100.w,
          child: Text(
            label,
            style: TextStyle(color: AppConst.grey, fontSize: 12.sp),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppConst.black,
              fontSize: emphasize ? 16.sp : 13.sp,
              fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

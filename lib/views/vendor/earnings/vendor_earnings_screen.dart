import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../consts/appConst.dart';

class VendorEarningsScreen extends StatelessWidget {
  const VendorEarningsScreen({super.key});

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
                  Text(
                    'vendor.earnings'.tr,
                    style: TextStyle(
                      color: AppConst.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
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
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Earnings Summary Cards
                  _buildEarningsCard(
                    title: 'vendor.total_earnings'.tr,
                    amount: '\$460.00',
                  ),
                  SizedBox(height: 16.h),
                  _buildEarningsCard(
                    title: 'vendor.pending_payments'.tr,
                    amount: '\$35.70',
                  ),
                  SizedBox(height: 16.h),
                  _buildEarningsCard(
                    title: 'Completed Payments',
                    amount: '\$460.00',
                  ),
                  SizedBox(height: 30.h),
                  // Payment Methods Section
                  Text(
                    'Payment Methods',
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPaymentMethodButton(
                          icon: Icons.account_balance_wallet,
                          label: 'Cash',
                          hasDollarSign: true,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildPaymentMethodButton(
                          icon: Icons.account_balance_wallet,
                          label: 'Wallet',
                          hasDollarSign: false,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildPaymentMethodButton(
                          icon: Icons.credit_card,
                          label: 'Card',
                          hasDollarSign: false,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  // Account Details Button
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Navigate to account details
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppConst.black,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(12.r),
                            bottomLeft: Radius.circular(12.r),
                            topLeft: Radius.circular(12.r),
                            bottomRight: Radius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Account details',
                          style: TextStyle(
                            color: AppConst.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30.h),
                  // Transaction History List Section
                  Text(
                    'Transaction History List',
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Transaction Card
                  _buildTransactionCard(
                    date: 'December 14, 2025',
                    orderId: '123 456 7890',
                    amount: '\$17.00',
                    status: 'Paid',
                  ),
                  SizedBox(height: 16.h),
                  _buildTransactionCard(
                    date: 'December 13, 2025',
                    orderId: '123 456 7891',
                    amount: '\$25.50',
                    status: 'vendor.pending'.tr,
                  ),
                  SizedBox(height: 16.h),
                  _buildTransactionCard(
                    date: 'December 12, 2025',
                    orderId: '123 456 7892',
                    amount: '\$32.00',
                    status: 'Paid',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard({required String title, required String amount}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: AppConst.cardLight,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(12.r),
          bottomLeft: Radius.circular(12.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppConst.black,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: AppConst.black,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodButton({
    required IconData icon,
    required String label,
    required bool hasDollarSign,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 13.h),
      decoration: BoxDecoration(
        color: AppConst.cardLight,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(12.r),
          bottomLeft: Radius.circular(12.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppConst.black, size: 25.sp),

          SizedBox(width: 10.h),
          Text(
            label,
            style: TextStyle(
              color: AppConst.black,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard({
    required String date,
    required String orderId,
    required String amount,
    required String status,
  }) {
    return Container(
      width: double.infinity,
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
          Text(
            'Date: $date',
            style: TextStyle(color: AppConst.black, fontSize: 14.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            'Order ID: $orderId',
            style: TextStyle(color: AppConst.black, fontSize: 14.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            'Amount: $amount',
            style: TextStyle(color: AppConst.black, fontSize: 14.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            'Status ($status)',
            style: TextStyle(
              color: AppConst.black,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

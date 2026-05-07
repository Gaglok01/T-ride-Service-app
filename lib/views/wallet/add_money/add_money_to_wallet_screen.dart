import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_ride_rider_app/data/models/wallet_model.dart';
import 'package:t_ride_rider_app/data/repositories/wallet_repository.dart';
import '../../../consts/appConst.dart';
import '../../../widgets/app_snackbar.dart';
import '../money_added_success/money_added_success_screen.dart';

class AddMoneyToWalletScreen extends StatefulWidget {
  const AddMoneyToWalletScreen({super.key});

  @override
  State<AddMoneyToWalletScreen> createState() => _AddMoneyToWalletScreenState();
}

class _AddMoneyToWalletScreenState extends State<AddMoneyToWalletScreen> {
  final TextEditingController _amountController = TextEditingController();
  String? _selectedPaymentMethod;
  final WalletRepository _walletRepository = WalletRepository();
  WalletData? _walletData;
  bool _isLoadingWallet = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    setState(() {
      _isLoadingWallet = true;
    });
    try {
      final wallet = await _walletRepository.getWallet();
      if (!mounted) return;
      setState(() {
        _walletData = wallet;
      });
    } catch (e) {
      // ignore: avoid_print
      print('AddMoneyToWalletScreen _fetchWallet error: $e');
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWallet = false;
        });
      }
    }
  }

  bool get _isFormValid {
    final amount = double.tryParse(_amountController.text);
    return amount != null && amount > 0 && _selectedPaymentMethod != null;
  }

  Future<void> _onAddMoneyPressed() async {
    if (!_isFormValid || _isSubmitting) return;

    final amount = double.parse(_amountController.text);
    final method = _selectedPaymentMethod!;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _walletRepository.addMoney(
        amount: amount,
        paymentMethod: method,
      );

      // ignore: avoid_print
      print('AddMoneyToWalletScreen addMoney response: $response');

      final wallet = WalletData.fromJson(response);
      if (!mounted) return;
      setState(() {
        _walletData = wallet;
      });

      final message = (response['message'] ?? 'Money added successfully')
          .toString();

      AppSnackBar.show('common.success'.tr, message);

      final result =
          await Get.to<bool>(() => const MoneyAddedSuccessScreen());
      if (result == true) {
        Get.back(result: true);
      }
    } catch (e) {
      // ignore: avoid_print
      print('AddMoneyToWalletScreen addMoney error: $e');
      if (mounted) {
        AppSnackBar.show('common.error'.tr, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = _walletData?.balance;
    final balanceText = _isLoadingWallet
        ? 'common.loading'.tr
        : balance != null
        ? '\$${balance.toString()}'
        : '\$0.00';

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
                    'Add Money To Wallet',
                    style: TextStyle(
                      color: AppConst.white,
                      fontSize: 18.sp,
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
                  // Available Balance Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(10),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available Balance',
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 12.sp,
                              ),
                            ),
                            Text(
                              balanceText,
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40.h),
                  // Select Payment Method Section
                  Text(
                    'wallet.select_payment'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Payment Method Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildPaymentMethodButton(
                          label: 'payment.card'.tr,
                          isSelected: _selectedPaymentMethod == 'Card',
                          onTap: () {
                            setState(() {
                              _selectedPaymentMethod = 'Card';
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildPaymentMethodButton(
                          label: 'wallet.mobile_money'.tr,
                          isSelected: _selectedPaymentMethod == 'Mobile Money',
                          onTap: () {
                            setState(() {
                              _selectedPaymentMethod = 'Mobile Money';
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildPaymentMethodButton(
                          label: 'wallet.bank_transfer'.tr,
                          isSelected: _selectedPaymentMethod == 'Bank Transfer',
                          onTap: () {
                            setState(() {
                              _selectedPaymentMethod = 'Bank Transfer';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30.h),
                  // Enter Amount Field
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 18.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12.r),
                        bottomLeft: Radius.circular(12.r),
                      ),
                      border: Border.all(
                        color: AppConst.black.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'wallet.hint_amount'.tr,
                        hintStyle: TextStyle(
                          color: AppConst.grey,
                          fontSize: 16.sp,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(color: AppConst.black, fontSize: 16.sp),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
          // Add Money Button
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
              onTap: _isFormValid && !_isSubmitting ? _onAddMoneyPressed : null,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: _isFormValid && !_isSubmitting
                      ? AppConst.black
                      : AppConst.blackWithOpacity(0.5),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12.r),
                    bottomLeft: Radius.circular(12.r),
                  ),
                ),
                child: Center(
                  child: _isSubmitting
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppConst.white,
                          ),
                        )
                      : Text(
                          'Add Money',
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

  Widget _buildPaymentMethodButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: AppConst.cardLight,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(12.r),
            bottomLeft: Radius.circular(12.r),
          ),
          border: isSelected
              ? Border.all(color: AppConst.black, width: 1)
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: AppConst.black,
              fontSize: 12.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

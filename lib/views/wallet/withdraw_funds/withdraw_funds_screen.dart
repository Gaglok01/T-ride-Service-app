import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_ride_rider_app/data/models/wallet_model.dart';
import 'package:t_ride_rider_app/data/repositories/wallet_repository.dart';
import '../../../consts/appConst.dart';
import '../../../widgets/app_snackbar.dart';

class WithdrawFundsScreen extends StatefulWidget {
  const WithdrawFundsScreen({super.key});

  @override
  State<WithdrawFundsScreen> createState() => _WithdrawFundsScreenState();
}

class _WithdrawFundsScreenState extends State<WithdrawFundsScreen> {
  final TextEditingController _withdrawalAmountController =
      TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _ibanController = TextEditingController();
  String? _selectedPaymentMethod;
  final WalletRepository _walletRepository = WalletRepository();
  WalletData? _walletData;
  bool _isLoadingWallet = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _withdrawalAmountController.dispose();
    _accountNumberController.dispose();
    _ibanController.dispose();
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
      print('WithdrawFundsScreen _fetchWallet error: $e');
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
    final amount = double.tryParse(_withdrawalAmountController.text);
    return amount != null &&
        amount > 0 &&
        _selectedPaymentMethod != null &&
        _accountNumberController.text.trim().isNotEmpty &&
        _ibanController.text.trim().isNotEmpty;
  }

  Future<void> _onRequestWithdrawalPressed() async {
    if (!_isFormValid || _isSubmitting) return;

    final amount = double.parse(_withdrawalAmountController.text);
    final method = _selectedPaymentMethod!;
    final accountNumber = _accountNumberController.text.trim();
    final iban = _ibanController.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _walletRepository.withdraw(
        amount: amount,
        paymentMethod: method,
        accountNumber: accountNumber,
        iban: iban,
      );

      // ignore: avoid_print
      print('WithdrawFundsScreen withdraw response: $response');

      final message = (response['message'] ?? 'Withdrawal request submitted')
          .toString();

      // Return the success message so previous screen can
      // refresh data and show snackbar there.
      Get.back(result: message);
    } catch (e) {
      // ignore: avoid_print
      print('WithdrawFundsScreen withdraw error: $e');
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
                    'Withdraw Funds',
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
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12.r),
                        bottomLeft: Radius.circular(12.r),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Balance',
                                style: TextStyle(
                                  color: AppConst.black,
                                  fontSize: 14.sp,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                balanceText,
                                style: TextStyle(
                                  color: AppConst.black,
                                  fontSize: 32.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // GestureDetector(
                        //   onTap: () {
                        //     // TODO: Handle add money
                        //   },
                        //   child: Container(
                        //     width: 50.w,
                        //     height: 50.w,
                        //     decoration: BoxDecoration(
                        //       color: AppConst.black,
                        //       shape: BoxShape.circle,
                        //     ),
                        //     child: Icon(
                        //       Icons.add,
                        //       color: AppConst.white,
                        //       size: 28.sp,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30.h),
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
                  // Input Fields
                  _buildInputField(
                    controller: _withdrawalAmountController,
                    hintText: 'Enter Withdrawal Amount',
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 16.h),
                  _buildInputField(
                    controller: _accountNumberController,
                    hintText: 'Enter Account number',
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 16.h),
                  _buildInputField(
                    controller: _ibanController,
                    hintText: 'Enter IBAN number',
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 20.h),
                  // Processing Time
                  Text(
                    'Processing Time: 1-3 working days',
                    style: TextStyle(color: AppConst.black, fontSize: 14.sp),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
          // Request Withdrawal Button
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
              onTap: _isFormValid && !_isSubmitting
                  ? _onRequestWithdrawalPressed
                  : null,
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
                          'Request Withdrawal',
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
          border: Border.all(color: AppConst.black, width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: AppConst.black,
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: AppConst.cardLight,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(12.r),
          bottomLeft: Radius.circular(12.r),
        ),
        border: Border.all(color: AppConst.black.withOpacity(0.2), width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: AppConst.grey, fontSize: 16.sp),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: TextStyle(color: AppConst.black, fontSize: 16.sp),
        onChanged: onChanged,
      ),
    );
  }
}

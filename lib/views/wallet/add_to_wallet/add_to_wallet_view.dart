import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_ride_rider_app/data/models/wallet_model.dart';
import 'package:t_ride_rider_app/data/repositories/wallet_repository.dart';
import '../../../consts/appConst.dart';
import '../../../widgets/app_snackbar.dart';
import '../add_money/add_money_to_wallet_screen.dart';
import '../withdraw_funds/withdraw_funds_screen.dart';

class AddToWalletView extends StatefulWidget {
  const AddToWalletView({super.key});

  @override
  State<AddToWalletView> createState() => _AddToWalletViewState();
}

class _AddToWalletViewState extends State<AddToWalletView> {
  final WalletRepository _walletRepository = WalletRepository();
  WalletData? _walletData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final wallet = await _walletRepository.getWallet();
      if (!mounted) return;
      setState(() {
        _walletData = wallet;
      });
    } catch (e) {
      // ignore: avoid_print
      print('AddToWalletView _fetchWallet error: $e');
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = _walletData?.balance;
    final availableBalanceText = _isLoading
        ? 'Loading...'
        : balance != null
        ? '\$${balance.toString()}'
        : '\$0.00';

    final transactions =
        _walletData?.transactions ?? const <WalletTransaction>[];

    return Scaffold(
      backgroundColor: AppConst.background,
      body: RefreshIndicator(
        onRefresh: _fetchWallet,
        child: Column(
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
                      'Wallet Balance Dashboard',
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
                physics: const AlwaysScrollableScrollPhysics(),
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
                                availableBalanceText,
                                style: TextStyle(
                                  color: AppConst.black,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () async {
                              final result = await Get.to(
                                () => const AddMoneyToWalletScreen(),
                              );
                              if (result == true) {
                                await _fetchWallet();
                              }
                            },
                            child: Container(
                              width: 30.w,
                              height: 30.w,
                              decoration: BoxDecoration(
                                color: AppConst.black,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Icon(
                                Icons.add,
                                color: AppConst.white,
                                size: 20.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    // Action Buttons
                    GestureDetector(
                      onTap: () async {
                        final result = await Get.to(
                          () => const AddMoneyToWalletScreen(),
                        );
                        if (result == true) {
                          await _fetchWallet();
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        decoration: BoxDecoration(
                          color: AppConst.black,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: Text(
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
                    SizedBox(height: 12.w),
                    GestureDetector(
                      onTap: () async {
                        final result =
                            await Get.to<String?>(() => const WithdrawFundsScreen());
                        if (result != null && result.isNotEmpty) {
                          await _fetchWallet();
                          AppSnackBar.show('Success', result);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        decoration: BoxDecoration(
                          color: AppConst.grey,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: Text(
                            'Withdraw Money',
                            style: TextStyle(
                              color: AppConst.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30.h),
                    // Transaction History Section
                    Text(
                      'Transaction History',
                      style: TextStyle(
                        color: AppConst.black,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    if (_isLoading) ...[
                      Center(
                        child: CircularProgressIndicator(color: AppConst.black),
                      ),
                    ] else if (transactions.isEmpty) ...[
                      Text(
                        'No transactions yet.',
                        style: TextStyle(color: AppConst.grey, fontSize: 14.sp),
                      ),
                    ] else ...[
                      for (final tx in transactions) ...[
                        _buildTransactionCard(
                          type: (tx.type ?? '').isNotEmpty
                              ? tx.type!
                              : (tx.transactionType ?? ''),
                          description: tx.description ?? '',
                          dateTime: _formatDateTime(tx.createdAt),
                          amount: _formatAmount(tx),
                          status: tx.status ?? '',
                        ),
                        SizedBox(height: 12.h),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard({
    required String type,
    required String description,
    required String dateTime,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Credit Card Icon
          Icon(Icons.credit_card, color: AppConst.black, size: 24.sp),
          SizedBox(width: 12.w),
          // Transaction Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: TextStyle(
                    color: AppConst.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(color: AppConst.black, fontSize: 14.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  dateTime,
                  style: TextStyle(color: AppConst.grey, fontSize: 12.sp),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(Icons.check_circle, color: Colors.green, size: 16.sp),
                  ],
                ),
              ],
            ),
          ),
          // Amount
          Text(
            amount,
            style: TextStyle(
              color: amount.startsWith('+') ? Colors.green : AppConst.black,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(WalletTransaction tx) {
    final amt = tx.amount ?? 0;
    final isDebit =
        (tx.type ?? '').toLowerCase() == 'debit' ||
        (tx.transactionType ?? '').toLowerCase() == 'debit';
    final sign = isDebit ? '- ' : '+ ';
    return '$sign\$${amt.toStringAsFixed(2)}';
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;

      var hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;

      return '$day $month $year, $hour:$minute $ampm';
    } catch (_) {
      return raw;
    }
  }
}

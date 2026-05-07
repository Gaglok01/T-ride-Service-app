import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_ride_rider_app/data/repositories/auth_repository.dart';
import 'package:t_ride_rider_app/widgets/app_snackbar.dart';
import 'package:t_ride_rider_app/widgets/custom_appbar.dart';
import 'package:t_ride_rider_app/widgets/custom_textfield.dart';
import '../../../consts/appConst.dart';
import 'email_otp_screen.dart';

class EmailRegistrationScreen extends StatefulWidget {
  const EmailRegistrationScreen({super.key});

  @override
  State<EmailRegistrationScreen> createState() =>
      _EmailRegistrationScreenState();
}

class _EmailRegistrationScreenState extends State<EmailRegistrationScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isEmailValid = false;
  bool _isSendingOtp = false;
  final AuthRepository _authRepository = AuthRepository();

  @override
  void initState() {
    super.initState();
    emailController.addListener(_validateEmail);
  }

  void _validateEmail() {
    setState(() {
      final email = emailController.text;
      isEmailValid =
          email.isNotEmpty && email.contains('@') && email.contains('.');
    });
  }

  @override
  void dispose() {
    emailController.removeListener(_validateEmail);
    emailController.dispose();
    super.dispose();
  }

  Future<void> _onContinuePressed() async {
    if (!isEmailValid || _isSendingOtp) return;

    final email = emailController.text.trim();

    setState(() {
      _isSendingOtp = true;
    });

    try {
      final success = await _authRepository.sendOtp(
        method: 'email',
        email: email,
      );

      if (!mounted) return;

      if (success) {
        Get.to(
          () => const EmailOtpScreen(),
          arguments: {'email': email},
        );
      } else {
        AppSnackBar.show(
          'common.error'.tr,
          'reg.otp_send_failed'.tr,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('EmailRegistrationScreen send OTP error: $e');
      if (mounted) {
        AppSnackBar.show('common.error'.tr, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          // Top Section - Black Header with rounded bottom corners
          CustomAppBar(title: 'appbar.continue_email'.tr),
          // Bottom Section - Yellow Background with Form
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40.h),
                  // Email Address Label
                  Text(
                    'email_reg.label'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Email Input Field
                  // Container(
                  //   decoration: BoxDecoration(
                  //     borderRadius: BorderRadius.circular(12.r),
                  //   ),
                  //   child: TextField(
                  //     controller: emailController,
                  //     keyboardType: TextInputType.emailAddress,
                  //     style: TextStyle(color: AppConst.black, fontSize: 16.sp),

                  //     decoration: InputDecoration(
                  //       fillColor: AppConst.cardLight,
                  //       filled: true,
                  //       hintText: 'Enter Email address',
                  //       hintStyle: TextStyle(
                  //         color: AppConst.grey,
                  //         fontSize: 16.sp,
                  //       ),
                  //       border: OutlineInputBorder(
                  //         borderRadius: BorderRadius.only(
                  //           topRight: Radius.circular(12.r),
                  //           bottomLeft: Radius.circular(12.r),
                  //         ),
                  //         borderSide: BorderSide.none,
                  //       ),
                  //       contentPadding: EdgeInsets.symmetric(
                  //         horizontal: 16.w,
                  //         vertical: 18.h,
                  //       ),
                  //       enabledBorder: OutlineInputBorder(
                  //         borderRadius: BorderRadius.only(
                  //           topRight: Radius.circular(12.r),
                  //           bottomLeft: Radius.circular(12.r),
                  //         ),
                  //         borderSide: BorderSide.none,
                  //       ),
                  //       focusedBorder: OutlineInputBorder(
                  //         borderRadius: BorderRadius.only(
                  //           topRight: Radius.circular(12.r),
                  //           bottomLeft: Radius.circular(12.r),
                  //         ),
                  //         borderSide: BorderSide.none,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  CustomTextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    hintText: 'email_reg.hint'.tr,
                    onChanged: (value) {
                      _validateEmail();
                    },
                    onSubmitted: (value) {
                      _validateEmail();
                    },
                    enabled: true,
                    focusNode: FocusNode(),
                  ),
                  const Spacer(),
                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: isEmailValid && !_isSendingOtp
                          ? _onContinuePressed
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEmailValid && !_isSendingOtp
                            ? AppConst.accent
                            : AppConst.accentWithOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppConst.buttonRadius,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isSendingOtp ? 'reg.sending_otp'.tr : 'common.continue'.tr,
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

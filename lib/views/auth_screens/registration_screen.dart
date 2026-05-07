import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_ride_rider_app/data/repositories/auth_repository.dart';
import 'package:t_ride_rider_app/widgets/app_back_button.dart';
import 'package:t_ride_rider_app/widgets/app_snackbar.dart';
import '../../consts/appConst.dart';
import 'Regsitration_screens/email_registration_screen.dart';
import 'Regsitration_screens/phone_otp_screen.dart';
import 'Regsitration_screens/whatsapp_registration_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController countryCodeController = TextEditingController();
  bool isPhoneNumberValid = false;
  bool _isSendingOtp = false;
  final AuthRepository _authRepository = AuthRepository();

  @override
  void initState() {
    super.initState();
    countryCodeController.text = '+1';
    phoneController.addListener(_validatePhoneNumber);
  }

  void _validatePhoneNumber() {
    setState(() {
      isPhoneNumberValid =
          phoneController.text.isNotEmpty && phoneController.text.length >= 10;
    });
  }

  @override
  void dispose() {
    phoneController.removeListener(_validatePhoneNumber);
    phoneController.dispose();
    countryCodeController.dispose();
    super.dispose();
  }

  Future<void> _onContinuePressed() async {
    if (!isPhoneNumberValid || _isSendingOtp) return;

    final fullNumber = '${countryCodeController.text}${phoneController.text}';

    setState(() {
      _isSendingOtp = true;
    });

    try {
      final success = await _authRepository.sendOtp(
        method: 'phone',
        phoneNumber: fullNumber,
      );

      if (!mounted) return;

      if (success) {
        Get.to(
          () => PhoneOtpScreen(
            phoneNumber: phoneController.text,
            countryCode: countryCodeController.text,
          ),
        );
      } else {
        AppSnackBar.show('common.error'.tr, 'reg.otp_send_failed'.tr);
      }
    } catch (e) {
      // ignore: avoid_print
      print('RegistrationScreen send OTP error: $e');
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
          // Top Section - Black Background with Logo
          ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30.r),
              bottomRight: Radius.circular(30.r),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppConst.black,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30.r),
                  bottomRight: Radius.circular(30.r),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    // vert.h,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Logo
                        // Align(
                        //   alignment: AlignmentDirectional.topStart,
                        //   child: AppBackIconButton(color: AppConst.white),
                        // ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/T (1) 2 (1).png',
                              width: 200.w,
                              height: 200.h,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                        // Welcome Text
                        Text(
                          'reg.welcome_title'.tr,
                          style: TextStyle(
                            color: AppConst.primaryColor,
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        // Instruction Text
                        Text(
                          'reg.phone_instruction'.tr,
                          style: TextStyle(
                            color: AppConst.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Bottom Section - Yellow Background with Input Fields
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phone Number Input Fields
                    Row(
                      children: [
                        // Country Code Field
                        Container(
                          width: 100.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: TextField(
                            controller: countryCodeController,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppConst.black,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              fillColor: AppConst.cardLight,
                              filled: true,
                              prefixIcon: Icon(
                                Icons.phone,
                                color: AppConst.black,
                                size: 20.sp,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(12.r),
                                  bottomLeft: Radius.circular(12.r),
                                ),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 16.h,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        // Phone Number Field
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppConst.cardLight,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: TextField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 16.sp,
                              ),
                              decoration: InputDecoration(
                                fillColor: AppConst.cardLight,
                                filled: true,
                                hintText: 'reg.hint_phone'.tr,
                                hintStyle: TextStyle(
                                  color: AppConst.grey,
                                  fontSize: 16.sp,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(12.r),
                                    bottomLeft: Radius.circular(12.r),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 16.h,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30.h),
                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: isPhoneNumberValid && !_isSendingOtp
                            ? _onContinuePressed
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPhoneNumberValid && !_isSendingOtp
                              ? AppConst.accent
                              : AppConst.accentWithOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppConst.buttonRadius,
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _isSendingOtp
                              ? 'reg.sending_otp'.tr
                              : 'common.continue'.tr,
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30.h),
                    // Divider with "or continue with"
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: AppConst.black, thickness: 1),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            'reg.or_continue_with'.tr,
                            style: TextStyle(
                              color: AppConst.black,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: AppConst.black, thickness: 1),
                        ),
                      ],
                    ),
                    SizedBox(height: 30.h),
                    // Continue with Email Button
                    Container(
                      width: double.infinity,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: AppConst.cardLight,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Get.to(() => const EmailRegistrationScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConst.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google G Logo (simplified)
                            Container(
                              width: 24.w,
                              height: 24.w,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    color: AppConst.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              'reg.continue_email'.tr,
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // Continue with WhatsApp Button
                    Container(
                      width: double.infinity,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: AppConst.cardLight,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Get.to(() => const WhatsappRegistrationScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConst.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google G Logo (simplified)
                            Container(
                              width: 24.w,
                              height: 24.w,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    color: AppConst.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              'reg.continue_whatsapp'.tr,
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

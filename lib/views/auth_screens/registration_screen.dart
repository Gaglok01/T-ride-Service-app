import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_ride_rider_app/data/repositories/auth_repository.dart';
import 'package:t_ride_rider_app/widgets/app_snackbar.dart';
import '../../consts/appConst.dart';
import 'Regsitration_screens/email_registration_screen.dart';
import 'Regsitration_screens/phone_otp_screen.dart';
import 'Regsitration_screens/role_screen.dart';

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
          phoneController.text.trim().isNotEmpty &&
          phoneController.text.trim().length >= 10;
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

    final fullNumber =
        '${countryCodeController.text.trim()}${phoneController.text.trim()}';

    setState(() => _isSendingOtp = true);

    try {
      final success = await _authRepository.sendOtp(
        method: 'phone',
        phoneNumber: fullNumber,
      );

      if (!mounted) return;

      if (success) {
        Get.to(
          () => PhoneOtpScreen(
            phoneNumber: phoneController.text.trim(),
            countryCode: countryCodeController.text.trim(),
          ),
        );
      } else {
        AppSnackBar.show('Error', 'Unable to send OTP. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show('Error', 'Unable to send OTP. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Widget _secondaryButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: AppConst.black, size: 22.sp),
        label: Text(
          text,
          style: TextStyle(
            color: AppConst.black,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppConst.white,
          side: BorderSide(color: AppConst.blackWithOpacity(0.12)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 34.h),

              Center(
                child: Image.asset(
                  'assets/T (1) 2 (1).png',
                  width: 110.w,
                  height: 90.h,
                  fit: BoxFit.contain,
                ),
              ),

              SizedBox(height: 20.h),

              Text(
                'Move smarter with T-Ride',
                style: TextStyle(
                  color: AppConst.black,
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),

              SizedBox(height: 10.h),

              Text(
                'Enter your phone number to sign in or create an account.',
                style: TextStyle(
                  color: AppConst.grey,
                  fontSize: 15.sp,
                  height: 1.4,
                ),
              ),

              SizedBox(height: 32.h),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppConst.white,
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppConst.blackWithOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72.w,
                      child: TextField(
                        controller: countryCodeController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28.h,
                      color: AppConst.blackWithOpacity(0.12),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Phone number',
                          hintStyle: TextStyle(
                            color: AppConst.grey,
                            fontSize: 16.sp,
                          ),
                        ),
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: isPhoneNumberValid && !_isSendingOtp
                      ? _onContinuePressed
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPhoneNumberValid && !_isSendingOtp
                        ? AppConst.black
                        : AppConst.blackWithOpacity(0.35),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    _isSendingOtp ? 'Sending code...' : 'Continue',
                    style: TextStyle(
                      color: AppConst.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 26.h),

              Row(
                children: [
                  Expanded(child: Divider(color: AppConst.blackWithOpacity(0.14))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    child: Text(
                      'or',
                      style: TextStyle(color: AppConst.grey, fontSize: 14.sp),
                    ),
                  ),
                  Expanded(child: Divider(color: AppConst.blackWithOpacity(0.14))),
                ],
              ),

              SizedBox(height: 22.h),

              _secondaryButton(
                icon: Icons.email_outlined,
                text: 'Continue with email',
                onTap: () => Get.to(() => const EmailRegistrationScreen()),
              ),

              SizedBox(height: 12.h),

              _secondaryButton(
                icon: Icons.storefront_outlined,
                text: 'Continue as vendor',
                onTap: () => Get.to(() => const RoleScreen()),
              ),

              const Spacer(),

              Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 18.h),
                  child: Text(
                    'By continuing, you agree to T-Ride Terms and Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppConst.grey,
                      fontSize: 12.sp,
                      height: 1.4,
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

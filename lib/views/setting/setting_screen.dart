import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_ride_rider_app/controllers/theme_controller.dart';
import 'package:t_ride_rider_app/data/repositories/auth_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../consts/appConst.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_appbar.dart';
import '../auth_screens/login_screen.dart';
import 'profile_screen.dart';
import 'feedback_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _pushNotificationsEnabled = true;
  bool _isLoggingOut = false;
  static const String _sosEmergencyNumber = '911';
  static const String _sosTRideNumber = '87344';
  final AuthRepository _authRepository = AuthRepository();

  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      AppSnackBar.show('common.error'.tr, 'settings.sos_call_failed'.tr);
    }
  }

  Future<void> _onSosPressed() async {
    await Get.dialog<void>(
      AlertDialog(
        backgroundColor: AppConst.cardLight,
        title: Text(
          'settings.sos_title'.tr,
          style: TextStyle(
            color: AppConst.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'settings.sos_confirm_body'.tr,
          style: TextStyle(
            color: AppConst.black,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'common.cancel'.tr,
              style: TextStyle(
                color: AppConst.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (Get.isDialogOpen == true) Get.back();
              await _callNumber(_sosEmergencyNumber);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('settings.sos_call_911'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              if (Get.isDialogOpen == true) Get.back();
              await _callNumber(_sosTRideNumber);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConst.black,
              foregroundColor: AppConst.white,
            ),
            child: Text('settings.sos_call_tride'.tr),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    Get.dialog(
      Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: AppConst.cardLight,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.headset_mic, color: AppConst.black, size: 22.sp),
                    SizedBox(width: 10.w),
                    Text(
                      'settings.support_dialog_title'.tr,
                      style: TextStyle(
                        color: AppConst.black,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  'settings.support_dialog_body'.tr,
                  style: TextStyle(
                    color: AppConst.black,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (Get.isDialogOpen == true) Get.back();
                          Get.to(() => const FeedbackScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConst.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: Text(
                          'settings.open_feedback'.tr,
                          style: TextStyle(
                            color: AppConst.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    IconButton(
                      onPressed: () {
                        if (Get.isDialogOpen == true) Get.back();
                      },
                      icon: const Icon(Icons.close),
                      color: AppConst.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Future<void> _onLogoutPressed() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authRepository.logout();

      if (!mounted) return;
      Get.offAll(() => const LoginScreen());
    } catch (e) {
      // ignore: avoid_print
      print('SettingScreen logout error: $e');
      if (mounted) {
        AppSnackBar.show('common.error'.tr, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
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
          CustomAppBar(title: 'appbar.settings'.tr),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile Opti
                  SizedBox(height: 100),
                  _buildSettingOption(
                    icon: Icons.person_outline,
                    title: 'settings.profile'.tr,
                    onTap: () {
                      Get.to(() => const ProfileScreen());
                    },
                  ),
                  SizedBox(height: 12.h),
                  // Support Option
                  _buildSettingOption(
                    icon: Icons.headset_outlined,
                    title: 'settings.support'.tr,
                    onTap: () {
                      _showSupportDialog();
                    },
                  ),
                  SizedBox(height: 12.h),
                  // Provide feedback Option
                  _buildSettingOption(
                    icon: Icons.feedback_outlined,
                    title: 'settings.feedback'.tr,
                    onTap: () {
                      Get.to(() => const FeedbackScreen());
                    },
                  ),
                  SizedBox(height: 12.h),
                  // SOS Option
                  _buildSettingOption(
                    icon: Icons.sos_rounded,
                    title: 'settings.sos'.tr,
                    onTap: _onSosPressed,
                    iconColor: Colors.red,
                    textColor: Colors.red,
                    trailingColor: Colors.red,
                  ),
                  SizedBox(height: 12.h),
                  // Sign out Option
                  _buildSettingOption(
                    icon: Icons.logout,
                    title: _isLoggingOut
                        ? 'settings.logging_out'.tr
                        : 'settings.logout'.tr,
                    onTap: () {
                      _onLogoutPressed();
                    },
                  ),
                  SizedBox(height: 12.h),
                  // Push notifications Option with Toggle
                  _buildSettingOptionWithToggle(
                    icon: Icons.notifications_outlined,
                    title: 'settings.notifications'.tr,
                    value: _pushNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _pushNotificationsEnabled = value;
                      });
                    },
                  ),
                  SizedBox(height: 12.h),
                  // Theme toggle: OFF = Yellow theme, ON = White theme.
                  Obx(() {
                    final controller = Get.find<ThemeController>();
                    final isWhiteTheme = controller.isDarkMode.value;
                    return _buildSettingOptionWithToggle(
                      icon: isWhiteTheme
                          ? Icons.palette_outlined
                          : Icons.wb_sunny_outlined,
                      title: 'settings.dark_mode'.tr,
                      value: isWhiteTheme,
                      onChanged: (_) => controller.toggle(),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    Color? trailingColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppConst.cardLight,
          borderRadius: AppConst.borderRadius,
          boxShadow: [
            BoxShadow(
              color: AppConst.blackWithOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppConst.black, size: 24.sp),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor ?? AppConst.black,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: trailingColor ?? AppConst.black,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingOptionWithToggle({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppConst.cardLight,
        borderRadius: AppConst.borderRadius,
        boxShadow: [
          BoxShadow(
            color: AppConst.blackWithOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppConst.black, size: 24.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppConst.black,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppConst.white,
            activeTrackColor: AppConst.accent,
            inactiveThumbColor: AppConst.grey,
            inactiveTrackColor: AppConst.grey.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

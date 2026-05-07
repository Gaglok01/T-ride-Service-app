import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_ride_rider_app/data/local/secure_storage_service.dart';
import 'package:t_ride_rider_app/data/repositories/auth_repository.dart';
import 'package:t_ride_rider_app/localization/app_translations.dart';
import 'package:t_ride_rider_app/views/custom_navbar/navbar.dart';
import 'package:t_ride_rider_app/views/auth_screens/language_selection_screen.dart';
import 'package:t_ride_rider_app/widgets/app_snackbar.dart';
import '../../consts/appConst.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordObscured = true;
  bool _isLoading = false;
  final AuthRepository _authRepository = AuthRepository();
  final SecureStorageService _storageService = SecureStorageService();
  final List<Map<String, String>> _languages = const [
    {'code': 'en', 'labelKey': 'lang.english'},
    {'code': 'ar', 'labelKey': 'lang.arabic'},
    {'code': 'es', 'labelKey': 'lang.spanish'},
    {'code': 'fr', 'labelKey': 'lang.french'},
    {'code': 'zh', 'labelKey': 'lang.mandarin'},
  ];
  String _currentLanguageCode = Get.locale?.languageCode ?? 'en';

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _identifierController.text.isNotEmpty &&
        _passwordController.text.length >= 6;
  }

  /// `driver_id` set (non-null, non-empty) means this account is a driver — rider app only.
  bool _userHasDriverId(dynamic user) {
    if (user is! Map) return false;
    final m = Map<String, dynamic>.from(user);
    final v = m['driver_id'];
    if (v == null) return false;
    if (v is String) {
      final t = v.trim();
      if (t.isEmpty || t.toLowerCase() == 'null') return false;
      final n = int.tryParse(t);
      if (n != null) return n != 0;
      return true;
    }
    if (v is num) return v != 0;
    return true;
  }

  Future<void> _onLoginPressed() async {
    if (!_isFormValid() || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authRepository.login(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
      );

      // Log full response for debugging
      // ignore: avoid_print
      print('Login API response: $response');

      final status = response['status'];

      if (status == true || status == 1) {
        if (_userHasDriverId(response['user'])) {
          if (mounted) {
            AppSnackBar.show(
              'login.card_title'.tr,
              'login.error.driver_forbidden'.tr,
            );
          }
          return;
        }

        final token = response['token'] as String?;
        if (token != null && token.isNotEmpty) {
          await _storageService.saveAuthToken(token);
        }

        if (!mounted) return;
        Get.offAll(() => const Navbar());
      } else {
        final message = (response['message'] ?? 'login.error.failed_generic'.tr)
            .toString();
        if (mounted) {
          AppSnackBar.show('login.error.failed_title'.tr, message);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('LoginScreen login error: $e');
      if (mounted) {
        AppSnackBar.show('login.error.title'.tr, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSignUpPressed() {
    Get.to(() => const LanguageSelectionScreen());
  }

  Future<void> _onLanguageChanged(String? code) async {
    if (code == null || code == _currentLanguageCode) return;
    final locale = AppTranslations.localeForLanguageCode(code);
    setState(() {
      _currentLanguageCode = code;
    });
    await _storageService.saveAppLocaleLanguageCode(code);
    Get.updateLocale(locale);
  }

  /// Sits on the yellow gradient below the login card — white surface, black text.
  Widget _buildLanguageDropdown() {
    final itemStyle = TextStyle(
      color: AppConst.black,
      fontSize: 13.sp,
      fontWeight: FontWeight.w600,
    );

    return Center(
      child: DropdownButtonHideUnderline(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppConst.cardLight,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: AppConst.blackWithOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: AppConst.blackWithOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: DropdownButton<String>(
            value: _currentLanguageCode,
            borderRadius: BorderRadius.circular(14.r),
            elevation: 0,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppConst.black,
              size: 20.sp,
            ),
            iconEnabledColor: AppConst.black,
            iconDisabledColor: AppConst.grey,
            style: itemStyle,
            dropdownColor: AppConst.cardLight,
            menuMaxHeight: 240,
            items: _languages.map((lang) {
              final code = lang['code']!;
              final labelKey = lang['labelKey']!;
              return DropdownMenuItem<String>(
                value: code,
                child: Text(labelKey.tr, style: itemStyle),
              );
            }).toList(),
            onChanged: _onLanguageChanged,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppConst.isDarkMode
                ? [AppConst.background, AppConst.cardLight]
                : [
                    AppConst.primaryColorWithOpacity(0.95),
                    AppConst.primaryColorWithOpacity(0.75),
                  ],
          ),
        ),
        child: Column(
          children: [
            // Top black header with title
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              decoration: BoxDecoration(
                color: AppConst.black,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30.r),
                  bottomRight: Radius.circular(30.r),
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'login.title_welcome'.tr,
                                style: TextStyle(
                                  color: AppConst.white,
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'login.subtitle_welcome'.tr,
                                style: TextStyle(
                                  color: AppConst.white.withValues(alpha: 0.8),
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 24.h,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Centered login card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 24.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppConst.cardLight,
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppConst.blackWithOpacity(0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'login.card_title'.tr,
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'login.card_subtitle'.tr,
                              style: TextStyle(
                                color: AppConst.grey,
                                fontSize: 13.sp,
                              ),
                            ),
                            SizedBox(height: 24.h),
                            Text(
                              'login.field_identifier'.tr,
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              decoration: BoxDecoration(
                                color: AppConst.cardLight,
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: AppConst.blackWithOpacity(0.12),
                                ),
                              ),
                              child: TextField(
                                controller: _identifierController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color: AppConst.grey,
                                    size: 22.sp,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 14.h,
                                  ),
                                  hintText: 'login.hint_identifier'.tr,
                                  hintStyle: TextStyle(
                                    color: AppConst.grey,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Text(
                              'login.field_password'.tr,
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              decoration: BoxDecoration(
                                color: AppConst.cardLight,
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: AppConst.blackWithOpacity(0.12),
                                ),
                              ),
                              child: TextField(
                                controller: _passwordController,
                                obscureText: _isPasswordObscured,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: AppConst.grey,
                                    size: 22.sp,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 14.h,
                                  ),
                                  hintText: 'login.hint_password'.tr,
                                  hintStyle: TextStyle(
                                    color: AppConst.grey,
                                    fontSize: 14.sp,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordObscured
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: AppConst.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordObscured =
                                            !_isPasswordObscured;
                                      });
                                    },
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            SizedBox(height: 10.h),
                            // Align(
                            //   alignment: Alignment.centerRight,
                            //   child: TextButton(
                            //     onPressed: () {
                            //       // TODO: Forgot password flow
                            //     },
                            //     style: TextButton.styleFrom(
                            //       padding: EdgeInsets.zero,
                            //       minimumSize: Size(0, 0),
                            //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            //     ),
                            //     child: Text(
                            //       'Forgot password?',
                            //       style: TextStyle(
                            //         color: AppConst.black,
                            //         fontSize: 13.sp,
                            //         fontWeight: FontWeight.w500,
                            //       ),
                            //     ),
                            //   ),
                            // ),
                            SizedBox(height: 12.h),
                            SizedBox(
                              width: double.infinity,
                              height: 52.h,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConst.accent,
                                  disabledBackgroundColor:
                                      AppConst.accentWithOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppConst.buttonRadius,
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _isFormValid() && !_isLoading
                                    ? _onLoginPressed
                                    : null,
                                child: _isLoading
                                    ? SizedBox(
                                        width: 20.w,
                                        height: 20.w,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : Text(
                                        'login.button'.tr,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),

                      _buildLanguageDropdown(),

                      SizedBox(height: 100.h),
                      Center(
                        child: TextButton(
                          onPressed: _onSignUpPressed,
                          child: RichText(
                            text: TextSpan(
                              text: 'login.footer.no_account'.tr,
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 14.sp,
                              ),
                              children: [
                                TextSpan(
                                  text: 'login.footer.signup'.tr,
                                  style: TextStyle(
                                    color: AppConst.black,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
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
      ),
    );
  }
}

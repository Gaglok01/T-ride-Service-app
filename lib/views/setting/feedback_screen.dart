import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../consts/appConst.dart';
import '../../data/repositories/feedback_repository.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  final FeedbackRepository _feedbackRepository = FeedbackRepository();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _cityController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _roleController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty &&
        _commentsController.text.trim().isNotEmpty;
  }

  Future<void> _submitFeedback() async {
    if (!_isFormValid() || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await _feedbackRepository.submitFeedback(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: _roleController.text.trim(),
        city: _cityController.text.trim(),
        comments: _commentsController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('feedback.success'.tr)),
        );
        _nameController.clear();
        _emailController.clear();
        _roleController.clear();
        _cityController.clear();
        _commentsController.clear();
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('feedback.failed'.tr)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
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
    return Scaffold(
      backgroundColor: const Color(0xffF7F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 28.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Material(
                    color: AppConst.white,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Get.back(),
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 44.w,
                        height: 44.w,
                        child: Icon(Icons.arrow_back_rounded, color: AppConst.black, size: 24.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'appbar.feedback'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Tell us what we can improve',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppConst.textSecondary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppConst.black,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46.w,
                      height: 46.w,
                      decoration: BoxDecoration(
                        color: AppConst.primaryColor,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Icon(Icons.support_agent_rounded, color: AppConst.black, size: 24.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Your feedback helps us build a better T-Ride experience.',
                        style: TextStyle(
                          color: AppConst.white,
                          fontSize: 13.sp,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppConst.white,
                  borderRadius: BorderRadius.circular(26.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppConst.blackWithOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _modernField(
                      controller: _nameController,
                      label: 'common.name'.tr,
                      hint: 'feedback.hint_name'.tr,
                      icon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.name,
                    ),
                    SizedBox(height: 14.h),
                    _modernField(
                      controller: _emailController,
                      label: 'common.email'.tr,
                      hint: 'feedback.hint_email'.tr,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 14.h),
                    _modernField(
                      controller: _roleController,
                      label: 'common.role'.tr,
                      hint: 'feedback.hint_role'.tr,
                      icon: Icons.badge_outlined,
                    ),
                    SizedBox(height: 14.h),
                    _modernField(
                      controller: _cityController,
                      label: 'common.city'.tr,
                      hint: 'feedback.hint_city'.tr,
                      icon: Icons.location_city_outlined,
                    ),
                    SizedBox(height: 14.h),
                    _modernField(
                      controller: _commentsController,
                      label: 'feedback.label_comments'.tr,
                      hint: 'feedback.hint_comments'.tr,
                      icon: Icons.chat_bubble_outline_rounded,
                      keyboardType: TextInputType.multiline,
                      minLines: 4,
                      maxLines: 6,
                    ),
                    SizedBox(height: 22.h),
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: _isFormValid() && !_isSubmitting ? _submitFeedback : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConst.black,
                          disabledBackgroundColor: const Color(0xffD7D7D7),
                          foregroundColor: AppConst.white,
                          disabledForegroundColor: AppConst.grey,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.r),
                          ),
                        ),
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
                                'common.continue'.tr,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppConst.black,
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 7.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          style: TextStyle(
            color: AppConst.black,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppConst.grey,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(icon, color: AppConst.grey, size: 21.sp),
            filled: true,
            fillColor: const Color(0xffF6F6F6),
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18.r),
              borderSide: BorderSide(color: AppConst.primaryColor, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../consts/appConst.dart';
import '../../data/repositories/feedback_repository.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_textfield.dart';

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
    return _nameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _roleController.text.isNotEmpty &&
        _cityController.text.isNotEmpty &&
        _commentsController.text.isNotEmpty;
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
        // ignore: avoid_print
        print('Feedback submitted successfully');
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
      // ignore: avoid_print
      print('FeedbackScreen submit error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
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
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          CustomAppBar(title: 'appbar.feedback'.tr),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Field
                  Text(
                    'common.name'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    height: 55.h,
                    child: CustomTextField(
                      controller: _nameController,
                      hintText: 'feedback.hint_name'.tr,
                      keyboardType: TextInputType.name,
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Email Field
                  Text(
                    'common.email'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    height: 55.h,
                    child: CustomTextField(
                      controller: _emailController,
                      hintText: 'feedback.hint_email'.tr,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Role Field
                  Text(
                    'common.role'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    height: 55.h,
                    child: CustomTextField(
                      controller: _roleController,
                      hintText: 'feedback.hint_role'.tr,
                      keyboardType: TextInputType.text,
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // City Field
                  Text(
                    'common.city'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    height: 55.h,
                    child: CustomTextField(
                      controller: _cityController,
                      hintText: 'feedback.hint_city'.tr,
                      keyboardType: TextInputType.text,
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Comments Field
                  Text(
                    'feedback.label_comments'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    height: 120.h,
                    child: CustomTextField(
                      controller: _commentsController,
                      hintText: 'feedback.hint_comments'.tr,
                      keyboardType: TextInputType.multiline,
                      maxLines: 5,
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  SizedBox(height: 30.h),
                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: _isFormValid() && !_isSubmitting
                          ? _submitFeedback
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormValid()
                            ? AppConst.black
                            : AppConst.blackWithOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
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
                                color: AppConst.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

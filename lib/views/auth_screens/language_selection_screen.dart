import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_ride_rider_app/consts/appConst.dart';
import 'package:t_ride_rider_app/controllers/language_controller.dart';
import 'package:t_ride_rider_app/data/models/language_model.dart';

import '../../widgets/custom_appbar.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final LanguageController controller;
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LanguageController(), permanent: false);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _selectLanguage(LanguageModel lang) {
    controller.selectLanguage(lang);
    setState(() {
      _isExpanded = false;
      _animationController.reverse();
    });
  }

  Widget _buildFlag(LanguageModel lang) {
    final url = lang.flagUrl?.trim();
    if (url == null || url.isEmpty) {
      return Icon(Icons.flag_outlined, color: AppConst.grey, size: 22.sp);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4.r),
      child: Image.network(
        url,
        width: 24.w,
        height: 16.h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.flag_outlined, color: AppConst.grey, size: 22.sp),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: 24.w,
            height: 16.h,
            child: Center(
              child: SizedBox(
                width: 12.w,
                height: 12.w,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppConst.grey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CustomAppBar(title: 'lang_screen.title'.tr),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),
                  // "Select your language" text
                  Text(
                    'lang_screen.select_prompt'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 30.h),
                  // Loading / Error / Content
                  Obx(() {
                    if (controller.isLoading.value) {
                      return Padding(
                        padding: EdgeInsets.only(top: 40.h),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (controller.errorMessage.value != null) {
                      return Padding(
                        padding: EdgeInsets.only(top: 40.h),
                        child: Column(
                          children: [
                            Text(
                              'lang_screen.load_failed'.tr,
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 16.sp,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            TextButton(
                              onPressed: controller.fetchLanguages,
                              child: Text('common.retry'.tr),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  Obx(() {
                    if (controller.isLoading.value ||
                        controller.errorMessage.value != null) {
                      return const SizedBox.shrink();
                    }
                    final selected = controller.selectedLanguage.value;
                    return Column(
                      children: [
                        // Main selection card
                        GestureDetector(
                          onTap: _toggleDropdown,
                          child: Container(
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
                              boxShadow: [
                                BoxShadow(
                                  color: AppConst.blackWithOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                if (selected != null) ...[
                                  _buildFlag(selected),
                                  SizedBox(width: 12.w),
                                  Text(
                                    selected.name,
                                    style: TextStyle(
                                      color: AppConst.black,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    'lang_screen.select_placeholder'.tr,
                                    style: TextStyle(
                                      color: AppConst.grey,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                AnimatedRotation(
                                  turns: _isExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: AppConst.black,
                                    size: 24.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Expandable language list
                        SizeTransition(
                          sizeFactor: _expandAnimation,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              // Limit height so long lists don't overflow screen
                              maxHeight: 400.h,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                children: controller.filteredLanguages.map((
                                  lang,
                                ) {
                                  final isSelected = selected?.id == lang.id;
                                  return Padding(
                                    padding: EdgeInsets.only(top: 12.h),
                                    child: GestureDetector(
                                      onTap: () => _selectLanguage(lang),
                                      child: Container(
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
                                          border: isSelected
                                              ? Border.all(
                                                  color: AppConst.black,
                                                  width: 2,
                                                )
                                              : null,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppConst.blackWithOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            _buildFlag(lang),
                                            SizedBox(width: 12.w),
                                            Text(
                                              lang.name,
                                              style: TextStyle(
                                                color: AppConst.black,
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w500,
                                                decoration: isSelected
                                                    ? TextDecoration.underline
                                                    : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  const Spacer(),
                  // Continue Button
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: controller.selectedLanguage.value != null
                            ? controller.continueAction
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              controller.selectedLanguage.value != null
                              ? AppConst.accent
                              : AppConst.accentWithOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppConst.buttonRadius,
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'common.continue'.tr,
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
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

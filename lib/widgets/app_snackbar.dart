import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../consts/appConst.dart';
import '../utils/api_error_message.dart';

/// App-wide black snackbars (GetX). Use this instead of [Get.snackbar].
abstract final class AppSnackBar {
  static const Duration _defaultDuration = Duration(seconds: 3);

  /// Generic black snackbar.
  static void show(
    String title,
    String message, {
    Duration? duration,
    IconData? icon,
  }) {
    _showBlack(
      title: title,
      message: message,
      duration: duration ?? _defaultDuration,
      icon: icon,
    );
  }

  static void showApiError(
    Object error, {
    String? fallbackMessage,
  }) {
    showError(
      title: 'common.error'.tr,
      message: apiErrorMessage(error, fallback: fallbackMessage ?? 'common.something_went_wrong'.tr),
    );
  }

  static void showError({
    String? title,
    required String message,
    Duration duration = _defaultDuration,
  }) {
    show(title ?? 'common.error'.tr, message, duration: duration, icon: Icons.error_outline_rounded);
  }

  static void showSuccess({
    String? title,
    required String message,
    Duration duration = _defaultDuration,
  }) {
    show(
      title ?? 'common.success'.tr,
      message,
      duration: duration,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  /// Same as [showError] — kept for existing call sites: `AppSnackBar.error(t, m)`.
  static void error(String title, String message, {Duration? duration}) {
    show(
      title,
      message,
      duration: duration ?? _defaultDuration,
      icon: Icons.error_outline_rounded,
    );
  }

  /// Same as [showSuccess] — kept for existing call sites: `AppSnackBar.success(t, m)`.
  static void success(String title, String message, {Duration? duration}) {
    show(
      title,
      message,
      duration: duration ?? _defaultDuration,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  static void _showBlack({
    required String title,
    required String message,
    required Duration duration,
    IconData? icon,
  }) {
    if (Get.context == null) return;

    Get.closeAllSnackbars();

    final topInset = MediaQuery.paddingOf(Get.context!).top;

    Get.snackbar(
      '',
      '',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.transparent,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      duration: duration,
      titleText: const SizedBox.shrink(),
      messageText: Padding(
        padding: EdgeInsets.fromLTRB(16.w, topInset + 8.h, 16.w, 0),
        child: Material(
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppConst.black,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(16.r),
                bottomLeft: Radius.circular(16.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppConst.blackWithOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: AppConst.white.withValues(alpha: 0.9),
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title.isNotEmpty) ...[
                          Text(
                            title,
                            style: TextStyle(
                              color: AppConst.white,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 6.h),
                        ],
                        Text(
                          message,
                          style: TextStyle(
                            color: AppConst.white.withValues(alpha: 0.88),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

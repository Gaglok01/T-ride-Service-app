import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../consts/appConst.dart';

class CustomTextField extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final TextInputType? keyboardType;
  final int? maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;

  const CustomTextField({
    super.key,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topRight: Radius.circular(12.r),
      bottomLeft: Radius.circular(12.r),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      focusNode: focusNode,
      cursorColor: AppConst.black,
      style: TextStyle(color: AppConst.black, fontSize: 16.sp),
      decoration: InputDecoration(
        fillColor: AppConst.cardLight,
        filled: true,
        hintText: hintText ?? '',
        hintStyle: TextStyle(
          color: AppConst.blackWithOpacity(0.45),
          fontSize: 16.sp,
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 18.h,
        ),
        // Subtle outline visible on both yellow and white scaffolds, then
        // a stronger outline on focus for contrast in both themes.
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: AppConst.blackWithOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: AppConst.blackWithOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: AppConst.blackWithOpacity(0.6),
            width: 1.5,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: AppConst.blackWithOpacity(0.04)),
        ),
      ),
    );
  }
}

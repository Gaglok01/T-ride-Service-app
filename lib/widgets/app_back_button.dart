import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../consts/appConst.dart';

/// Uses [BackButtonIcon] so the glyph mirrors correctly in RTL (e.g. Arabic).
class AppBackIconButton extends StatelessWidget {
  const AppBackIconButton({
    super.key,
    this.onPressed,
    this.color,
    this.iconSize,
  });

  final VoidCallback? onPressed;
  final Color? color;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return IconTheme(
      data: IconThemeData(
        color: color ?? AppConst.white,
        size: iconSize ?? 24,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: const BackButtonIcon(),
        onPressed: onPressed ?? () => Get.back(),
      ),
    );
  }
}

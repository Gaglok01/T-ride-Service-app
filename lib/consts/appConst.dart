import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppConst {
  static const String appName = 'T Ride';
  static const String logoBlack = 'assets/T 1.png';
  static const String NewLogo =
      'assets/WhatsApp_Image_2025-12-31_at_2.44.07_AM-removebg-preview.png';

  // ---------------------------------------------------------------------------
  // Theme mode
  // ---------------------------------------------------------------------------
  // The app supports two themes:
  //   * Yellow theme  -> isDarkMode == false (default)
  //   * White  theme  -> isDarkMode == true
  //
  // The boolean name "isDarkMode" is kept for backward-compat with the
  // existing controller, persistence key, and toggle UI. Semantically it now
  // means "white theme on?". When this flips, ThemeController calls
  // Get.forceAppUpdate() so widgets reading the getters below rebuild.
  static bool isDarkMode = false;

  // ---------------------------------------------------------------------------
  // Design system v3 — Yellow + White themes
  // ---------------------------------------------------------------------------
  // Both themes use BLACK foreground (text/icons). Only the scaffold and
  // card surfaces change between themes:
  //
  //   Yellow theme  -> scaffold = brand yellow, cards = white
  //   White  theme  -> scaffold = pure white,   cards = light grey (#EFEFEF)
  //
  // [black] and [white] are now mode-independent (always black / always white)
  // so branded headers (Container(color: AppConst.black) + AppConst.white
  // foreground) stay correctly styled in BOTH themes.
  // ---------------------------------------------------------------------------

  // ===== Yellow theme palette =====
  static const Color _yellowScaffold = Color(0xffFDC700); // brand yellow
  static const Color _yellowCard = Color(0xffFFFFFF); // white cards on yellow

  // ===== White theme palette =====
  static const Color _whiteScaffold = Color(0xffFFFFFF); // pure white
  static const Color _whiteCard = Color(0xffEFEFEF); // light grey cards

  // ===== Constants (do NOT flip between themes) =====
  static const Color _foreground = Color(0xff000000); // text / icons
  static const Color _inverseForeground = Color(0xffFFFFFF); // on-black headers
  static const Color _grey = Color(0xff808080);

  // ---------------------------------------------------------------------------
  // Accent (mode-independent yellow)
  // ---------------------------------------------------------------------------

  /// Brand accent (yellow). Used for CTA buttons, highlights, indicators.
  /// Keeps the old name [primaryColor] so existing accent-style usages
  /// (icons, splashes, indicators) keep working unchanged.
  static const Color primaryColor = Color(0xffFDC700);

  /// Alias of [primaryColor] for new design-system call sites.
  static const Color accent = Color(0xffFDC700);

  // ---------------------------------------------------------------------------
  // Mode-aware semantic tokens
  // ---------------------------------------------------------------------------

  /// Scaffold background.
  ///   Yellow theme -> brand yellow
  ///   White  theme -> pure white
  static Color get background =>
      isDarkMode ? _whiteScaffold : _yellowScaffold;

  /// Card / surface color (sits on top of [background]).
  ///   Yellow theme -> white
  ///   White  theme -> light grey (#EFEFEF)
  static Color get cardLight => isDarkMode ? _whiteCard : _yellowCard;

  /// Foreground for text & icons. Always black — text contrast on both
  /// themes is black, per design spec.
  static Color get black => _foreground;

  /// Inverse foreground (e.g. icons / labels sitting on a [black]-coloured
  /// branded header). Always white — branded headers are black in both
  /// themes, so this stays white in both themes too.
  static Color get white => _inverseForeground;

  /// Secondary / de-emphasised label text. Black with opacity so it works on
  /// both yellow and white scaffolds, plus white and grey cards.
  static Color get textSecondary => _foreground.withValues(alpha: 0.6);

  /// Mid grey, used for hints and dividers.
  static Color get grey => _grey;

  // ---------------------------------------------------------------------------
  // Static helpers
  // ---------------------------------------------------------------------------

  static const Color transparent = Colors.transparent;

  /// Brownish-yellow used by the legacy continue button.
  static const Color continueButtonColor = Color(0xffD4A574);

  /// Blue for the selected language border.
  static const Color selectedBorderColor = Color(0xff2196F3);

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Foreground-with-opacity. Always black-with-opacity since [black] is
  /// constant in both Yellow and White themes.
  static Color blackWithOpacity(double opacity) =>
      _foreground.withValues(alpha: opacity);

  static Color primaryColorWithOpacity(double opacity) {
    return Color.fromRGBO(253, 199, 0, opacity);
  }

  /// Shorthand for accent-with-opacity (semantic alias of
  /// [primaryColorWithOpacity]).
  static Color accentWithOpacity(double opacity) =>
      primaryColorWithOpacity(opacity);

  /// Standard (legacy) topRight/bottomLeft asymmetric corner radius.
  static BorderRadius get borderRadius => BorderRadius.only(
    topRight: Radius.circular(20.r),
    bottomLeft: Radius.circular(20.r),
  );

  /// Round / pill-shape radius for primary CTA buttons.
  static BorderRadius get buttonRadius => BorderRadius.circular(28.r);
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:t_ride_rider_app/controllers/theme_controller.dart';
import 'package:t_ride_rider_app/core/config/stripe_config.dart';
import 'package:t_ride_rider_app/data/local/secure_storage_service.dart';
import 'package:t_ride_rider_app/firebase_options.dart';
import 'package:t_ride_rider_app/views/splash/splash_screen.dart';
import 'consts/appConst.dart';
import 'localization/app_translations.dart';

Future<void> _initFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on UnsupportedError catch (_) {
    if (kDebugMode) {
      debugPrint(
        'Firebase: DefaultFirebaseOptions not configured for this platform.',
      );
    }
  } catch (e, st) {
    debugPrint('Firebase.initializeApp failed: $e');
    if (kDebugMode) {
      debugPrint('$st');
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = StripeConfig.publishableKey;
  await Stripe.instance.applySettings();
  await _initFirebase();
  // Set global system UI overlay style - white icons for all screens
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // White icons
      statusBarBrightness: Brightness.dark, // For iOS
    ),
  );
  final storage = SecureStorageService();
  final savedLang = await storage.getAppLocaleLanguageCode();
  final supportedCodes =
      AppTranslations.supportedLocales.map((l) => l.languageCode).toSet();
  if (savedLang != null && supportedCodes.contains(savedLang)) {
    Get.locale = AppTranslations.localeForLanguageCode(savedLang);
  } else {
    // First launch (or invalid stored code): GetX needs a non-null locale or
    // `.tr` shows raw keys until the user changes language once.
    Get.locale = AppTranslations.en;
  }

  // Theme controller — load persisted dark-mode preference before runApp so
  // the very first frame uses the correct palette.
  final themeController = Get.put(ThemeController(storage: storage));
  await themeController.loadInitial();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        // Observe ThemeController so the whole MaterialApp tree rebuilds when
        // the user toggles between Yellow and White themes — every widget
        // that reads from AppConst (theme-aware getters) picks up the new
        // palette on rebuild.
        return Obx(() {
          // Touch the reactive flag so Obx re-runs on toggle, even though
          // we don't otherwise read it (AppConst.isDarkMode is the source
          // of truth used by _buildTheme).
          Get.find<ThemeController>().isDarkMode.value;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
            child: GetMaterialApp(
              title: 'T Ride',
              debugShowCheckedModeBanner: false,
              translations: AppTranslations(),
              locale: Get.locale ?? AppTranslations.en,
              fallbackLocale: AppTranslations.en,
              supportedLocales: AppTranslations.supportedLocales,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              // Both Yellow and White themes use light-brightness Material
              // defaults (black text on light surfaces). We force themeMode
              // to light and rebuild the single theme using AppConst tokens
              // when the user toggles.
              themeMode: ThemeMode.light,
              theme: _buildTheme(),
              home: const SplashScreen(),
            ),
          );
        });
      },
    );
  }

  /// Build a [ThemeData] from the current [AppConst] tokens. Both Yellow
  /// and White themes use light brightness — only the surface/scaffold
  /// colors change between them, which we read straight from [AppConst].
  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppConst.black,
      scaffoldBackgroundColor: AppConst.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConst.accent,
        brightness: Brightness.light,
        primary: AppConst.black,
        onPrimary: AppConst.white,
        secondary: AppConst.accent,
        onSecondary: AppConst.black,
        surface: AppConst.cardLight,
        onSurface: AppConst.black,
      ),
      useMaterial3: true,
    );
  }
}

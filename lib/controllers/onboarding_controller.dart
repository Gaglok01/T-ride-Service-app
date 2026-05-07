import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/local/secure_storage_service.dart';
import '../views/auth_screens/language_selection_screen.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;
  final SecureStorageService _storageService = SecureStorageService();

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  void nextPage() {
    if (currentPage.value < 3) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Mark onboarding as completed and navigate to language selection screen
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    await _storageService.setOnboardingCompleted();
    Get.offAll(() => const LanguageSelectionScreen());
  }

  void previousPage() {
    if (currentPage.value > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}


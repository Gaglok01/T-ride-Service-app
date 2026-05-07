import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_ride_rider_app/widgets/app_back_button.dart';
import '../../consts/appConst.dart';
import '../../controllers/onboarding_controller.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingController());

    final List<OnboardingData> onboardingData = [
      OnboardingData(
        titleKey: 'onboard.1.title',
        descriptionKey: 'onboard.1.body',
        imagePath: 'assets/image-removebg-preview 1.png',
      ),
      OnboardingData(
        titleKey: 'onboard.2.title',
        descriptionKey: 'onboard.2.body',
        imagePath: 'assets/fda09075-9e94-4381-889f-3fed533e537e 1.png',
      ),
      OnboardingData(
        titleKey: 'onboard.3.title',
        descriptionKey: 'onboard.3.body',
        imagePath:
            'assets/WhatsApp_Image_2025-12-18_at_11.50.46_AM-removebg-preview.png',
      ),
      OnboardingData(
        titleKey: 'onboard.4.title',
        descriptionKey: 'onboard.4.body',
        imagePath: 'assets/_Hoodie Sale Instagram Post (1) 1.png',
      ),
    ];

    return Scaffold(
      backgroundColor: AppConst.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppConst.black,
              AppConst.black,

              AppConst.transparent,
              AppConst.primaryColor,

              AppConst.primaryColor,
              AppConst.primaryColor,
            ],
            // stops: const [0.5, 0.6, 0.5],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back Button
              Obx(
                () => controller.currentPage.value > 0
                    ? Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: 20.w,
                          top: 10.h,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: AppBackIconButton(
                            color: AppConst.white,
                            iconSize: 24.sp,
                            onPressed: () => controller.previousPage(),
                          ),
                        ),
                      )
                    : SizedBox(height: 60.h),
              ),
              // PageView
              Expanded(
                child: PageView.builder(
                  controller: controller.pageController,
                  onPageChanged: controller.onPageChanged,
                  itemCount: onboardingData.length,
                  itemBuilder: (context, index) {
                    return OnboardingPage(
                      data: onboardingData[index],
                      index: index,
                    );
                  },
                ),
              ),
              // Pagination Dots
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    onboardingData.length,
                    (index) => Container(
                      width: 8.w,
                      height: 8.w,
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: controller.currentPage.value == index
                            ? AppConst.white
                            : AppConst.blackWithOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),

              // Next/Done Button
              Obx(
                () => Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 30.h,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: controller.nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConst.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        controller.currentPage.value ==
                                onboardingData.length - 1
                            ? 'onboard.get_started'.tr
                            : 'onboard.next'.tr,
                        style: TextStyle(
                          color: AppConst.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final int index;

  const OnboardingPage({super.key, required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image
          Container(
            margin: EdgeInsets.only(bottom: 40.h),
            decoration: BoxDecoration(color: Colors.transparent),
            child: Image.asset(
              data.imagePath,
              // width: 400.w,
              height: 350.h,
              fit: BoxFit.cover,
            ),
          ),
          // Title
          Text(
            data.titleKey.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppConst.black,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          SizedBox(height: 16.h),
          // Description
          Text(
            data.descriptionKey.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppConst.blackWithOpacity(0.7),
              fontSize: 14.sp,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String titleKey;
  final String descriptionKey;
  final String imagePath;

  OnboardingData({
    required this.titleKey,
    required this.descriptionKey,
    required this.imagePath,
  });
}

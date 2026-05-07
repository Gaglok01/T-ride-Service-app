import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_ride_rider_app/views/setting/setting_screen.dart';
import '../../../consts/appConst.dart';
import '../car_rental/car_rental_view.dart';

class RentalHomeView extends StatelessWidget {
  const RentalHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    String searchText = '';
    return Scaffold(
      backgroundColor: AppConst.background,
      body: SingleChildScrollView(
        child: StatefulBuilder(
          builder: (context, setState) {
            final q = searchText;
            final showCar =
                q.isEmpty ||
                'car rental rent a car easily for daily or long-term use car'
                    .contains(q);
            final showApartment =
                q.isEmpty ||
                'apartment rental find comfortable apartments for short or long stays apartment'
                    .contains(q);
            final showHouse =
                q.isEmpty ||
                'house rentals browse houses available for rent at affordable prices house'
                    .contains(q);
            return Column(
              children: [
                // Top Header (Black Background)
                Container(
                  decoration: BoxDecoration(
                    color: AppConst.black,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20.r),
                      bottomRight: Radius.circular(20.r),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        SizedBox(height: 8.h),
                        // Navigation Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Get.back(),
                              child: Icon(
                                Directionality.of(context) == TextDirection.rtl
                                    ? Icons.arrow_forward
                                    : Icons.arrow_back,
                                color: AppConst.white,
                                size: 24.sp,
                              ),
                            ),
                            Text(
                              'Rental Service',
                              style: TextStyle(
                                color: AppConst.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Get.to(() => const SettingScreen());
                              },
                              child: Icon(
                                Icons.settings,
                                color: AppConst.white,
                                size: 24.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        // Search Bar
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppConst.cardLight,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                searchText = value.trim().toLowerCase();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'rental.search_hint'.tr,
                              hintStyle: TextStyle(
                                color: AppConst.grey,
                                fontSize: 14.sp,
                              ),
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.search,
                                color: AppConst.grey,
                                size: 20.sp,
                              ),
                              isDense: true,
                              contentPadding: EdgeInsets.only(top: 10),
                            ),
                            style: TextStyle(
                              color: AppConst.black,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),
                // Main Content
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      Text(
                        'Find Rentals Near You',
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Rental Category Cards
                      if (showCar) ...[
                        _buildRentalCard(
                          imageIcon: Icons.directions_car,
                          title: 'rental.car'.tr,
                          category: 'Car',
                          description:
                              'Rent a car easily for daily or long-term use.',
                        ),
                        if (showApartment || showHouse) SizedBox(height: 16.h),
                      ],
                      if (showApartment) ...[
                        _buildRentalCard(
                          imageIcon: Icons.apartment,
                          title: 'rental.apartment'.tr,
                          category: 'Apartment',
                          description:
                              'Find comfortable apartments for short or long stays.',
                          imagePath: 'assets/apartment.jpeg',
                        ),
                        if (showHouse) SizedBox(height: 16.h),
                      ],
                      if (showHouse) ...[
                        _buildRentalCard(
                          imageIcon: Icons.home,
                          title: 'rental.house'.tr,
                          category: 'House',
                          description:
                              'Browse houses available for rent at affordable prices.',
                          imagePath: 'assets/house.jpeg',
                        ),
                      ],
                      if (!showCar && !showApartment && !showHouse) ...[
                        Padding(
                          padding: EdgeInsets.only(top: 10.h),
                          child: Text(
                            'No results found.',
                            style: TextStyle(
                              color: AppConst.black,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRentalCard({
    required IconData imageIcon,
    required String title,
    required String category,
    required String description,
    String? imagePath,
  }) {
    return GestureDetector(
      onTap: () {
        Get.to(
          () => CarRentalView(
            title: title,
            description: description,
            category: category,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          // color: AppConst.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            // BoxShadow(
            //   color: AppConst.black.withOpacity(0.08),
            //   blurRadius: 8,
            //   offset: const Offset(0, 2),
            // ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Container(
              height: 150.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppConst.grey.withOpacity(0.2),
                borderRadius: AppConst.borderRadius,
              ),
              child: Stack(
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: AppConst.borderRadius,
                      child: Image.asset(
                        imagePath ?? 'assets/Frame 73.png',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            imageIcon,
                            color: AppConst.grey,
                            size: 60.sp,
                          );
                        },
                      ),
                    ),
                  ),
                  // Add Button
                  // Positioned(
                  //   bottom: 12.h,
                  //   right: 12.w,
                  //   child: GestureDetector(
                  //     onTap: () {
                  //       // TODO: Handle add to favorites or quick action
                  //     },
                  //     child: Container(
                  //       width: 32.w,
                  //       height: 32.w,
                  //       decoration: BoxDecoration(
                  //         color: AppConst.black,
                  //         shape: BoxShape.circle,
                  //       ),
                  //       child: Icon(
                  //         Icons.add,
                  //         color: AppConst.white,
                  //         size: 20.sp,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
            // Content Section
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    description,
                    style: TextStyle(color: AppConst.black, fontSize: 12.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

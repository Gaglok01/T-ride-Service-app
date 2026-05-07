import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:t_ride_rider_app/views/location/select_location_screen.dart';
import 'package:t_ride_rider_app/views/setting/feedback_screen.dart';
import 'package:t_ride_rider_app/views/setting/profile_screen.dart';
import '../../consts/appConst.dart';
import 'home_screen.dart';
import 'list_screen.dart';
import 'help_screen.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ListScreen(),
    const FeedbackScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: _screens[_currentIndex],
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppConst.cardLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppConst.blackWithOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Home Icon
                    _buildNavItem(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      index: 0,
                    ),
                    // List Icon
                    _buildNavItem(
                      icon: Icons.menu_outlined,
                      selectedIcon: Icons.menu,
                      index: 1,
                    ),
                    // Spacer for Add Button
                    // Help Icon
                    _buildNavItem(
                      icon: Icons.help_outline,
                      selectedIcon: Icons.help,
                      index: 2,
                    ),
                    // Profile Icon
                    _buildNavItem(
                      icon: Icons.person_outline,
                      selectedIcon: Icons.person,
                      index: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Add Button (Floating - positioned above)
          // Positioned(
          //   top: -28.h,
          //   child: GestureDetector(
          //     onTap: () {
          //       Get.to(() => const SelectLocationScreen());
          //     },
          //     child: Container(
          //       width: 60.w,
          //       height: 60.w,
          //       decoration: BoxDecoration(
          //         color: AppConst.black,
          //         shape: BoxShape.circle,
          //         boxShadow: [
          //           BoxShadow(
          //             color: AppConst.blackWithOpacity(0.3),
          //             blurRadius: 8,
          //             offset: const Offset(0, 2),
          //           ),
          //         ],
          //       ),
          //       child: Center(
          //         child: Text(
          //           'book\nRide',
          //           textAlign: TextAlign.center,
          //           style: TextStyle(
          //             color: AppConst.white,
          //             fontSize: 12.sp,
          //             fontWeight: FontWeight.w700,
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppConst.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Icon(
          isSelected ? selectedIcon : icon,
          color: AppConst.black,
          size: 24.sp,
        ),
      ),
    );
  }
}

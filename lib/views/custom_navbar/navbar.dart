import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../consts/appConst.dart';
import 'home_screen.dart';
import 'list_screen.dart';
import 'help_screen.dart';
import '../setting/profile_screen.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ListScreen(),
    HelpScreen(),
    ProfileScreen(),
  ];

  final List<_NavEntry> _items = const [
    _NavEntry(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _NavEntry(
      label: 'Orders',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
    ),
    _NavEntry(
      label: 'Help',
      icon: Icons.support_agent_outlined,
      selectedIcon: Icons.support_agent_rounded,
    ),
    _NavEntry(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: _screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26.r),
            border: Border.all(color: const Color(0xFFEDEEF2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              _items.length,
              (index) => _buildNavItem(_items[index], index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavEntry item, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(vertical: 9.h),
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          decoration: BoxDecoration(
            color: isSelected ? AppConst.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? item.selectedIcon : item.icon,
                color: AppConst.black,
                size: 22.sp,
              ),
              SizedBox(height: 3.h),
              Text(
                item.label,
                style: TextStyle(
                  color: AppConst.black,
                  fontSize: 10.sp,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavEntry {
  const _NavEntry({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

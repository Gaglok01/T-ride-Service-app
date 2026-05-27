import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_ride_rider_app/data/models/roles_model.dart';
import 'package:t_ride_rider_app/data/repositories/roles_repository.dart';
import 'package:t_ride_rider_app/widgets/custom_appbar.dart';
import '../../../consts/appConst.dart';
import 'profile_setup_screen.dart';

class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

/// Registration only offers these roles, in this order, and only if the API returns them.
const List<String> _kRegistrationRoleSlugs = ['customer', 'vendor'];

List<Role> _filterRegistrationRoles(List<Role> apiRoles) {
  final bySlug = <String, Role>{};
  for (final r in apiRoles) {
    final slug = (r.name ?? '').trim().toLowerCase();
    if (slug.isEmpty) continue;
    bySlug[slug] = r;
  }
  final out = <Role>[];
  for (final slug in _kRegistrationRoleSlugs) {
    final match = bySlug[slug];
    if (match != null) out.add(match);
  }
  return out;
}

String _displayRoleName(Role role) {
  final n = (role.name ?? '').trim();
  if (n.isEmpty) return n;
  if (n.length == 1) return n.toUpperCase();
  return '${n[0].toUpperCase()}${n.substring(1).toLowerCase()}';
}

class _RoleScreenState extends State<RoleScreen>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  Role? _selectedRole;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  final RolesRepository _rolesRepository = RolesRepository();
  final List<Role> _roles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _fetchRoles();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchRoles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final roles = await _rolesRepository.getRoles();
      setState(() {
        _roles
          ..clear()
          ..addAll(_filterRegistrationRoles(roles));
      });
    } catch (e) {
      // ignore: avoid_print
      print('RoleScreen fetch roles error: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleDropdown() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _selectRole(Role role) {
    setState(() {
      _selectedRole = role;
      _isExpanded = false;
      _animationController.reverse();
    });
  }

  IconData _iconForRole(Role role) {
    switch ((role.name ?? '').trim().toLowerCase()) {
      case 'customer':
      case 'rider':
        return Icons.person_rounded;
      case 'vendor':
        return Icons.storefront_outlined;
      default:
        return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          CustomAppBar(title: 'Continue as'),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),
                  // "Select your role" text
                  Text(
                    'Choose how you want to use T-Ride',
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 30.h),
                  if (_isLoading) ...[
                    Center(
                      child: CircularProgressIndicator(color: AppConst.black),
                    ),
                  ] else if (_error != null) ...[
                    Column(
                      children: [
                        Text(
                          'role.load_failed'.tr,
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        TextButton(
                          onPressed: _fetchRoles,
                          child: Text('common.retry'.tr),
                        ),
                      ],
                    ),
                  ] else if (_roles.isEmpty) ...[
                    Text(
                      'role.empty_roles'.tr,
                      style: TextStyle(
                        color: AppConst.black,
                        fontSize: 15.sp,
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: _fetchRoles,
                      child: Text('common.refresh'.tr),
                    ),
                  ] else ...[
                    // Dropdown container
                    Column(
                      children: [
                        // Main selection card
                        GestureDetector(
                          onTap: _toggleDropdown,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 18.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppConst.cardLight,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(12.r),
                                bottomLeft: Radius.circular(12.r),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppConst.blackWithOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                if (_selectedRole != null) ...[
                                  Icon(
                                    _iconForRole(_selectedRole!),
                                    color: AppConst.black,
                                    size: 24.sp,
                                  ),
                                  SizedBox(width: 12.w),
                                  Text(
                                    _displayRoleName(_selectedRole!),
                                    style: TextStyle(
                                      color: AppConst.black,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    'Continue as Customer or Vendor',
                                    style: TextStyle(
                                      color: AppConst.grey,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                AnimatedRotation(
                                  turns: _isExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: AppConst.black,
                                    size: 24.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Expandable role list
                        SizeTransition(
                          sizeFactor: _expandAnimation,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              // Prevent the list from taking more than ~40% of screen height
                              maxHeight: 300.h,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                children: _roles.map((role) {
                                  final isSelected =
                                      _selectedRole?.id == role.id;
                                  return Padding(
                                    padding: EdgeInsets.only(top: 12.h),
                                    child: GestureDetector(
                                      onTap: () => _selectRole(role),
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 18.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppConst.cardLight,
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(12.r),
                                            bottomLeft: Radius.circular(12.r),
                                          ),
                                          border: isSelected
                                              ? Border.all(
                                                  color: AppConst.black,
                                                  width: 2,
                                                )
                                              : null,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppConst.blackWithOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _iconForRole(role),
                                              color: AppConst.black,
                                              size: 24.sp,
                                            ),
                                            SizedBox(width: 12.w),
                                            Text(
                                              _displayRoleName(role),
                                              style: TextStyle(
                                                color: AppConst.black,
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w500,
                                                decoration: isSelected
                                                    ? TextDecoration.underline
                                                    : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Spacer(),
                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: _selectedRole != null
                          ? () {
                              // Both Customer and Vendor go to ProfileSetupScreen first
                              Get.to(
                                () => ProfileSetupScreen(
                                  role: _selectedRole!.name ?? '',
                                ),
                                arguments:
                                    Get.arguments as Map<String, dynamic>? ??
                                    {},
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedRole != null
                            ? AppConst.black
                            : AppConst.blackWithOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'role.continue'.tr,
                        style: TextStyle(
                          color: AppConst.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



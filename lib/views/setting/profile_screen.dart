import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:t_ride_rider_app/data/repositories/profile_repository.dart';
import 'package:t_ride_rider_app/views/setting/setting_screen.dart';
import '../../consts/appConst.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_textfield.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final ProfileRepository _profileRepository = ProfileRepository();
  bool _isLoading = true;
  bool _isSaving = false;
  File? _selectedPhoto;
  String? _existingPhotoUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _regionController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final profile = await _profileRepository.getProfile();
      if (!mounted) return;
      setState(() {
        _nameController.text = profile.name ?? '';
        _addressController.text = profile.address ?? '';
        _cityController.text = profile.city ?? '';
        _regionController.text = profile.city ?? '';
        // If backend sends a photo URL, store it for display.
        _existingPhotoUrl = profile.photo;
      });
    } catch (e) {
      // ignore: avoid_print
      print('ProfileScreen loadProfile error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _addressController.text.trim().isNotEmpty &&
      _regionController.text.trim().isNotEmpty &&
      _cityController.text.trim().isNotEmpty;

  Future<void> _saveProfile() async {
    if (_isSaving || !_isFormValid) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = await _profileRepository.updateProfile(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        region: _regionController.text.trim(),
        city: _cityController.text.trim(),
        photoFile: _selectedPhoto,
      );

      // refresh controllers with server data (in case backend normalized them)
      _nameController.text = updated.name ?? _nameController.text;
      _addressController.text = updated.address ?? _addressController.text;
      _cityController.text = updated.city ?? _cityController.text;
      _regionController.text = _regionController.text;
      _existingPhotoUrl = updated.photo ?? _existingPhotoUrl;

      AppSnackBar.show('common.success'.tr, 'profile.updated_success'.tr);
    } catch (e) {
      // ignore: avoid_print
      print('ProfileScreen saveProfile error: $e');
      AppSnackBar.show('common.error'.tr, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return;
      setState(() {
        _selectedPhoto = File(picked.path);
      });
    } catch (e) {
      // ignore: avoid_print
      print('ProfileScreen pickImage error: $e');
      AppSnackBar.show('common.error'.tr, 'profile.unable_pick_image'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          // Custom Header with Settings Icon
          Container(
            decoration: BoxDecoration(
              color: AppConst.black,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20.r),
                bottomRight: Radius.circular(20.r),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 60.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_forward
                            : Icons.arrow_back,
                        color: AppConst.white,
                        size: 24.sp,
                      ),
                      onPressed: () => Get.back(),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'profile.title'.tr,
                        style: TextStyle(
                          color: AppConst.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.settings,
                        color: AppConst.white,
                        size: 24.sp,
                      ),
                      onPressed: () {
                        Get.to(() => const SettingScreen());
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading) ...[
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 20.h),
                        child: CircularProgressIndicator(color: AppConst.black),
                      ),
                    ),
                  ],
                  // Profile Picture (tap to change)
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 80.w,
                            height: 80.w,
                            decoration: BoxDecoration(
                              color: AppConst.cardLight,
                              shape: BoxShape.circle,
                              image: _selectedPhoto != null
                                  ? DecorationImage(
                                      image: FileImage(_selectedPhoto!),
                                      fit: BoxFit.cover,
                                    )
                                  : (_existingPhotoUrl != null &&
                                        _existingPhotoUrl!.isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(_existingPhotoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child:
                                (_selectedPhoto == null &&
                                    (_existingPhotoUrl == null ||
                                        _existingPhotoUrl!.isEmpty))
                                ? Icon(
                                    Icons.person_outline,
                                    size: 30.sp,
                                    color: AppConst.black,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 24.w,
                              height: 24.w,
                              decoration: BoxDecoration(
                                color: AppConst.black,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: AppConst.white,
                                size: 14.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30.h),
                  // Name Field
                  Text(
                    'common.name'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    height: 55.h,
                    child: CustomTextField(
                      controller: _nameController,
                      hintText: 'profile.hint_name'.tr,
                      keyboardType: TextInputType.name,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Address Field
                  Text(
                    'common.address'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    height: 55.h,
                    child: CustomTextField(
                      controller: _addressController,
                      hintText: 'profile.hint_address'.tr,
                      keyboardType: TextInputType.streetAddress,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Region Field
                  Text(
                    'common.region'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    height: 55.h,
                    child: CustomTextField(
                      controller: _regionController,
                      hintText: 'profile.hint_region'.tr,
                      keyboardType: TextInputType.text,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // City Field
                  Text(
                    'common.city'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    height: 55.h,
                    child: CustomTextField(
                      controller: _cityController,
                      hintText: 'profile.hint_city'.tr,
                      keyboardType: TextInputType.text,
                    ),
                  ),
                  SizedBox(height: 30.h),
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: _isFormValid && !_isSaving
                          ? _saveProfile
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConst.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppConst.white,
                              ),
                            )
                          : Text(
                              'common.save'.tr,
                              style: TextStyle(
                                color: AppConst.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

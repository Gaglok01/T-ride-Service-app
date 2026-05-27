import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:t_ride_rider_app/data/models/user_profile_model.dart';
import 'package:t_ride_rider_app/data/repositories/profile_repository.dart';
import 'package:t_ride_rider_app/data/repositories/auth_repository.dart';
import 'package:t_ride_rider_app/views/auth_screens/login_screen.dart';
import 'package:t_ride_rider_app/views/setting/feedback_screen.dart';
import 'package:t_ride_rider_app/views/setting/setting_screen.dart';
import 'package:t_ride_rider_app/views/wallet/add_to_wallet/add_to_wallet_view.dart';

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
  final AuthRepository _authRepository = AuthRepository();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoggingOut = false;
  File? _selectedPhoto;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFormChanged);
    _addressController.addListener(_onFormChanged);
    _regionController.addListener(_onFormChanged);
    _cityController.addListener(_onFormChanged);
    _loadProfile();
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFormChanged);
    _addressController.removeListener(_onFormChanged);
    _regionController.removeListener(_onFormChanged);
    _cityController.removeListener(_onFormChanged);
    _nameController.dispose();
    _addressController.dispose();
    _regionController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _profileRepository.getProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _nameController.text = profile.name ?? '';
        _addressController.text = profile.address ?? '';
        _cityController.text = profile.city ?? '';
        _regionController.text = profile.region ?? '';
      });
    } catch (e) {
      if (mounted) AppSnackBar.show('common.error'.tr, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _addressController.text.trim().isNotEmpty &&
      _regionController.text.trim().isNotEmpty &&
      _cityController.text.trim().isNotEmpty;

  Future<void> _saveProfile() async {
    if (_isSaving || !_isFormValid) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final updated = await _profileRepository.updateProfile(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        region: _regionController.text.trim(),
        city: _cityController.text.trim(),
        photoFile: _selectedPhoto,
      );

      if (!mounted) return;
      setState(() {
        _profile = updated;
        _selectedPhoto = null;
        _nameController.text = updated.name ?? _nameController.text;
        _addressController.text = updated.address ?? _addressController.text;
        _cityController.text = updated.city ?? _cityController.text;
        _regionController.text = updated.region ?? _regionController.text;
      });

      if (Get.isBottomSheetOpen == true) Get.back();
      AppSnackBar.show('common.success'.tr, 'profile.updated_success'.tr);
    } catch (e) {
      if (mounted) AppSnackBar.show('common.error'.tr, e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1000,
      );
      if (picked == null) return;
      setState(() => _selectedPhoto = File(picked.path));
    } catch (e) {
      AppSnackBar.show('Photo upload', 'Unable to open photos. Please allow photo permission in Android settings and try again.');
    }
  }

  Future<void> _showPersonalInfoSheet() async {
    final name = _profile?.name ?? 'T-Ride User';
    final email = _profile?.email ?? 'Not added';
    final phone = _profile?.phoneNumber ?? _profile?.whatsappNumber ?? 'Not added';
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 22.h + MediaQuery.paddingOf(context).bottom),
        decoration: BoxDecoration(
          color: AppConst.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 42.w, height: 4.h, decoration: BoxDecoration(color: const Color(0xFFE1E3E8), borderRadius: BorderRadius.circular(99.r))),
            ),
            SizedBox(height: 18.h),
            _sectionTitle('Personal info', Icons.badge_outlined),
            SizedBox(height: 14.h),
            _infoRow(Icons.person_outline, 'Name', name),
            _infoRow(Icons.email_outlined, 'Email', email),
            _infoRow(Icons.phone_iphone, 'Phone', phone),
            _infoRow(Icons.home_outlined, 'Address', _profile?.address ?? 'Not set'),
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); _showEditProfileSheet(); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConst.black,
                  foregroundColor: AppConst.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                child: const Text('Edit profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditProfileSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.86),
          padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 18.h),
          decoration: BoxDecoration(
            color: AppConst.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 42.w, height: 4.h, decoration: BoxDecoration(color: const Color(0xFFE1E3E8), borderRadius: BorderRadius.circular(99.r))),
                SizedBox(height: 14.h),
                _buildProfileForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _onLogoutPressed() async {
    if (_isLoggingOut) return;

    final shouldLogout = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to book rides or view your account.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConst.black,
              foregroundColor: AppConst.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    setState(() => _isLoggingOut = true);
    try {
      await _authRepository.logout();
      if (!mounted) return;
      Get.offAll(() => const LoginScreen());
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show('Signed out locally', 'We could not reach the server, but your session was cleared on this device.');
      Get.offAll(() => const LoginScreen());
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: RefreshIndicator(
        color: AppConst.black,
        onRefresh: _loadProfile,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 28.h),
                child: Column(
                  children: [
                    if (_isLoading)
                      LinearProgressIndicator(
                        color: AppConst.black,
                        backgroundColor: AppConst.cardLight,
                      ),
                    SizedBox(height: 10.h),
                    _buildProfileHeader(),
                    SizedBox(height: 16.h),
                    _buildQuickActions(),
                    SizedBox(height: 16.h),
                    _buildAccountMenuCard(),
                    SizedBox(height: 16.h),
                    _buildAccountStatusCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 92.h,
      elevation: 0,
      backgroundColor: AppConst.black,
      foregroundColor: AppConst.white,
      leading: IconButton(
        icon: Icon(
          Directionality.of(context) == TextDirection.rtl
              ? Icons.arrow_forward
              : Icons.arrow_back,
        ),
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Get.to(() => const SettingScreen()),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsetsDirectional.only(start: 56.w, bottom: 14.h),
        title: Text(
          'profile.title'.tr,
          style: TextStyle(
            color: AppConst.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final name = (_profile?.name?.trim().isNotEmpty ?? false)
        ? _profile!.name!.trim()
        : 'T-Ride User';
    final email = _profile?.email ?? 'Complete your profile';
    final phone = _profile?.phoneNumber ?? _profile?.whatsappNumber ?? 'Phone not added';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: _cardDecoration(radius: 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildAvatar(),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 30.w,
                    height: 30.w,
                    decoration: BoxDecoration(
                      color: AppConst.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppConst.cardLight, width: 2),
                    ),
                    child: Icon(Icons.camera_alt, color: AppConst.white, size: 15.sp),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppConst.black,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppConst.textSecondary, fontSize: 12.sp),
                ),
                SizedBox(height: 5.h),
                Row(
                  children: [
                    Icon(Icons.phone_iphone, color: AppConst.textSecondary, size: 14.sp),
                    SizedBox(width: 5.w),
                    Expanded(
                      child: Text(
                        phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppConst.textSecondary, fontSize: 12.sp),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppConst.accentWithOpacity(0.25),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: AppConst.black, size: 15.sp),
                      SizedBox(width: 4.w),
                      Text(
                        '4.9 Rider',
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final photo = _profile?.photo;
    return Container(
      width: 88.w,
      height: 88.w,
      decoration: BoxDecoration(
        color: AppConst.background,
        shape: BoxShape.circle,
        border: Border.all(color: AppConst.blackWithOpacity(0.08), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: _selectedPhoto != null
          ? Image.file(_selectedPhoto!, fit: BoxFit.cover)
          : (photo != null && photo.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: photo,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Center(
                    child: CircularProgressIndicator(color: AppConst.black, strokeWidth: 2),
                  ),
                  errorWidget: (_, __, ___) => _avatarFallback(),
                )
              : _avatarFallback(),
    );
  }

  Widget _avatarFallback() {
    return Icon(Icons.person_rounded, color: AppConst.black, size: 42.sp);
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _quickAction(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallet',
            subtitle: _profile?.walletBalance == null ? 'Balance' : '\$${_profile!.walletBalance}',
            onTap: () => Get.to(() => const AddToWalletView()),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _quickAction(
            icon: Icons.history_rounded,
            title: 'Trips',
            subtitle: 'History',
            onTap: () => Get.snackbar('Trips', 'Ride history screen is the next MVP step.'),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _quickAction(
            icon: Icons.support_agent_rounded,
            title: 'Support',
            subtitle: 'Help',
            onTap: () => Get.to(() => const FeedbackScreen()),
          ),
        ),
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 14.h),
        decoration: _cardDecoration(radius: 18),
        child: Column(
          children: [
            Icon(icon, color: AppConst.black, size: 24.sp),
            SizedBox(height: 8.h),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppConst.black,
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppConst.textSecondary, fontSize: 11.sp),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAccountMenuCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Account', Icons.manage_accounts_outlined),
          SizedBox(height: 12.h),
          _profileMenuItem(Icons.badge_outlined, 'Personal info', 'View your rider identity and contact details', () {
            _showPersonalInfoSheet();
          }),
          _profileMenuItem(Icons.edit_outlined, 'Edit profile', 'Update name, address and profile photo', () {
            _showEditProfileSheet();
          }),
          _profileMenuItem(Icons.home_work_outlined, 'Saved places', 'Home, Work and favorites', () {
            Get.snackbar('Saved places', 'This screen is the next MVP step.');
          }),
          _profileMenuItem(Icons.payment_outlined, 'Payment methods', 'Card, cash and wallet', () => Get.to(() => const AddToWalletView())),
          _profileMenuItem(Icons.security_outlined, 'Security', 'Password and phone verification', () {
            Get.snackbar('Security', 'Security settings will connect to the backend.');
          }),
          _profileMenuItem(Icons.support_agent_outlined, 'Help & support', 'Contact the T-Ride team', () => Get.to(() => const FeedbackScreen())),
          Divider(height: 20.h, color: AppConst.blackWithOpacity(0.08)),
          _profileMenuItem(
            Icons.logout_rounded,
            _isLoggingOut ? 'Signing out...' : 'Sign out',
            'Securely leave this device',
            _onLogoutPressed,
            isDanger: true,
          ),
        ],
      ),
    );
  }

  Widget _profileMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    final color = isDanger ? Colors.red : AppConst.black;
    return InkWell(
      borderRadius: BorderRadius.circular(18.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: isDanger ? Colors.red.withValues(alpha: 0.08) : const Color(0xFFF2F3F5),
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: Icon(icon, color: color, size: 21.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color, fontSize: 14.sp, fontWeight: FontWeight.w900)),
                  SizedBox(height: 2.h),
                  Text(subtitle, style: TextStyle(color: AppConst.textSecondary, fontSize: 12.sp, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isDanger ? Colors.red : AppConst.textSecondary, size: 24.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Edit profile', Icons.edit_outlined),
          SizedBox(height: 16.h),
          _fieldLabel('common.name'.tr),
          CustomTextField(
            controller: _nameController,
            hintText: 'profile.hint_name'.tr,
            keyboardType: TextInputType.name,
          ),
          SizedBox(height: 14.h),
          _fieldLabel('common.address'.tr),
          CustomTextField(
            controller: _addressController,
            hintText: 'profile.hint_address'.tr,
            keyboardType: TextInputType.streetAddress,
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('common.city'.tr),
                    CustomTextField(
                      controller: _cityController,
                      hintText: 'profile.hint_city'.tr,
                      keyboardType: TextInputType.text,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('common.region'.tr),
                    CustomTextField(
                      controller: _regionController,
                      hintText: 'profile.hint_region'.tr,
                      keyboardType: TextInputType.text,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton.icon(
              onPressed: _isFormValid && !_isSaving ? _saveProfile : null,
              icon: _isSaving
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppConst.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_isSaving ? 'Saving...' : 'common.save'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConst.black,
                foregroundColor: AppConst.white,
                disabledBackgroundColor: AppConst.grey.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                textStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStatusCard() {
    final status = _profile?.status ?? 'active';
    final roles = (_profile?.roles ?? [])
        .map((role) => role.name)
        .whereType<String>()
        .where((role) => role.isNotEmpty)
        .join(', ');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Account', Icons.verified_user_outlined),
          SizedBox(height: 14.h),
          _infoRow(Icons.verified_rounded, 'Status', status),
          _infoRow(Icons.groups_2_outlined, 'Role', roles.isEmpty ? 'Rider' : roles),
          _infoRow(Icons.location_on_outlined, 'Default city', _profile?.city ?? 'Not set'),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppConst.black, size: 22.sp),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            color: AppConst.black,
            fontSize: 16.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        label,
        style: TextStyle(
          color: AppConst.black,
          fontSize: 13.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(icon, color: AppConst.textSecondary, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppConst.textSecondary, fontSize: 13.sp),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppConst.black,
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({required double radius}) {
    return BoxDecoration(
      color: AppConst.cardLight,
      borderRadius: BorderRadius.circular(radius.r),
      boxShadow: [
        BoxShadow(
          color: AppConst.blackWithOpacity(0.07),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

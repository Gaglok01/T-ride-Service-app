import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../consts/appConst.dart';
import '../setting/feedback_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _callSupport() async {
    final uri = Uri(scheme: 'tel', path: '87344');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 110.h),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Support',
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Get help with rides, courier orders, safety, and your account.',
                        style: TextStyle(
                          color: AppConst.textSecondary,
                          fontSize: 13.sp,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: AppConst.primaryColor,
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Icon(Icons.support_agent_rounded, color: AppConst.black, size: 25.sp),
                ),
              ],
            ),
            SizedBox(height: 22.h),
            _heroCard(),
            SizedBox(height: 18.h),
            _sectionTitle('How can we help?'),
            SizedBox(height: 10.h),
            _supportTile(
              icon: Icons.receipt_long_outlined,
              title: 'Trip or order issue',
              subtitle: 'Report a problem with a ride, delivery, or courier request.',
              onTap: () => Get.to(() => const FeedbackScreen()),
            ),
            _supportTile(
              icon: Icons.shield_outlined,
              title: 'Safety support',
              subtitle: 'Get urgent support or review safety tools.',
              onTap: _callSupport,
              isPriority: true,
            ),
            _supportTile(
              icon: Icons.payment_outlined,
              title: 'Payments & wallet',
              subtitle: 'Questions about wallet, cards, cash, or charges.',
              onTap: () => Get.snackbar('Payments', 'Payment support will connect to the backend.'),
            ),
            _supportTile(
              icon: Icons.person_outline_rounded,
              title: 'Account help',
              subtitle: 'Profile, password, phone verification, and login help.',
              onTap: () => Get.snackbar('Account help', 'Account support will connect to the backend.'),
            ),
            SizedBox(height: 16.h),
            _sectionTitle('Popular topics'),
            SizedBox(height: 10.h),
            _topicChip('How to book a ride'),
            _topicChip('How courier tracking works'),
            _topicChip('Cancel a trip'),
            _topicChip('Contact T-Ride support'),
          ],
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppConst.black,
        borderRadius: BorderRadius.circular(26.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: AppConst.primaryColor,
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Icon(Icons.chat_bubble_outline_rounded, color: AppConst.black, size: 25.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need assistance?',
                  style: TextStyle(color: AppConst.white, fontSize: 17.sp, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Send a report or call support for urgent safety help.',
                  style: TextStyle(color: AppConst.white.withValues(alpha: 0.72), fontSize: 12.sp, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(color: AppConst.black, fontSize: 18.sp, fontWeight: FontWeight.w900, letterSpacing: -0.3),
    );
  }

  Widget _supportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isPriority = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: isPriority ? Colors.red.withValues(alpha: 0.10) : AppConst.primaryColor.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(icon, color: isPriority ? Colors.red : AppConst.black, size: 23.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: AppConst.black, fontSize: 14.sp, fontWeight: FontWeight.w900)),
                      SizedBox(height: 3.h),
                      Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppConst.textSecondary, fontSize: 12.sp, height: 1.28)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppConst.textSecondary, size: 24.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topicChip(String text) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFEDEEF2)),
      ),
      child: Row(
        children: [
          Icon(Icons.help_outline_rounded, color: AppConst.black, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(child: Text(text, style: TextStyle(color: AppConst.black, fontSize: 13.sp, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_ride_rider_app/widgets/custom_appbar.dart';
import '../../../consts/appConst.dart';
import '../checkout_success/rental_checkout_success_view.dart';

class DocumentUploadView extends StatefulWidget {
  const DocumentUploadView({super.key});

  @override
  State<DocumentUploadView> createState() => _DocumentUploadViewState();
}

class _DocumentUploadViewState extends State<DocumentUploadView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          // Top Header
          CustomAppBar(title: 'appbar.document_upload'.tr),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instructional Text
                  Text(
                    'Upload your personal document',
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  // CNIC/ID Upload Card
                  _buildDocumentCard(
                    icon: Icons.credit_card,
                    title: 'rental.doc_cnic'.tr,
                    onTap: () {
                      // TODO: Handle CNIC/ID upload
                    },
                  ),
                  SizedBox(height: 16.h),
                  // Proof of Income Card
                  _buildDocumentCard(
                    icon: Icons.receipt_long,
                    title: 'rental.doc_income'.tr,
                    onTap: () {
                      // TODO: Handle proof of income upload
                    },
                  ),
                  SizedBox(height: 16.h),
                  // Selfie Verification Card
                  _buildDocumentCard(
                    icon: Icons.person,
                    title: 'rental.doc_selfie'.tr,
                    onTap: () {
                      // TODO: Handle selfie verification
                    },
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
          // Book Now Button
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppConst.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: AppConst.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () {
                Get.to(() => const RentalCheckoutSuccessView());
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: AppConst.black,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    'Book now',
                    style: TextStyle(
                      color: AppConst.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppConst.cardLight,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            // Document Icon
            Icon(
              icon,
              color: AppConst.black,
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppConst.black,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Camera Icon
            Icon(
              Icons.camera_alt,
              color: AppConst.black,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }
}


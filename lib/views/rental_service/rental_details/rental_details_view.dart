import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:t_ride_rider_app/widgets/custom_appbar.dart';
import '../../../consts/appConst.dart';
import '../rental_information/rental_information_view.dart';
import '../apartment_house_information/apartment_house_information_view.dart';
import '../../../core/config/api_urls.dart';
import '../../../data/models/rental_item_details_model.dart';

class RentalDetailsView extends StatefulWidget {
  final String rentalType; // 'Car Rental', 'Apartment Rental', 'House Rentals'
  final Data item;

  const RentalDetailsView({
    super.key,
    required this.item,
    this.rentalType = 'Car Rental',
  });

  @override
  State<RentalDetailsView> createState() => _RentalDetailsViewState();
}

class _RentalDetailsViewState extends State<RentalDetailsView> {
  int _currentImageIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String? _resolveImageUrl(String? image) {
    if (image == null) return null;
    final v = image.trim();
    if (v.isEmpty) return null;
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    final cleaned = v.startsWith('/') ? v.substring(1) : v;
    return '${ApiUrls.baseUrl}$cleaned';
  }

  String _formatPrice() {
    final price = widget.item.price;
    final unit = widget.item.priceUnit;
    if (price == null || unit == null) return 'Price N/A';
    return '\$ $price/$unit';
  }

  Widget _buildImageSlider() {
    final images = widget.item.images ?? [];
    if (images.isEmpty) {
      return Icon(Icons.broken_image, color: AppConst.grey, size: 150.sp);
    }

    final resolvedUrls = images.map(_resolveImageUrl).toList();

    return Stack(
      children: [
        ClipRect(
          child: PageView.builder(
            controller: _pageController,
            itemCount: resolvedUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final url = resolvedUrls[index];
              if (url == null) {
                return Center(
                  child: Icon(
                    Icons.broken_image,
                    color: AppConst.grey,
                    size: 150.sp,
                  ),
                );
              }

              return CachedNetworkImage(
                imageUrl: url,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, _) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, _, __) => Icon(
                  Icons.broken_image,
                  color: AppConst.grey,
                  size: 150.sp,
                ),
              );
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 10.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              resolvedUrls.length,
              (index) => Container(
                width: 8.w,
                height: 8.w,
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentImageIndex
                      ? AppConst.black
                      : AppConst.black.withOpacity(0.25),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDynamicDetails() {
    final rows = <Widget>[];

    if (widget.item.category != null && widget.item.category!.isNotEmpty) {
      rows.add(_buildDetailRow('Type', widget.item.category!));
      rows.add(SizedBox(height: 8.h));
    }

    if (widget.item.location != null && widget.item.location!.isNotEmpty) {
      rows.add(_buildDetailRow('Location', widget.item.location!));
      rows.add(SizedBox(height: 8.h));
    }

    final features = widget.item.features;
    if (features != null) {
      if (features.safety != null && features.safety!.isNotEmpty) {
        rows.add(_buildDetailRow('Safety', features.safety!));
        rows.add(SizedBox(height: 8.h));
      }

      if (features.sunroof != null) {
        rows.add(_buildDetailRow('Sunroof', features.sunroof! ? 'Yes' : 'No'));
        rows.add(SizedBox(height: 8.h));
      }

      if (features.cruiseControl != null) {
        rows.add(
          _buildDetailRow(
            'Cruise Control',
            features.cruiseControl! ? 'Yes' : 'No',
          ),
        );
        rows.add(SizedBox(height: 8.h));
      }
    }

    // Description fallback
    if (widget.item.description != null &&
        widget.item.description!.isNotEmpty) {
      rows.add(_buildDetailRow('Notes', widget.item.description!));
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          // Top Header
          CustomAppBar(title: widget.item.name ?? 'appbar.rental_details'.tr),
          // Main Content (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Car Image Section
                  Container(
                    height: 300.h,
                    width: double.infinity,
                    decoration: BoxDecoration(color: AppConst.white),
                    child: _buildImageSlider(),
                  ),
                  // Content Section (Yellow Background)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppConst.primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(20.r),
                      ),
                    ),
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Car Name, Price, and Quantity Selector
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.item.name ?? '',
                                    style: TextStyle(
                                      color: AppConst.black,
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      Text(
                                        _formatPrice(),
                                        style: TextStyle(
                                          color: AppConst.black,
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Quantity Selector
                            // Container(
                            //   decoration: BoxDecoration(
                            //     color: AppConst.white,
                            //     borderRadius: BorderRadius.circular(12.r),
                            //   ),
                            //   child: Row(
                            //     children: [
                            //       GestureDetector(
                            //         onTap: () {
                            //           if (_quantity > 1) {
                            //             setState(() {
                            //               _quantity--;
                            //             });
                            //           }
                            //         },
                            //         child: Container(
                            //           padding: EdgeInsets.all(8.w),
                            //           child: Icon(
                            //             Icons.remove,
                            //             color: AppConst.black,
                            //             size: 20.sp,
                            //           ),
                            //         ),
                            //       ),
                            //       Container(
                            //         padding: EdgeInsets.symmetric(
                            //           horizontal: 16.w,
                            //         ),
                            //         child: Text(
                            //           '$_quantity',
                            //           style: TextStyle(
                            //             color: AppConst.black,
                            //             fontSize: 16.sp,
                            //             fontWeight: FontWeight.bold,
                            //           ),
                            //         ),
                            //       ),
                            //       GestureDetector(
                            //         onTap: () {
                            //           setState(() {
                            //             _quantity++;
                            //           });
                            //         },
                            //         child: Container(
                            //           padding: EdgeInsets.all(8.w),
                            //           child: Icon(
                            //             Icons.add,
                            //             color: AppConst.black,
                            //             size: 20.sp,
                            //           ),
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        // Description
                        Text(
                          widget.item.description ?? '',
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 14.sp,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        // Details Section
                        Text(
                          'Details',
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        ..._buildDynamicDetails(),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom Action Buttons
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(
                  builder: (context) {
                    final available = (widget.item.status ?? '')
                        .toLowerCase()
                        .trim()
                        .contains('available');

                    if (!available) {
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        decoration: BoxDecoration(
                          color: AppConst.grey.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: Text(
                            'Unavailable',
                            style: TextStyle(
                              color: AppConst.black,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }

                    return GestureDetector(
                      onTap: () {
                        if (widget.rentalType == 'Car Rental') {
                          Get.to(
                            () => RentalInformationView(
                              rentableItemId: widget.item.id ?? 0,
                              totalPrice: widget.item.price ?? '0.00',
                            ),
                          );
                        } else if (widget.rentalType == 'Apartment Rental' ||
                            widget.rentalType == 'House Rentals') {
                          Get.to(() => const ApartmentHouseInformationView());
                        }
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
                            'Book',
                            style: TextStyle(
                              color: AppConst.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120.w,
          child: Text(
            '$label:',
            style: TextStyle(
              color: AppConst.black,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: AppConst.black, fontSize: 14.sp),
          ),
        ),
      ],
    );
  }
}

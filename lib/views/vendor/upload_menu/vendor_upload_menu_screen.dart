import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../consts/appConst.dart';

class VendorUploadMenuScreen extends StatefulWidget {
  const VendorUploadMenuScreen({super.key});

  @override
  State<VendorUploadMenuScreen> createState() => _VendorUploadMenuScreenState();
}

class _VendorUploadMenuScreenState extends State<VendorUploadMenuScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Special offers for you';

  final List<String> _categories = [
    'Special offers for you',
    'Popular',
    'Newly Added',
  ];

  // Sample menu items data
  final List<MenuItem> _menuItems = [
    MenuItem(name: 'Burger Deluxe', price: 12.99, originalPrice: 15.99),
    MenuItem(name: 'Chicken Wings', price: 9.99, originalPrice: 12.99),
    MenuItem(name: 'Pizza Margherita', price: 14.99, originalPrice: 17.99),
    MenuItem(name: 'Caesar Salad', price: 8.99, originalPrice: null),
    MenuItem(name: 'Fish & Chips', price: 11.99, originalPrice: 14.99),
    MenuItem(name: 'Pasta Carbonara', price: 13.99, originalPrice: 16.99),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          // Header with Settings Icon
          Container(
            decoration: BoxDecoration(
              color: AppConst.black,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20.r),
                bottomRight: Radius.circular(20.r),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: SafeArea(
              child: Row(
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
                  GestureDetector(
                    onTap: () {
                      // TODO: Handle settings
                    },
                    child: Icon(
                      Icons.settings,
                      color: AppConst.white,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Profile Picture and Shop Info Section (White Container)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppConst.cardLight,
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(20.r),
                bottomLeft: Radius.circular(20.r),
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 30.h),
            child: Column(
              children: [
                // Profile Picture Placeholder
                Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    color: AppConst.black,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: AppConst.white,
                    size: 40.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                // Shop Name
                Text(
                  'Shop / Business Name',
                  style: TextStyle(
                    color: AppConst.black,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                // Ratings
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: AppConst.primaryColor, size: 16.sp),
                    SizedBox(width: 4.w),
                    Text(
                      'Ratings',
                      style: TextStyle(color: AppConst.black, fontSize: 14.sp),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery Information Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppConst.black,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12.r),
                        bottomLeft: Radius.circular(12.r),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery time',
                              style: TextStyle(
                                color: AppConst.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Delivery offer',
                              style: TextStyle(
                                color: AppConst.white,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 50.w,
                          height: 50.w,
                          decoration: BoxDecoration(
                            color: AppConst.cardLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.local_shipping,
                            color: AppConst.black,
                            size: 24.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Search Bar
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        style: BorderStyle.solid,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: AppConst.grey, size: 20.sp),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search menu',
                              hintStyle: TextStyle(
                                color: AppConst.grey,
                                fontSize: 14.sp,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Category Tabs
                  SizedBox(
                    height: 40.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: 20.w),
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  category,
                                  style: TextStyle(
                                    color: AppConst.black,
                                    fontSize: 14.sp,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    decoration: isSelected
                                        ? TextDecoration.underline
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Item Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 20.h,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      return _buildMenuItemCard(_menuItems[index]);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 120.h,
              decoration: BoxDecoration(
                color: AppConst.cardLight,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12.r),
                  bottomLeft: Radius.circular(12.r),
                ),
              ),
            ),
            Positioned(
              bottom: 8.h,
              right: 8.w,
              child: GestureDetector(
                onTap: () {
                  // TODO: Handle add to cart
                },
                child: Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: AppConst.black,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, color: AppConst.white, size: 20.sp),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          item.name,
          style: TextStyle(
            color: AppConst.black,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Text(
              '\$${item.price.toStringAsFixed(2)}',
              style: TextStyle(
                color: AppConst.black,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (item.originalPrice != null) ...[
              SizedBox(width: 8.w),
              Text(
                '\$${item.originalPrice!.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppConst.grey,
                  fontSize: 12.sp,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class MenuItem {
  final String name;
  final double price;
  final double? originalPrice;

  MenuItem({required this.name, required this.price, this.originalPrice});
}

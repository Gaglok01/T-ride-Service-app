import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/config/api_urls.dart';
import '../../consts/appConst.dart';
import '../../data/local/secure_storage_service.dart';
import '../../data/models/vendor_model.dart';
import '../../data/models/product_details_model.dart' as product_details;
import '../../data/network/api_client.dart';
import '../add_to_cart/add_to_cart_view.dart';
import 'product_details_view.dart';
import '../../widgets/app_snackbar.dart';

class FoodMenuView extends StatefulWidget {
  final String restaurantName;
  final double rating;
  final int reviews;
  final String deliveryTime;
  final String deliveryFee;
  final List<Product>? products;

  const FoodMenuView({
    super.key,
    required this.restaurantName,
    required this.rating,
    required this.reviews,
    required this.deliveryTime,
    required this.deliveryFee,
    this.products,
  });

  @override
  State<FoodMenuView> createState() => _FoodMenuViewState();
}

class _FoodMenuViewState extends State<FoodMenuView> {
  String selectedCategory = 'Special offers for you';
  final Random _random = Random();
  final List<String> _foodImages = [
    'assets/Rectangle 27 (1).png',
    'assets/Rectangle 27 (2).png',
    'assets/Rectangle 28 (4).png',
    'assets/Rectangle 28.png',
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storageService = SecureStorageService();

  Future<product_details.Data?> _fetchProductDetailsData(int productId) async {
    final token = await _storageService.getAuthToken();

    final headers = <String, String>{'Accept': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _apiClient.get(
      '${ApiUrls.foodProduct}/$productId',
      headers: headers,
    );

    final bodyTrim = response.body.trim();
    if (response.statusCode != 200 && response.statusCode != 201) {
      return null;
    }

    if (!(bodyTrim.startsWith('{') || bodyTrim.startsWith('['))) {
      return null;
    }

    final parsed = product_details.ProductDetails.fromJsonString(response.body);
    if (parsed.status != true) return null;
    return parsed.data;
  }

  @override
  void initState() {
    super.initState();
    // No-op: query updates are handled by `onChanged` so we don't need a listener.
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getRandomFoodImage() {
    return _foodImages[_random.nextInt(_foodImages.length)];
  }

  String? _resolveImageUrl(String? path) {
    if (path == null) return null;
    final v = path.trim();
    if (v.isEmpty) return null;
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    final cleaned = v.startsWith('/') ? v.substring(1) : v;
    return '${ApiUrls.baseUrl}$cleaned';
  }

  double _parseMoney(String? value) {
    if (value == null) return 0.0;
    return double.tryParse(value) ?? 0.0;
  }

  Widget _buildFoodItemFromProduct(Product p) {
    final name = p.name ?? 'Food item';
    final original = _parseMoney(p.price);
    final sale = _parseMoney(p.salePrice);

    final price = sale > 0 ? sale : original;
    return _buildFoodItem(
      name: name,
      price: price,
      originalPrice: original,
      imageUrl: p.image,
      productId: p.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiProducts = widget.products ?? const <Product>[];
    final hasApiProducts =
        widget.products != null && widget.products!.isNotEmpty;
    final q = _searchQuery.trim().toLowerCase();

    final visibleProducts = !hasApiProducts
        ? <Product>[]
        : q.isEmpty
        ? apiProducts
        : apiProducts
              .where((p) => (p.name ?? '').toLowerCase().contains(q))
              .toList();

    return Scaffold(
      backgroundColor: AppConst.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header (Black Background with Image)
            Container(
              height: 200.h,
              decoration: BoxDecoration(
                color: AppConst.black,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20.r),
                  bottomRight: Radius.circular(20.r),
                ),
              ),
              child: Stack(
                children: [
                  // Background Image Placeholder
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20.r),
                        bottomRight: Radius.circular(20.r),
                      ),
                      child: Stack(
                        children: [
                          Image.asset(
                            'assets/Frame 72.png',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppConst.black.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Navigation Bar
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: AppConst.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Directionality.of(context) == TextDirection.rtl
                                    ? Icons.arrow_forward
                                    : Icons.arrow_back,
                                color: AppConst.white,
                                size: 20.sp,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // TODO: Handle settings
                            },
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: AppConst.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.settings,
                                color: AppConst.white,
                                size: 20.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Restaurant Info Section
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Name
                  Text(
                    widget.restaurantName,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Rating
                  Row(
                    children: [
                      Icon(Icons.star, color: AppConst.black, size: 20.sp),
                      SizedBox(width: 6.w),
                      Text(
                        '${widget.rating} (${widget.reviews}+)',
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  // Delivery Info Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppConst.black,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delivery ${widget.deliveryTime}',
                                style: TextStyle(
                                  color: AppConst.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '${widget.deliveryFee} delivery or free with \$20.00 spend',
                                style: TextStyle(
                                  color: AppConst.white,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: AppConst.cardLight,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: Icon(Icons.electric_scooter_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Search Bar
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: AppConst.borderRadius,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'food.search_menu'.tr,
                        hintStyle: TextStyle(
                          color: AppConst.grey,
                          fontSize: 14.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppConst.black,
                          size: 20.sp,
                        ),
                        suffixIcon: (_searchQuery.trim().isNotEmpty)
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  size: 18.sp,
                                  color: AppConst.grey,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 10.h,
                          horizontal: 6.w,
                        ),
                      ),
                      style: TextStyle(color: AppConst.black, fontSize: 14.sp),
                    ),
                  ),
                  // SizedBox(height: 20.h),
                  // Menu Categories
                  // SizedBox(
                  //   height: 40.h,
                  //   child: ListView(
                  //     scrollDirection: Axis.horizontal,
                  //     children: [
                  //       _buildCategoryChip('Special offers for you'),
                  //       SizedBox(width: 16.w),
                  //       _buildCategoryChip('Popular'),
                  //       SizedBox(width: 16.w),
                  //       _buildCategoryChip('Newly Added'),
                  //     ],
                  //   ),
                  // ),
                  // SizedBox(height: 20.h),
                  // Food Items Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16.h,
                    crossAxisSpacing: 16.w,
                    childAspectRatio: 0.75,
                    children: hasApiProducts
                        ? (visibleProducts.isNotEmpty)
                              ? visibleProducts
                                    .map((p) => _buildFoodItemFromProduct(p))
                                    .toList()
                              : [_buildNoItemsFoundTile()]
                        : [
                            _buildFoodItem(
                              name: 'Fettuccine Alfredo',
                              price: 7.99,
                              originalPrice: 8.99,
                            ),
                            _buildFoodItem(
                              name: 'Salmon Roll',
                              price: 9.99,
                              originalPrice: 11.99,
                            ),
                            _buildFoodItem(
                              name: 'Grilled Panini',
                              price: 6.99,
                              originalPrice: 8.99,
                            ),
                            _buildFoodItem(
                              name: 'Chicken Wings',
                              price: 10.99,
                              originalPrice: 12.99,
                            ),
                            _buildFoodItem(
                              name: 'Margherita Pizza',
                              price: 8.99,
                              originalPrice: 10.99,
                            ),
                            _buildFoodItem(
                              name: 'Caesar Salad',
                              price: 7.99,
                              originalPrice: 9.99,
                            ),
                          ],
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoItemsFoundTile() {
    return Container(
      decoration: BoxDecoration(
        color: AppConst.cardLight,
        borderRadius: AppConst.borderRadius,
      ),
      child: Center(
        child: Text(
          'No items found',
          style: TextStyle(
            color: AppConst.grey,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppConst.black : AppConst.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? AppConst.white : AppConst.black,
            fontSize: 14.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            decoration: isSelected
                ? TextDecoration.underline
                : TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFoodItem({
    required String name,
    required double price,
    required double originalPrice,
    String? imageUrl,
    int? productId,
  }) {
    return GestureDetector(
      onTap: () async {
        if (productId == null) {
          Get.to(
            () => AddToCartView(
              foodName: name,
              price: price,
              originalPrice: originalPrice,
            ),
          );
          return;
        }

        Get.dialog(
          Center(
            child: CircularProgressIndicator(color: AppConst.primaryColor),
          ),
          barrierDismissible: false,
        );

        try {
          final detailsData = await _fetchProductDetailsData(productId);
          if (!mounted) return;
          if (Get.isDialogOpen == true) Get.back();

          if (detailsData == null) {
            AppSnackBar.error('common.error'.tr, 'food.failed_product'.tr);
            Get.to(
              () => AddToCartView(
                foodName: name,
                price: price,
                originalPrice: originalPrice,
              ),
            );
            return;
          }

          Get.to(() => ProductDetailsView(productData: detailsData));
        } catch (e) {
          if (Get.isDialogOpen == true) Get.back();
          // ignore: avoid_print
          print('FoodMenuView product tap error: $e');
          AppSnackBar.error('common.error'.tr, 'food.failed_product'.tr);
          Get.to(
            () => AddToCartView(
              foodName: name,
              price: price,
              originalPrice: originalPrice,
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          // color: AppConst.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Image
            Expanded(
              flex: 4,
              child: Container(
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
                        child: (() {
                          final resolved = _resolveImageUrl(imageUrl);
                          if (resolved == null) {
                            return Image.asset(
                              _getRandomFoodImage(),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            );
                          }

                          return CachedNetworkImage(
                            imageUrl: resolved,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, _) => Container(
                              color: AppConst.grey.withOpacity(0.2),
                              child: Center(
                                child: SizedBox(
                                  width: 24.w,
                                  height: 24.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppConst.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, _, __) => Container(
                              color: AppConst.grey.withOpacity(0.2),
                              child: Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: AppConst.grey,
                                  size: 44.sp,
                                ),
                              ),
                            ),
                          );
                        })(),
                      ),
                    ),
                    // Add Button
                    Positioned(
                      bottom: 8.h,
                      right: 8.w,
                      child: GestureDetector(
                        onTap: () {
                          Get.to(
                            () => AddToCartView(
                              foodName: name,
                              price: price,
                              originalPrice: originalPrice,
                            ),
                          );
                        },
                        child: Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            color: AppConst.black,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: AppConst.white,
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Food Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: AppConst.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      // Keep within the grid cell height to avoid bottom overflow.
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '\$${originalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppConst.grey,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

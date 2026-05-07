import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../consts/appConst.dart';
import '../../core/config/api_urls.dart';
import '../../data/local/secure_storage_service.dart';
import '../../data/models/food_placed_order_model.dart';
import '../../data/models/product_details_model.dart';
import '../../data/network/api_client.dart';
import '../../data/repositories/profile_repository.dart';
import '../../widgets/app_snackbar.dart';
import 'food_order_placed_view.dart';

/// Same key as [SelectLocationScreen] for Places autocomplete.
const String _kGoogleMapsApiKeyForPlaces =
    'AIzaSyDuAloVADiL2L-pa1Dg7OIkjPLl-lAE6eA';

num _couponToNum(dynamic value, {required num fallback}) {
  if (value is num) return value;
  return num.tryParse('$value') ?? fallback;
}

/// Parses `api/app/coupon/apply` JSON (nested `data` or flat `final_fare`, etc.).
num _extractCouponDiscountedFare(
  Map<String, dynamic> decoded,
  num originalFare,
) {
  num? fromFareMap(Map<String, dynamic> m) {
    if (m['discounted_fare'] != null) {
      return _couponToNum(m['discounted_fare'], fallback: originalFare);
    }
    if (m['final_fare'] != null) {
      return _couponToNum(m['final_fare'], fallback: originalFare);
    }
    if (m['fare'] != null) {
      return _couponToNum(m['fare'], fallback: originalFare);
    }
    if (m['discount_amount'] != null) {
      final discount = _couponToNum(m['discount_amount'], fallback: 0);
      return (originalFare - discount).clamp(0, originalFare);
    }
    if (m['discount'] != null) {
      final discount = _couponToNum(m['discount'], fallback: 0);
      return (originalFare - discount).clamp(0, originalFare);
    }
    return null;
  }

  final rawData = decoded['data'];
  if (rawData is Map) {
    final dataMap = Map<String, dynamic>.from(rawData);
    final fromData = fromFareMap(dataMap);
    if (fromData != null) return fromData;
  }

  final fromRoot = fromFareMap(decoded);
  if (fromRoot != null) return fromRoot;

  return originalFare;
}

class ProductDetailsView extends StatefulWidget {
  final Data productData;

  const ProductDetailsView({super.key, required this.productData});

  @override
  State<ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends State<ProductDetailsView> {
  static const double _softDrinkPrice = 2.05;
  static const double _defaultLat = 24.8607;
  static const double _defaultLng = 67.0011;
  bool _isSoftDrinkSelected = false;
  bool _isOpeningPlaceOrder = false;
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();
  bool _isApplyingCoupon = false;

  /// `final_fare` from coupon API for current line subtotal (qty 1 on this screen).
  double? _couponLineFinal;
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storageService = SecureStorageService();
  final ProfileRepository _profileRepository = ProfileRepository();

  @override
  void dispose() {
    _instructionsController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  double _lineSubtotal(double effectivePrice) {
    return effectivePrice + (_isSoftDrinkSelected ? _softDrinkPrice : 0.0);
  }

  Future<void> _applyProductCoupon(double effectivePrice) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      AppSnackBar.error('food.coupon'.tr, 'Enter a coupon code.');
      return;
    }
    final subtotal = _lineSubtotal(effectivePrice);
    if (subtotal <= 0) return;

    setState(() => _isApplyingCoupon = true);
    try {
      final token = await _storageService.getAuthToken();
      final uri = Uri.parse('${ApiUrls.baseUrl}${ApiUrls.couponApply}');
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
      final body = jsonEncode({'coupon_code': code, 'fare': subtotal});

      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 12));

      Map<String, dynamic>? decoded;
      final bodyTrim = response.body.trim();
      if (bodyTrim.startsWith('{')) {
        try {
          decoded = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        final msg = decoded?['message']?.toString();
        AppSnackBar.error(
          'food.coupon'.tr,
          (msg != null && msg.isNotEmpty)
              ? msg
              : 'Failed to apply coupon (${response.statusCode}).',
        );
        return;
      }

      final status = decoded?['status'];
      final ok =
          status == true || status == 1 || status == '1' || status == 'true';
      if (!ok || decoded == null) {
        final msg = decoded?['message']?.toString();
        AppSnackBar.error(
          'food.coupon'.tr,
          (msg != null && msg.isNotEmpty) ? msg : 'Invalid coupon code.',
        );
        return;
      }

      final discounted = _extractCouponDiscountedFare(decoded, subtotal);
      if (!mounted) return;
      setState(() {
        _couponLineFinal = discounted.toDouble();
      });
      final msg = decoded['message']?.toString();
      AppSnackBar.success(
        'food.coupon'.tr,
        (msg != null && msg.isNotEmpty) ? msg : 'Coupon applied.',
      );
    } on TimeoutException {
      AppSnackBar.error('food.coupon'.tr, 'Request timed out. Try again.');
    } catch (e) {
      // ignore: avoid_print
      print('ProductDetailsView _applyProductCoupon: $e');
      AppSnackBar.error('food.coupon'.tr, 'Could not apply coupon right now.');
    } finally {
      if (mounted) setState(() => _isApplyingCoupon = false);
    }
  }

  double _parseMoney(String? value) {
    if (value == null) return 0.0;
    return double.tryParse(value) ?? 0.0;
  }

  String? _resolveProductImageUrl(String? path) {
    if (path == null) return null;
    final v = path.trim();
    if (v.isEmpty) return null;
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    final cleaned = v.startsWith('/') ? v.substring(1) : v;
    return '${ApiUrls.baseUrl}$cleaned';
  }

  Future<void> _openPlaceOrderDialog({
    required String productName,
    required int productId,
    required int vendorId,
    required double effectivePrice,
    double? lineTotalAfterCoupon,
    String? couponCode,
  }) async {
    String contactPhone = '';
    String deliveryAddress = '';

    try {
      final profile = await _profileRepository.getProfile();
      contactPhone = profile.phoneNumber ?? profile.whatsappNumber ?? '';
      final addr = profile.address?.trim() ?? '';
      final city = profile.city?.trim() ?? '';
      deliveryAddress = [addr, city]
          .where((e) => e.isNotEmpty)
          .join(addr.isNotEmpty && city.isNotEmpty ? ', ' : '');
    } catch (e, st) {
      // ignore: avoid_print
      print('[PlaceOrder] getProfile failed: $e\n$st');
    }

    if (!mounted) return;

    double deliveryLat = _defaultLat;
    double deliveryLng = _defaultLng;

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition();
        deliveryLat = pos.latitude;
        deliveryLng = pos.longitude;
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('[PlaceOrder] getCurrentPosition failed: $e\n$st');
    }

    if (!mounted) return;

    if (mounted) setState(() => _isOpeningPlaceOrder = false);

    final placedOrder = await showDialog<FoodPlacedOrderModel?>(
      context: context,
      builder: (context) => _PlaceOrderMapDialog(
        productName: productName,
        productId: productId,
        vendorId: vendorId,
        effectivePrice: effectivePrice,
        lineTotalAfterCoupon: lineTotalAfterCoupon,
        couponCode: couponCode,
        initialPhone: contactPhone,
        initialAddress: deliveryAddress,
        initialLat: deliveryLat,
        initialLng: deliveryLng,
        initialInstructions: _instructionsController.text,
        apiClient: _apiClient,
        storageService: _storageService,
        parentMounted: () => mounted,
      ),
    );

    if (!mounted || placedOrder == null) return;
    Get.to(() => FoodOrderPlacedView(order: placedOrder));
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.productData.name ?? 'Product';
    final desc = widget.productData.description ?? '';
    final vendorName = widget.productData.vendor?.name;
    final vendorAddress = widget.productData.vendor?.address;

    final price = _parseMoney(widget.productData.price);
    final salePrice = _parseMoney(widget.productData.salePrice);
    final effectivePrice = salePrice > 0 ? salePrice : price;
    final total =
        effectivePrice + (_isSoftDrinkSelected ? _softDrinkPrice : 0.0);
    final displayTotal = _couponLineFinal ?? total;

    final imageUrl = _resolveProductImageUrl(widget.productData.image);

    return Scaffold(
      backgroundColor: AppConst.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                height: 220.h,
                width: double.infinity,
                color: AppConst.black,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20.r),
                          bottomRight: Radius.circular(20.r),
                        ),
                        child: imageUrl == null
                            ? Image.asset(
                                'assets/Frame 72.png',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, _) => Container(
                                  color: AppConst.grey.withValues(alpha: 0.2),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, _, __) => Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 50.sp,
                                    color: AppConst.grey,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 12.h,
                      left: 12.w,
                      child: GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppConst.white.withValues(alpha: 0.2),
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
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: AppConst.black,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (vendorName != null && vendorName.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text(
                        vendorName,
                        style: TextStyle(
                          color: AppConst.grey,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (vendorAddress != null && vendorAddress.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        vendorAddress,
                        style: TextStyle(color: AppConst.grey, fontSize: 12.sp),
                      ),
                    ],
                    SizedBox(height: 12.h),
                    if (desc.isNotEmpty)
                      Text(
                        desc,
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 13.sp,
                          height: 1.4,
                        ),
                      ),
                    SizedBox(height: 16.h),

                    // Price
                    Row(
                      children: [
                        Text(
                          '\$${effectivePrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        if (salePrice > 0 && price > 0)
                          Text(
                            '\$${price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: AppConst.grey,
                              fontSize: 13.sp,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: 28.h),

                    // Frequently bought together
                    // Text(
                    //   'Frequently bought together',
                    //   style: TextStyle(
                    //     color: AppConst.black,
                    //     fontSize: 15.sp,
                    //     fontWeight: FontWeight.bold,
                    //   ),
                    // ),
                    // SizedBox(height: 4.h),
                    // Text(
                    //   'Other customers also ordered these',
                    //   style: TextStyle(color: AppConst.black, fontSize: 10.sp),
                    // ),
                    // SizedBox(height: 12.h),

                    // Row(
                    //   children: [
                    //     Container(
                    //       width: 70.w,
                    //       height: 70.w,
                    //       decoration: BoxDecoration(
                    //         color: AppConst.grey.withValues(alpha: 0.2),
                    //         borderRadius: AppConst.borderRadius,
                    //       ),
                    //       child: ClipRRect(
                    //         borderRadius: AppConst.borderRadius,
                    //         child: Image.asset(
                    //           'assets/cold-drink-hacks-to-know.jpg',
                    //           fit: BoxFit.cover,
                    //         ),
                    //       ),
                    //     ),
                    //     SizedBox(width: 12.w),
                    //     Expanded(
                    //       child: Text(
                    //         'Soft drink',
                    //         style: TextStyle(
                    //           color: AppConst.black,
                    //           fontSize: 14.sp,
                    //           fontWeight: FontWeight.w500,
                    //         ),
                    //       ),
                    //     ),
                    //     Text(
                    //       '+ \$${_softDrinkPrice.toStringAsFixed(2)}',
                    //       style: TextStyle(
                    //         color: AppConst.black,
                    //         fontSize: 14.sp,
                    //         fontWeight: FontWeight.bold,
                    //       ),
                    //     ),
                    //     SizedBox(width: 12.w),
                    //     GestureDetector(
                    //       onTap: () {
                    //         setState(() {
                    //           _isSoftDrinkSelected = !_isSoftDrinkSelected;
                    //         });
                    //       },
                    //       child: Container(
                    //         width: 24.w,
                    //         height: 24.w,
                    //         decoration: BoxDecoration(
                    //           color: _isSoftDrinkSelected
                    //               ? AppConst.black
                    //               : AppConst.transparent,
                    //           borderRadius: BorderRadius.circular(6.r),
                    //           border: Border.all(
                    //             color: AppConst.black,
                    //             width: 1.5,
                    //           ),
                    //         ),
                    //         child: _isSoftDrinkSelected
                    //             ? Icon(
                    //                 Icons.check,
                    //                 color: AppConst.white,
                    //                 size: 16.sp,
                    //               )
                    //             : null,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // SizedBox(height: 28.h),

                    // Special instructions
                    Text(
                      'Special instructions',
                      style: TextStyle(
                        color: AppConst.black,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Kindly let us know if you are allergic to anything or if we need to avoid anything',
                      style: TextStyle(color: AppConst.black, fontSize: 10.sp),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      decoration: BoxDecoration(
                        color: AppConst.transparent,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppConst.white, width: 1),
                      ),
                      child: Stack(
                        children: [
                          TextField(
                            controller: _instructionsController,
                            maxLines: 4,
                            maxLength: 500,
                            decoration: InputDecoration(
                              hintText: 'e.g. no mayo',
                              hintStyle: TextStyle(
                                color: AppConst.black,
                                fontSize: 14.sp,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16.w),
                              counterText: '',
                            ),
                            style: TextStyle(
                              color: AppConst.black,
                              fontSize: 14.sp,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          Positioned(
                            bottom: 8.h,
                            right: 12.w,
                            child: Text(
                              '${_instructionsController.text.length}/500',
                              style: TextStyle(
                                color: AppConst.black,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),

                    Text(
                      'Coupon code',
                      style: TextStyle(
                        color: AppConst.black,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _couponController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'food.enter_promo'.tr,
                              hintStyle: TextStyle(
                                color: AppConst.grey,
                                fontSize: 14.sp,
                              ),
                              filled: true,
                              fillColor: AppConst.cardLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 12.h,
                              ),
                              prefixIcon: Icon(
                                Icons.local_offer_outlined,
                                color: AppConst.grey,
                                size: 22.sp,
                              ),
                            ),
                            style: TextStyle(
                              color: AppConst.black,
                              fontSize: 14.sp,
                            ),
                            onChanged: (_) {
                              if (_couponLineFinal != null) {
                                setState(() => _couponLineFinal = null);
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 10.w),
                        SizedBox(
                          height: 48.h,
                          child: ElevatedButton(
                            onPressed: _isApplyingCoupon
                                ? null
                                : () => _applyProductCoupon(effectivePrice),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConst.black,
                              foregroundColor: AppConst.white,
                              padding: EdgeInsets.symmetric(horizontal: 18.w),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: _isApplyingCoupon
                                ? SizedBox(
                                    width: 20.w,
                                    height: 20.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Apply',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    if (_couponLineFinal != null) ...[
                      SizedBox(height: 8.h),
                      Text(
                        'Discount applied • New total: \$${displayTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    SizedBox(height: 20.h),

                    // Place order
                    GestureDetector(
                      onTap: _isOpeningPlaceOrder
                          ? null
                          : () async {
                              final productId = widget.productData.id;
                              final vendorId = widget.productData.vendorId;
                              if (productId == null || vendorId == null) {
                                AppSnackBar.error(
                                  'common.error'.tr,
                                  'Missing product/vendor id for order.',
                                );
                                return;
                              }
                              setState(() => _isOpeningPlaceOrder = true);
                              try {
                                await _openPlaceOrderDialog(
                                  productName: name,
                                  productId: productId,
                                  vendorId: vendorId,
                                  effectivePrice: effectivePrice,
                                  lineTotalAfterCoupon: _couponLineFinal,
                                  couponCode: _couponLineFinal != null
                                      ? _couponController.text.trim()
                                      : null,
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isOpeningPlaceOrder = false);
                                }
                              }
                            },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: 14.h,
                          horizontal: 16.w,
                        ),
                        decoration: BoxDecoration(
                          color: AppConst.primaryColor,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppConst.black),
                        ),
                        child: Center(
                          child: _isOpeningPlaceOrder
                              ? SizedBox(
                                  height: 22.h,
                                  width: 22.h,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppConst.black,
                                  ),
                                )
                              : Text(
                                  'Place order (\$${displayTotal.toStringAsFixed(2)})',
                                  style: TextStyle(
                                    color: AppConst.black,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceSuggestion {
  const _PlaceSuggestion({required this.description, required this.placeId});

  final String description;
  final String placeId;
}

/// e.g. `{"status":false,"message":"Minimum order amount is 1000.00"}`.
String? _parseFoodOrderErrorMessage(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
  } catch (_) {}
  return null;
}

class _PlaceOrderMapDialog extends StatefulWidget {
  const _PlaceOrderMapDialog({
    required this.productName,
    required this.productId,
    required this.vendorId,
    required this.effectivePrice,
    this.lineTotalAfterCoupon,
    this.couponCode,
    required this.initialPhone,
    required this.initialAddress,
    required this.initialLat,
    required this.initialLng,
    required this.initialInstructions,
    required this.apiClient,
    required this.storageService,
    required this.parentMounted,
  });

  final String productName;
  final int productId;
  final int vendorId;
  final double effectivePrice;

  /// Per-unit line total after coupon (same basis as [effectivePrice] × qty when null).
  final double? lineTotalAfterCoupon;
  final String? couponCode;
  final String initialPhone;
  final String initialAddress;
  final double initialLat;
  final double initialLng;
  final String initialInstructions;
  final ApiClient apiClient;
  final SecureStorageService storageService;
  final bool Function() parentMounted;

  @override
  State<_PlaceOrderMapDialog> createState() => _PlaceOrderMapDialogState();
}

class _PlaceOrderMapDialogState extends State<_PlaceOrderMapDialog> {
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _searchController;
  late final TextEditingController _deliveryInstructionsController;
  late final TextEditingController _itemInstructionsController;

  GoogleMapController? _mapController;
  Timer? _searchDebounce;
  List<_PlaceSuggestion> _searchSuggestions = [];

  int _quantity = 1;
  String _paymentMethod = 'Cash';
  bool _isSubmitting = false;
  late double _deliveryLat;
  late double _deliveryLng;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone);
    _addressController = TextEditingController(text: widget.initialAddress);
    _searchController = TextEditingController();
    _deliveryInstructionsController = TextEditingController(
      text: widget.initialInstructions,
    );
    _itemInstructionsController = TextEditingController(
      text: widget.initialInstructions,
    );
    _deliveryLat = widget.initialLat;
    _deliveryLng = widget.initialLng;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _phoneController.dispose();
    _addressController.dispose();
    _searchController.dispose();
    _deliveryInstructionsController.dispose();
    _itemInstructionsController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _fetchSearchSuggestions(value);
    });
  }

  Future<void> _fetchSearchSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) {
      if (mounted) setState(() => _searchSuggestions = []);
      return;
    }

    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(trimmed)}'
        '&key=$_kGoogleMapsApiKeyForPlaces',
      );

      final response = await http.get(uri);
      if (response.statusCode != 200 && response.statusCode != 201) {
        // ignore: avoid_print
        print(
          '[PlaceOrder] Places autocomplete HTTP ${response.statusCode}: '
          '${response.body}',
        );
        return;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['status'] != 'OK') {
        // ignore: avoid_print
        print(
          '[PlaceOrder] Places autocomplete status=${decoded['status']} '
          'error_message=${decoded['error_message']} body=${response.body}',
        );
        return;
      }

      final preds = decoded['predictions'] as List<dynamic>? ?? [];
      final suggestions = preds
          .whereType<Map<String, dynamic>>()
          .map(
            (p) => _PlaceSuggestion(
              description: p['description'] as String? ?? '',
              placeId: p['place_id'] as String? ?? '',
            ),
          )
          .where((s) => s.description.isNotEmpty && s.placeId.isNotEmpty)
          .toList();

      if (mounted) setState(() => _searchSuggestions = suggestions);
    } catch (e, st) {
      // ignore: avoid_print
      print('[PlaceOrder] _fetchSearchSuggestions: $e\n$st');
    }
  }

  Future<void> _animateTo(double lat, double lng) async {
    final controller = _mapController;
    if (controller == null) {
      // ignore: avoid_print
      print(
        '[PlaceOrder] _animateTo: map controller not ready '
        '(lat=$lat lng=$lng)',
      );
      return;
    }
    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 15),
        ),
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('[PlaceOrder] _animateTo failed: $e\n$st');
    }
  }

  Future<void> _updateAddressFromLatLng(double lat, double lng) async {
    setState(() {
      _deliveryLat = lat;
      _deliveryLng = lng;
    });
    await _animateTo(lat, lng);
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final street = p.street?.trim();
        final locality = p.locality?.trim();
        final parts = <String>[
          if (street != null && street.isNotEmpty) street,
          if (locality != null && locality.isNotEmpty) locality,
        ];
        _addressController.text = parts.isNotEmpty
            ? parts.join(', ')
            : '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      } else {
        _addressController.text =
            '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('[PlaceOrder] placemarkFromCoordinates failed: $e\n$st');
      _addressController.text =
          '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
    if (mounted) setState(() {});
  }

  Future<void> _resolveQueryToMap(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    try {
      final locations = await locationFromAddress(trimmed);
      if (locations.isEmpty) {
        // ignore: avoid_print
        print('[PlaceOrder] locationFromAddress: no results for "$trimmed"');
        AppSnackBar.error('common.error'.tr, 'Address not found.');
        return;
      }
      final first = locations.first;
      await _updateAddressFromLatLng(first.latitude, first.longitude);
      if (mounted) setState(() => _searchSuggestions = []);
    } catch (e, st) {
      // ignore: avoid_print
      print('[PlaceOrder] _resolveQueryToMap failed for "$trimmed": $e\n$st');
      AppSnackBar.error('common.error'.tr, 'Address not found.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.lineTotalAfterCoupon != null
        ? widget.lineTotalAfterCoupon! * _quantity
        : widget.effectivePrice * _quantity;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
      backgroundColor: AppConst.background,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 780.h),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'food.place_order'.tr,
                  style: TextStyle(
                    color: AppConst.black,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(widget.productName, style: TextStyle(fontSize: 14.sp)),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Text('common.qty'.tr, style: TextStyle(fontSize: 13.sp)),
                    SizedBox(width: 8.w),
                    IconButton(
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$_quantity', style: TextStyle(fontSize: 14.sp)),
                    IconButton(
                      onPressed: () => setState(() => _quantity++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    const Spacer(),
                    Text(
                      'Total: \$${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact phone',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8.h),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  items: [
                    DropdownMenuItem(value: 'Cash', child: Text('payment.cash'.tr)),
                    DropdownMenuItem(value: 'Card', child: Text('payment.card'.tr)),
                    DropdownMenuItem(value: 'Wallet', child: Text('payment.wallet'.tr)),
                  ],
                  onChanged: (v) => setState(() {
                    _paymentMethod = v ?? 'Cash';
                  }),
                  decoration: const InputDecoration(
                    labelText: 'Payment method',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search address on map',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchSuggestions = []);
                            },
                            icon: const Icon(Icons.close),
                          ),
                        IconButton(
                          onPressed: () async {
                            await _resolveQueryToMap(_searchController.text);
                          },
                          icon: const Icon(Icons.arrow_forward),
                        ),
                      ],
                    ),
                  ),
                  onSubmitted: (_) async {
                    await _resolveQueryToMap(_searchController.text);
                  },
                ),
                if (_searchSuggestions.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Container(
                    constraints: BoxConstraints(maxHeight: 160.h),
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      border: Border.all(
                        color: AppConst.grey.withValues(alpha: 0.35),
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      itemCount: _searchSuggestions.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: AppConst.grey.withValues(alpha: 0.2),
                      ),
                      itemBuilder: (context, index) {
                        final suggestion = _searchSuggestions[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.location_on,
                            color: AppConst.black,
                            size: 20.sp,
                          ),
                          title: Text(
                            suggestion.description,
                            style: TextStyle(
                              color: AppConst.black,
                              fontSize: 13.sp,
                            ),
                          ),
                          onTap: () async {
                            _searchController.text = suggestion.description;
                            setState(() => _searchSuggestions = []);
                            await _resolveQueryToMap(suggestion.description);
                          },
                        );
                      },
                    ),
                  ),
                ],
                SizedBox(height: 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: SizedBox(
                    height: 180.h,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_deliveryLat, _deliveryLng),
                        zoom: 14,
                      ),
                      onMapCreated: (c) => _mapController = c,
                      markers: {
                        Marker(
                          markerId: const MarkerId('delivery'),
                          position: LatLng(_deliveryLat, _deliveryLng),
                        ),
                      },
                      onTap: (pos) async {
                        await _updateAddressFromLatLng(
                          pos.latitude,
                          pos.longitude,
                        );
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Delivery address',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: _deliveryInstructionsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Delivery instructions',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: _itemInstructionsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Item special instructions',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text('common.cancel'.tr),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                final phone = _phoneController.text.trim();
                                final address = _addressController.text.trim();
                                if (phone.isEmpty || address.isEmpty) {
                                  // ignore: avoid_print
                                  print(
                                    '[PlaceOrder] submit blocked: '
                                    'missing phone=${phone.isEmpty} '
                                    'missing address=${address.isEmpty}',
                                  );
                                  AppSnackBar.error(
                                    'common.error'.tr,
                                    'Phone and address are required.',
                                  );
                                  return;
                                }
                                setState(() => _isSubmitting = true);
                                try {
                                  final token = await widget.storageService
                                      .getAuthToken();
                                  if (token == null || token.isEmpty) {
                                    // ignore: avoid_print
                                    print(
                                      '[PlaceOrder] submit: no auth token — '
                                      'API may return 401',
                                    );
                                  }
                                  final headers = <String, String>{
                                    'Accept': 'application/json',
                                    if (token != null && token.isNotEmpty)
                                      'Authorization': 'Bearer $token',
                                  };
                                  final coupon = widget.couponCode?.trim();
                                  final payload = <String, dynamic>{
                                    'vendor_id': widget.vendorId,
                                    'delivery_address': address,
                                    'delivery_lat': _deliveryLat,
                                    'delivery_lng': _deliveryLng,
                                    'contact_phone': phone,
                                    'payment_method': _paymentMethod,
                                    'delivery_instructions':
                                        _deliveryInstructionsController.text
                                            .trim(),
                                    'items': [
                                      {
                                        'product_id': widget.productId,
                                        'quantity': _quantity,
                                        'special_instructions':
                                            _itemInstructionsController.text
                                                .trim(),
                                      },
                                    ],
                                  };
                                  if (coupon != null && coupon.isNotEmpty) {
                                    payload['coupon_code'] = coupon;
                                  }

                                  final response = await widget.apiClient.post(
                                    ApiUrls.foodOrderPlace,
                                    headers: headers,
                                    body: payload,
                                  );

                                  if (response.statusCode == 200 ||
                                      response.statusCode == 201) {
                                    final placed =
                                        FoodPlacedOrderModel.tryParseResponseBody(
                                          response.body,
                                        );
                                    if (placed != null) {
                                      if (!context.mounted) return;
                                      Navigator.of(context).pop(placed);
                                    } else {
                                      // ignore: avoid_print
                                      print(
                                        '[PlaceOrder] success HTTP but invalid '
                                        'body: ${response.body}',
                                      );
                                      final serverMessage =
                                          _parseFoodOrderErrorMessage(
                                            response.body,
                                          );
                                      AppSnackBar.error(
                                        'common.error'.tr,
                                        serverMessage ??
                                            'Could not read order confirmation.',
                                      );
                                    }
                                  } else {
                                    // ignore: avoid_print
                                    print(
                                      '[PlaceOrder] place order failed: '
                                      'status=${response.statusCode} '
                                      'body=${response.body}',
                                    );
                                    final serverMessage =
                                        _parseFoodOrderErrorMessage(
                                          response.body,
                                        );
                                    AppSnackBar.error(
                                      'common.error'.tr,
                                      serverMessage ??
                                          'Failed to place order '
                                              '(${response.statusCode}).',
                                    );
                                  }
                                } catch (e, st) {
                                  // ignore: avoid_print
                                  print(
                                    '[PlaceOrder] place order exception: $e\n$st',
                                  );
                                  AppSnackBar.error(
                                    'common.error'.tr,
                                    'Something went wrong while placing order.',
                                  );
                                } finally {
                                  if (widget.parentMounted()) {
                                    setState(() => _isSubmitting = false);
                                  }
                                }
                              },
                        child: _isSubmitting
                            ? SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('food.place_order'.tr),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

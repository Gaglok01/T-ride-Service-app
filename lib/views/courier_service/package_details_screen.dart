import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../consts/appConst.dart';
import '../../core/config/api_urls.dart';
import '../../data/firestore/active_courier_firestore_service.dart';
import '../../data/local/secure_storage_service.dart';
import '../../data/models/user_profile_model.dart';
import '../../widgets/app_snackbar.dart';
import '../../data/repositories/profile_repository.dart';
import 'select_courier_screen.dart';
import 'courier_request_details_screen.dart';

class PackageDetailsScreen extends StatefulWidget {
  const PackageDetailsScreen({super.key});

  @override
  State<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends State<PackageDetailsScreen> {
  static const String _googleApiKey = 'AIzaSyDuAloVADiL2L-pa1Dg7OIkjPLl-lAE6eA';

  String? selectedPackageSize;
  String? selectedPaymentMethod = 'cash';

  // Sender / receiver / package fields
  final TextEditingController senderPhoneController = TextEditingController();
  final TextEditingController senderPickupAddressController =
      TextEditingController();
  final TextEditingController receiverNameController = TextEditingController();
  final TextEditingController receiverPhoneController = TextEditingController();
  final TextEditingController receiverDropoffAddressController =
      TextEditingController();
  final TextEditingController packageWeightController = TextEditingController();
  final TextEditingController packagePhotoUrlController =
      TextEditingController();
  final TextEditingController pickupInstructionsController =
      TextEditingController();
  final TextEditingController dropoffInstructionsController =
      TextEditingController();

  final TextEditingController instructionsController = TextEditingController();
  final TextEditingController recipientController = TextEditingController();
  final TextEditingController promoCodeController = TextEditingController();
  bool showFareEstimate = false;
  bool isFindingCourier = false;
  Timer? _timer;

  bool _isLoadingNearbyCouriers = false;
  List<Map<String, dynamic>> _nearbyCouriers = [];
  bool _isRequestingCourier = false;

  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;

  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(24.8607, 67.0011),
    zoom: 12,
  );
  Polyline? _routePolyline;
  bool _isLoadingRoute = false;

  bool _isLoadingFare = false;
  String? _estimatedFareText;

  final SecureStorageService _storageService = SecureStorageService();
  final ProfileRepository _profileRepository = ProfileRepository();
  UserProfile? _senderProfile;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      _pickupLatLng = args['pickup'] as LatLng?;
      _dropoffLatLng = args['destination'] as LatLng?;
      final pickupLabel = args['pickupLabel']?.toString();
      final destinationLabel = args['destinationLabel']?.toString();

      // Pre-fill location fields from SelectLocationScreen.
      if (pickupLabel != null && pickupLabel.trim().isNotEmpty) {
        if (senderPickupAddressController.text.trim().isEmpty) {
          senderPickupAddressController.text = pickupLabel.trim();
        }
      }
      if (destinationLabel != null && destinationLabel.trim().isNotEmpty) {
        if (receiverDropoffAddressController.text.trim().isEmpty) {
          receiverDropoffAddressController.text = destinationLabel.trim();
        }
      }

      // Fetch sender info from profile API.
      _prefillSenderFromProfile();

      if (_pickupLatLng != null) {
        _initialCameraPosition = CameraPosition(
          target: _pickupLatLng!,
          zoom: 14,
        );
      }
      if (_pickupLatLng != null && _dropoffLatLng != null) {
        _fetchRoute();
      }
    }
  }

  Future<void> _prefillSenderFromProfile() async {
    try {
      final profile = await _profileRepository.getProfile();
      if (!mounted) return;

      _senderProfile = profile;

      final phone = profile.phoneNumber?.trim();
      if (phone != null && phone.isNotEmpty) {
        if (senderPhoneController.text.trim().isEmpty) {
          setState(() {
            senderPhoneController.text = phone;
          });
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('PackageDetailsScreen prefillSenderFromProfile error: $e');
    }
  }

  @override
  void dispose() {
    senderPhoneController.dispose();
    senderPickupAddressController.dispose();
    receiverNameController.dispose();
    receiverPhoneController.dispose();
    receiverDropoffAddressController.dispose();
    packageWeightController.dispose();
    packagePhotoUrlController.dispose();
    pickupInstructionsController.dispose();
    dropoffInstructionsController.dispose();
    instructionsController.dispose();
    recipientController.dispose();
    promoCodeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _fetchRoute() async {
    if (_pickupLatLng == null || _dropoffLatLng == null) return;

    setState(() {
      _isLoadingRoute = true;
    });

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${_pickupLatLng!.latitude},${_pickupLatLng!.longitude}'
      '&destination=${_dropoffLatLng!.latitude},${_dropoffLatLng!.longitude}'
      '&mode=driving&key=$_googleApiKey',
    );

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['status'] == 'OK') {
        final routes = data['routes'] as List<dynamic>;
        if (routes.isNotEmpty) {
          final overviewPolyline =
              (routes.first as Map<String, dynamic>)['overview_polyline']
                  as Map<String, dynamic>;
          final encoded = overviewPolyline['points'] as String;
          final points = _decodePolyline(encoded);

          setState(() {
            _routePolyline = Polyline(
              polylineId: const PolylineId('courier_route'),
              points: points,
              width: 4,
              color: Colors.blue,
            );
          });
        }
      } else {
        // ignore: avoid_print
        print(
          'PackageDetailsScreen Directions API error: '
          '${data['status']} - ${data['error_message']}',
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('PackageDetailsScreen _fetchRoute error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    if (_pickupLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }
    if (_dropoffLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: _dropoffLatLng!,
          infoWindow: const InfoWindow(title: 'Dropoff'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.white,
      body: Stack(
        children: [
          Column(
            children: [
              // Top Header (Black Background)
              Container(
                decoration: BoxDecoration(color: AppConst.black),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10.h,
                  bottom: 12.h,
                  left: 20.w,
                  right: 20.w,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_forward
                            : Icons.arrow_back,
                        color: AppConst.white,
                        size: 20.sp,
                      ),
                    ),
                    // Title
                    Text(
                      isFindingCourier
                          ? 'Search Courier'
                          : showFareEstimate
                          ? 'Delivery Fare Estimate'
                          : 'Package Details',
                      style: TextStyle(
                        color: AppConst.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Settings Icon
                    Icon(Icons.settings, color: AppConst.white, size: 20.sp),
                  ],
                ),
              ),
              // Map Section
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: _initialCameraPosition,
                      onMapCreated: (controller) {},
                      markers: _buildMarkers(),
                      polylines: _routePolyline != null
                          ? {_routePolyline!}
                          : const {},
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
                    if (_isLoadingRoute)
                      Center(
                        child: CircularProgressIndicator(color: AppConst.black),
                      ),
                    // Current Location Button (Bottom Right)
                    Positioned(
                      bottom: 20.h,
                      right: 20.w,
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Handle current location
                        },
                        child: Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: AppConst.black,
                            borderRadius: BorderRadius.circular(6.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppConst.blackWithOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.near_me,
                            color: AppConst.white,
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Draggable Bottom Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppConst.primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.r),
                    topRight: Radius.circular(20.r),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag Handle
                    Container(
                      margin: EdgeInsets.only(top: 8.h),
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: AppConst.cardLight,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    Expanded(
                      child: isFindingCourier
                          ? _buildFindingCourierView(scrollController)
                          : showFareEstimate
                          ? _buildFareEstimateView(scrollController)
                          : _buildPackageDetailsView(scrollController),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPackageDetailsView(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 12.h,
        bottom: 16.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Select Package Size Section
          Text(
            'Select package size',
            style: TextStyle(
              color: AppConst.black,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          // Package Size Buttons
          Row(
            children: [
              Expanded(
                child: _buildPackageSizeButton(
                  label: 'Document',
                  icon: Icons.mail_outline,
                  value: 'document',
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _buildPackageSizeButton(
                  label: 'Small',
                  icon: Icons.inbox,
                  value: 'small',
                  sizeLabel: 'S',
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                child: _buildPackageSizeButton(
                  label: 'Medium',
                  icon: Icons.inbox,
                  value: 'medium',
                  sizeLabel: 'M',
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _buildPackageSizeButton(
                  label: 'Large',
                  icon: Icons.inbox,
                  value: 'large',
                  sizeLabel: 'L',
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Sender Info Section (required for courier request)
          Text(
            'Sender details',
            style: TextStyle(
              color: AppConst.black,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppConst.cardLight,
              borderRadius: AppConst.borderRadius,
            ),
            child: TextField(
              controller: senderPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Sender phone (e.g. +923001234567)',
                hintStyle: TextStyle(color: AppConst.grey, fontSize: 12.sp),
                border: InputBorder.none,
              ),
              style: TextStyle(color: AppConst.black, fontSize: 12.sp),
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppConst.cardLight,
              borderRadius: AppConst.borderRadius,
            ),
            child: TextField(
              controller: senderPickupAddressController,
              decoration: InputDecoration(
                hintText: 'Pickup address (e.g. Clifton Block 4, Karachi)',
                hintStyle: TextStyle(color: AppConst.grey, fontSize: 12.sp),
                border: InputBorder.none,
              ),
              style: TextStyle(color: AppConst.black, fontSize: 12.sp),
            ),
          ),
          SizedBox(height: 16.h),
          // Add Instructions & Package Photo Section
          Text(
            'Add Instructions & package photo',
            style: TextStyle(
              color: AppConst.black,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppConst.cardLight,
                    borderRadius: AppConst.borderRadius,
                  ),
                  child: TextField(
                    controller: instructionsController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Handle with care.',
                      hintStyle: TextStyle(
                        color: AppConst.grey,
                        fontSize: 12.sp,
                      ),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(color: AppConst.black, fontSize: 12.sp),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              GestureDetector(
                onTap: () {
                  // TODO: Handle package photo
                },
                child: Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: AppConst.cardLight,
                    borderRadius: AppConst.borderRadius,
                    border: Border.all(
                      color: AppConst.grey.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2,
                        color: AppConst.black,
                        size: 20.sp,
                      ),
                      Positioned(
                        bottom: 3.h,
                        right: 3.w,
                        child: Container(
                          width: 16.w,
                          height: 16.w,
                          decoration: BoxDecoration(
                            color: AppConst.black,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: AppConst.white,
                            size: 8.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Recipient's Detail Section
          Text(
            "Recipient's detail",
            style: TextStyle(
              color: AppConst.black,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppConst.cardLight,
              borderRadius: AppConst.borderRadius,
            ),
            child: TextField(
              controller: receiverNameController,
              decoration: InputDecoration(
                hintText: 'Receiver name (e.g. Ali Khan)',
                hintStyle: TextStyle(color: AppConst.grey, fontSize: 12.sp),
                border: InputBorder.none,
              ),
              style: TextStyle(color: AppConst.black, fontSize: 12.sp),
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppConst.cardLight,
              borderRadius: AppConst.borderRadius,
            ),
            child: TextField(
              controller: receiverPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Receiver phone (e.g. +923007654321)',
                hintStyle: TextStyle(color: AppConst.grey, fontSize: 12.sp),
                border: InputBorder.none,
              ),
              style: TextStyle(color: AppConst.black, fontSize: 12.sp),
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppConst.cardLight,
              borderRadius: AppConst.borderRadius,
            ),
            child: TextField(
              controller: receiverDropoffAddressController,
              decoration: InputDecoration(
                hintText: 'Dropoff address (e.g. Gulshan-e-Iqbal, Karachi)',
                hintStyle: TextStyle(color: AppConst.grey, fontSize: 12.sp),
                border: InputBorder.none,
              ),
              style: TextStyle(color: AppConst.black, fontSize: 12.sp),
            ),
          ),
          SizedBox(height: 16.h),
          // Continue Button
          GestureDetector(
            onTap: () async {
              if (_isLoadingFare) return;

              if (selectedPackageSize == null) {
                AppSnackBar.error(
                  'common.error'.tr,
                  'Please select a package size first.',
                );
                return;
              }

              final success = await _fetchCourierFareEstimate();

              if (success && mounted) {
                setState(() {
                  showFareEstimate = true;
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: _isLoadingFare
                    ? AppConst.accentWithOpacity(0.55)
                    : AppConst.accent,
                borderRadius: AppConst.buttonRadius,
              ),
              child: Center(
                child: _isLoadingFare
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppConst.black,
                        ),
                      )
                    : Text(
                        'common.continue'.tr,
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareEstimateView(ScrollController scrollController) {
    // Get package details based on selection
    String packageName = 'Document';
    String packageWeight = '0-0.5 kg';
    String packageDescription = 'Light envelope, Cheapest category';
    final String fare = _isLoadingFare
        ? 'Calculating...'
        : (_estimatedFareText ?? '\$ 0.00');

    if (selectedPackageSize == 'small') {
      packageName = 'Small';
      packageWeight = '0.5-2 kg';
      packageDescription = 'Small box, Affordable';
    } else if (selectedPackageSize == 'medium') {
      packageName = 'Medium';
      packageWeight = '2-5 kg';
      packageDescription = 'Medium box, Standard';
    } else if (selectedPackageSize == 'large') {
      packageName = 'Large';
      packageWeight = '5-10 kg';
      packageDescription = 'Large box, Premium';
    }

    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 12.h,
        bottom: 16.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Information
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppConst.cardLight,
              borderRadius: AppConst.borderRadius,
            ),
            child: Row(
              children: [
                // Package Icon
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: AppConst.cardLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppConst.grey.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.mail_outline,
                    color: AppConst.black,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                // Package Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        packageName,
                        style: TextStyle(
                          color: AppConst.black,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        packageWeight,
                        style: TextStyle(color: AppConst.grey, fontSize: 11.sp),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        packageDescription,
                        style: TextStyle(color: AppConst.grey, fontSize: 10.sp),
                      ),
                    ],
                  ),
                ),
                // Fare
                Text(
                  fare,
                  style: TextStyle(
                    color: AppConst.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          // Payment Method Selection
          Text(
            'Select payment method',
            style: TextStyle(
              color: AppConst.black,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _buildPaymentMethodButton(
                  icon: Icons.account_balance_wallet,
                  label: 'payment.cash'.tr,
                  value: 'cash',
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildPaymentMethodButton(
                  icon: Icons.account_balance_wallet,
                  label: 'payment.wallet'.tr,
                  value: 'wallet',
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildPaymentMethodButton(
                  icon: Icons.credit_card,
                  label: 'payment.card'.tr,
                  value: 'card',
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Package weight and photo URL (required for request payload)
          Text(
            'Package details',
            style: TextStyle(
              color: AppConst.black,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppConst.cardLight,
              borderRadius: AppConst.borderRadius,
            ),
            child: TextField(
              controller: packageWeightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: 'Package weight in kg (e.g. 2.5)',
                hintStyle: TextStyle(color: AppConst.grey, fontSize: 12.sp),
                border: InputBorder.none,
              ),
              style: TextStyle(color: AppConst.black, fontSize: 12.sp),
            ),
          ),
          SizedBox(height: 8.h),
          // Container(
          //   width: double.infinity,
          //   padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          //   decoration: BoxDecoration(
          //     color: AppConst.white,
          //     borderRadius: AppConst.borderRadius,
          //   ),
          //   child: TextField(
          //     controller: packagePhotoUrlController,
          //     decoration: InputDecoration(
          //       hintText: 'Package photo URL (optional)',
          //       hintStyle: TextStyle(color: AppConst.grey, fontSize: 12.sp),
          //       border: InputBorder.none,
          //     ),
          //     style: TextStyle(color: AppConst.black, fontSize: 12.sp),
          //   ),
          // ),
          // SizedBox(height: 16.h),
          // Pickup / dropoff instructions (more detailed)
          Text(
            'Pickup & dropoff instructions',
            style: TextStyle(
              color: AppConst.black,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppConst.cardLight,
              borderRadius: AppConst.borderRadius,
            ),
            child: TextField(
              controller: pickupInstructionsController,
              decoration: InputDecoration(
                hintText: 'Pickup instructions (e.g. Ring the doorbell)',
                hintStyle: TextStyle(color: AppConst.grey, fontSize: 12.sp),
                border: InputBorder.none,
              ),
              style: TextStyle(color: AppConst.black, fontSize: 12.sp),
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppConst.cardLight,
              borderRadius: AppConst.borderRadius,
            ),
            child: TextField(
              controller: dropoffInstructionsController,
              decoration: InputDecoration(
                hintText: 'Dropoff instructions (e.g. Leave at reception)',
                hintStyle: TextStyle(color: AppConst.grey, fontSize: 12.sp),
                border: InputBorder.none,
              ),
              style: TextStyle(color: AppConst.black, fontSize: 12.sp),
            ),
          ),
          SizedBox(height: 16.h),
          // Confirm Button
          GestureDetector(
            onTap: () async {
              if (_isRequestingCourier) return;

              setState(() {
                _isRequestingCourier = true;
              });

              try {
                final success = await _requestCourier();
                if (success && mounted) {
                  await _navigateToRequestedCourierDetails();
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isRequestingCourier = false;
                  });
                }
              }
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: AppConst.black,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: _isRequestingCourier
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppConst.white,
                        ),
                      )
                    : Text(
                        'Confirm & Request Courier',
                        style: TextStyle(
                          color: AppConst.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFindingCourierView(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 12.h,
        bottom: 16.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          Text(
            'Nearby couriers',
            style: TextStyle(
              color: AppConst.black,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          if (_isLoadingNearbyCouriers)
            Center(child: CircularProgressIndicator(color: AppConst.black))
          else if (_nearbyCouriers.isEmpty)
            Text(
              'No couriers available near your pickup location.',
              style: TextStyle(color: AppConst.black, fontSize: 14.sp),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _nearbyCouriers.length,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                final courier = _nearbyCouriers[index];
                final name = courier['name']?.toString() ?? 'Courier';
                final rating = courier['rating']?.toString() ?? '0.0';
                final eta = courier['eta']?.toString() ?? '';
                final distance = courier['distance']?.toString() ?? '';

                return GestureDetector(
                  onTap: () {
                    Get.to(
                      () => const CourierRequestDetailsScreen(),
                      arguments: {
                        'courier': courier,
                        'pickup_address': senderPickupAddressController.text
                            .trim(),
                        'dropoff_address': receiverDropoffAddressController.text
                            .trim(),
                        'estimated_fare': _estimatedFareText,
                        'payment_method': selectedPaymentMethod,
                        'pickup_lat': _pickupLatLng?.latitude,
                        'pickup_lng': _pickupLatLng?.longitude,
                        'dropoff_lat': _dropoffLatLng?.latitude,
                        'dropoff_lng': _dropoffLatLng?.longitude,
                      },
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: AppConst.borderRadius,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20.r,
                          backgroundColor: AppConst.black,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'C',
                            style: TextStyle(
                              color: AppConst.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  color: AppConst.black,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Rating: $rating',
                                style: TextStyle(
                                  color: AppConst.grey,
                                  fontSize: 12.sp,
                                ),
                              ),
                              if (eta.isNotEmpty || distance.isNotEmpty)
                                SizedBox(height: 2.h),
                              if (eta.isNotEmpty || distance.isNotEmpty)
                                Text(
                                  [
                                    eta,
                                    distance,
                                  ].where((e) => e.isNotEmpty).join(' • '),
                                  style: TextStyle(
                                    color: AppConst.grey,
                                    fontSize: 12.sp,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          SizedBox(height: 24.h),
          // Cancel Courier Button
          GestureDetector(
            onTap: () {
              _stopTimer();
              Get.to(() => const SelectCourierScreen());
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text(
                  'common.cancel'.tr,
                  style: TextStyle(
                    color: AppConst.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodButton({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isSelected = selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: AppConst.cardLight,
          borderRadius: AppConst.borderRadius,
          border: Border.all(
            color: isSelected
                ? AppConst.black
                : AppConst.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppConst.black, size: 20.sp),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                color: AppConst.black,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageSizeButton({
    required String label,
    required IconData icon,
    required String value,
    String? sizeLabel,
  }) {
    final isSelected = selectedPackageSize == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPackageSize = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
        decoration: BoxDecoration(
          color: AppConst.cardLight,
          borderRadius: AppConst.borderRadius,
          border: Border.all(
            color: isSelected
                ? AppConst.black
                : AppConst.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (sizeLabel != null)
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  border: Border.all(color: AppConst.black, width: 2),
                  borderRadius: BorderRadius.circular(3.r),
                ),
                child: Center(
                  child: Text(
                    sizeLabel,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else
              Icon(icon, color: AppConst.black, size: 20.sp),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                color: AppConst.black,
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _requestCourier() async {
    if (_pickupLatLng == null || _dropoffLatLng == null) {
      AppSnackBar.error('common.error'.tr, 'Pickup and dropoff locations are required.');
      return false;
    }

    // Basic validation for required fields
    if (senderPhoneController.text.trim().isEmpty ||
        senderPickupAddressController.text.trim().isEmpty ||
        receiverNameController.text.trim().isEmpty ||
        receiverPhoneController.text.trim().isEmpty ||
        receiverDropoffAddressController.text.trim().isEmpty ||
        packageWeightController.text.trim().isEmpty) {
      AppSnackBar.error('common.error'.tr, 'Please fill all required courier details.');
      return false;
    }

    if (_estimatedFareText == null) {
      AppSnackBar.error(
        'common.error'.tr,
        'Fare estimate is missing. Please go back and recalculate.',
      );
      return false;
    }

    // Parse fare from text like "Rs 250.00"
    num? estimatedFare;
    final fareStr = _estimatedFareText!.replaceAll(RegExp(r'[^0-9.]'), '');
    if (fareStr.isNotEmpty) {
      estimatedFare = num.tryParse(fareStr);
    }

    if (estimatedFare == null) {
      AppSnackBar.error('common.error'.tr, 'Invalid fare amount.');
      return false;
    }

    final packageWeight = num.tryParse(packageWeightController.text.trim());
    if (packageWeight == null) {
      AppSnackBar.error('common.error'.tr, 'Invalid package weight.');
      return false;
    }

    try {
      final token = await _storageService.getAuthToken();
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse('${ApiUrls.baseUrl}${ApiUrls.courierRequest}');

      // API expects capitalized payment methods like "Cash"
      final payment = selectedPaymentMethod ?? 'cash';
      String apiPaymentMethod;
      switch (payment) {
        case 'wallet':
          apiPaymentMethod = 'Wallet';
          break;
        case 'card':
          apiPaymentMethod = 'Card';
          break;
        default:
          apiPaymentMethod = 'Cash';
      }

      final body = jsonEncode({
        'sender_pickup_address': senderPickupAddressController.text.trim(),
        'sender_pickup_lat': _pickupLatLng!.latitude,
        'sender_pickup_lng': _pickupLatLng!.longitude,
        'sender_phone': senderPhoneController.text.trim(),
        'receiver_name': receiverNameController.text.trim(),
        'receiver_phone': receiverPhoneController.text.trim(),
        'receiver_dropoff_address': receiverDropoffAddressController.text
            .trim(),
        'receiver_dropoff_lat': _dropoffLatLng!.latitude,
        'receiver_dropoff_lng': _dropoffLatLng!.longitude,
        'package_size': selectedPackageSize ?? 'medium',
        'package_weight': packageWeight,
        'package_photo': packagePhotoUrlController.text.trim().isEmpty
            ? null
            : packagePhotoUrlController.text.trim(),
        'pickup_instructions': pickupInstructionsController.text.trim(),
        'dropoff_instructions': dropoffInstructionsController.text.trim(),
        'estimated_fare': estimatedFare,
        'payment_method': apiPaymentMethod,
      });

      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        String message = 'Failed to request courier.';
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          if (errorJson['message'] != null) {
            message = errorJson['message'].toString();
          }
        } catch (_) {}

        // ignore: avoid_print
        print(
          'PackageDetailsScreen _requestCourier error: '
          'statusCode=${response.statusCode}, body=${response.body}',
        );

        AppSnackBar.error('common.error'.tr, message);
        return false;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['status'] != true) {
        final message = (decoded['message'] ?? 'Failed to request courier.')
            .toString();

        // ignore: avoid_print
        print('PackageDetailsScreen _requestCourier status false: $decoded');

        AppSnackBar.error('common.error'.tr, message);
        return false;
      }

      try {
        await ActiveCourierFirestoreService().publishCourierRequested(
          apiCourierResponse: decoded,
          rider: _senderProfile,
          senderPickupAddress: senderPickupAddressController.text.trim(),
          senderPickupLat: _pickupLatLng!.latitude,
          senderPickupLng: _pickupLatLng!.longitude,
          receiverName: receiverNameController.text.trim(),
          receiverPhone: receiverPhoneController.text.trim(),
          receiverDropoffAddress: receiverDropoffAddressController.text.trim(),
          receiverDropoffLat: _dropoffLatLng!.latitude,
          receiverDropoffLng: _dropoffLatLng!.longitude,
          senderPhone: senderPhoneController.text.trim(),
          paymentMethod: apiPaymentMethod,
          estimatedFare: estimatedFare,
          packageWeight: packageWeight,
          packageSize: selectedPackageSize ?? 'medium',
          packagePhoto: packagePhotoUrlController.text.trim().isEmpty
              ? null
              : packagePhotoUrlController.text.trim(),
          pickupInstructions: pickupInstructionsController.text.trim(),
          dropoffInstructions: dropoffInstructionsController.text.trim(),
        );
      } catch (e) {
        // ignore: avoid_print
        print('PackageDetailsScreen Firestore active_courier write failed: $e');
      }

      AppSnackBar.success('common.success'.tr, 'Courier request created successfully.');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('PackageDetailsScreen _requestCourier exception: $e');
      AppSnackBar.error(
        'common.error'.tr,
        'Something went wrong while requesting courier.',
      );
      return false;
    }
  }

  Future<Map<String, dynamic>?> _fetchActiveCourier() async {
    final token = await _storageService.getAuthToken();
    if (token == null || token.isEmpty) return null;

    try {
      final uri = Uri.parse('${ApiUrls.baseUrl}${ApiUrls.courierActive}');
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200 && response.statusCode != 201) {
        // Keep this quiet during polling; we handle "not found" after timeout.
        return null;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['status'] != true) return null;

      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) return item;
        }
      }

      return null;
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _navigateToRequestedCourierDetails() async {
    // Temporary loading dialog while we wait for the active courier to appear.
    Get.dialog(
      const Material(
        color: Colors.transparent,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      barrierDismissible: false,
    );

    final start = DateTime.now();
    Map<String, dynamic>? activeCourier;

    while (mounted &&
        DateTime.now().difference(start) < const Duration(seconds: 12)) {
      activeCourier = await _fetchActiveCourier();
      if (activeCourier != null) break;
      await Future.delayed(const Duration(milliseconds: 1200));
    }

    if (Get.isDialogOpen == true) Get.back();

    if (!mounted) return;

    if (activeCourier == null) {
      AppSnackBar.error(
        'common.error'.tr,
        'Unable to load requested courier details. Please try again.',
      );
      return;
    }

    final paymentArg = switch (selectedPaymentMethod?.toLowerCase()) {
      'wallet' => 'Wallet',
      'card' => 'Card',
      _ => 'Cash',
    };

    final courierIdRaw =
        activeCourier['id'] ?? activeCourier['courier_id'] ?? activeCourier['courierId'];
    final courierId = (courierIdRaw as num?)?.toInt();

    final courierArgs = <String, dynamic>{
      'courier_id': courierId,
      'courier': <String, dynamic>{
        'name': activeCourier['receiver_name']?.toString() ??
            activeCourier['name']?.toString() ??
            'Courier',
        'rating': '0.0',
        'eta': activeCourier['eta']?.toString() ?? '',
        'distance': activeCourier['distance']?.toString() ?? '',
      },
      'pickup_address':
          activeCourier['pickup_address']?.toString() ??
              senderPickupAddressController.text.trim(),
      'dropoff_address':
          activeCourier['dropoff_address']?.toString() ??
              receiverDropoffAddressController.text.trim(),
      'estimated_fare': _estimatedFareText ?? 'N/A',
      'payment_method': paymentArg,
      'pickup_lat': _pickupLatLng?.latitude,
      'pickup_lng': _pickupLatLng?.longitude,
      'dropoff_lat': _dropoffLatLng?.latitude,
      'dropoff_lng': _dropoffLatLng?.longitude,
    };

    // Replace current screen to ensure there is no intermediate UI.
    Get.off(() => const CourierRequestDetailsScreen(), arguments: courierArgs);
  }

  // ignore: unused_element
  Future<bool> _fetchNearbyCouriers() async {
    if (_pickupLatLng == null) {
      AppSnackBar.error(
        'common.error'.tr,
        'Pickup location is required to find nearby couriers.',
      );
      return false;
    }

    setState(() {
      _isLoadingNearbyCouriers = true;
      _nearbyCouriers = [];
    });

    try {
      final token = await _storageService.getAuthToken();
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse('${ApiUrls.baseUrl}${ApiUrls.courierNearby}');

      final body = jsonEncode({
        'pickup_lat': _pickupLatLng!.latitude,
        'pickup_lng': _pickupLatLng!.longitude,
      });

      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        String message = 'Failed to load nearby couriers.';
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          if (errorJson['message'] != null) {
            message = errorJson['message'].toString();
          }
        } catch (_) {}

        // ignore: avoid_print
        print(
          'PackageDetailsScreen _fetchNearbyCouriers error: '
          'statusCode=${response.statusCode}, body=${response.body}',
        );

        AppSnackBar.error('common.error'.tr, message);
        return false;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['status'] != true) {
        final message = (decoded['message'] ?? 'No couriers available.')
            .toString();

        // ignore: avoid_print
        print(
          'PackageDetailsScreen _fetchNearbyCouriers status false: $decoded',
        );

        AppSnackBar.error('common.error'.tr, message);
        return false;
      }

      final data = decoded['data'];
      if (data is List) {
        setState(() {
          _nearbyCouriers = data.whereType<Map<String, dynamic>>().toList(
            growable: false,
          );
        });
      }

      return true;
    } catch (e) {
      // ignore: avoid_print
      print('PackageDetailsScreen _fetchNearbyCouriers exception: $e');
      AppSnackBar.error(
        'common.error'.tr,
        'Something went wrong while loading nearby couriers.',
      );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNearbyCouriers = false;
        });
      }
    }
  }

  Future<bool> _fetchCourierFareEstimate() async {
    if (_pickupLatLng == null || _dropoffLatLng == null) {
      AppSnackBar.show(
        'common.error'.tr,
        'Pickup and dropoff locations are required.',
      );
      return false;
    }

    setState(() {
      _isLoadingFare = true;
      _estimatedFareText = null;
    });

    try {
      final token = await _storageService.getAuthToken();
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse('${ApiUrls.baseUrl}${ApiUrls.courierEstimate}');

      final body = jsonEncode({
        'pickup_lat': _pickupLatLng!.latitude,
        'pickup_lng': _pickupLatLng!.longitude,
        'dropoff_lat': _dropoffLatLng!.latitude,
        'dropoff_lng': _dropoffLatLng!.longitude,
        'package_size': selectedPackageSize ?? 'medium',
      });

      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        String message = 'Failed to get courier fare estimate.';
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          if (errorJson['message'] != null) {
            message = errorJson['message'].toString();
          }
        } catch (_) {
          // ignore parsing error, keep default message
        }

        // ignore: avoid_print
        print(
          'PackageDetailsScreen _fetchCourierFareEstimate error: '
          'statusCode=${response.statusCode}, body=${response.body}',
        );

        AppSnackBar.error('common.error'.tr, message);
        return false;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['status'] != true) {
        final message =
            (decoded['message'] ?? 'Failed to get courier fare estimate.')
                .toString();

        // ignore: avoid_print
        print(
          'PackageDetailsScreen _fetchCourierFareEstimate status false: '
          '$decoded',
        );

        AppSnackBar.error('common.error'.tr, message);
        return false;
      }

      num? fareValue;
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        final rawFare = data['fare'];
        if (rawFare is num) {
          fareValue = rawFare;
        } else {
          fareValue = num.tryParse('$rawFare');
        }
      } else if (data is List && data.isNotEmpty && data.first is Map) {
        final first = data.first as Map<String, dynamic>;
        final rawFare = first['fare'];
        if (rawFare is num) {
          fareValue = rawFare;
        } else {
          fareValue = num.tryParse('$rawFare');
        }
      }

      if (fareValue != null) {
        final formatted = fareValue.toDouble().toStringAsFixed(2);
        setState(() {
          _estimatedFareText = '\$ $formatted';
        });
        return true;
      }

      AppSnackBar.error('common.error'.tr, 'Unable to calculate fare. Please try again.');
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('PackageDetailsScreen _fetchCourierFareEstimate exception: $e');
      AppSnackBar.error(
        'common.error'.tr,
        'Something went wrong while getting fare estimate.',
      );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFare = false;
        });
      }
    }
  }
}

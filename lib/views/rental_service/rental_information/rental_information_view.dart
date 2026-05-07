import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:t_ride_rider_app/widgets/custom_appbar.dart';
import '../../../consts/appConst.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../core/config/api_urls.dart';
import '../../../data/local/secure_storage_service.dart';
import '../../../data/network/api_client.dart';
import '../rental_home/rental_home_view.dart';
import '../../../widgets/app_snackbar.dart';

class RentalInformationView extends StatefulWidget {
  const RentalInformationView({
    super.key,
    required this.rentableItemId,
    required this.totalPrice,
  });

  final int rentableItemId;
  final String totalPrice;

  @override
  State<RentalInformationView> createState() => _RentalInformationViewState();
}

class _RentalInformationViewState extends State<RentalInformationView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pickupDateTimeController =
      TextEditingController();
  final TextEditingController _dropoffDateTimeController =
      TextEditingController();
  final TextEditingController _pickupLocationController =
      TextEditingController();
  // This maps to `booking_details.rental_type` expected by backend.
  String _rentalType = 'Daily';
  final ProfileRepository _profileRepository = ProfileRepository();
  bool _isLoadingProfile = true;
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storageService = SecureStorageService();
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });
    try {
      final profile = await _profileRepository.getProfile();
      if (!mounted) return;

      // Avoid overwriting user input if they already started typing.
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = profile.name ?? '';
      }
      if (_phoneController.text.trim().isEmpty) {
        _phoneController.text = profile.phoneNumber ?? '';
      }
    } catch (e) {
      // ignore: avoid_print
      print('RentalInformationView loadProfile error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<void> _pickDateTime(TextEditingController controller) async {
    final now = DateTime.now();

    // Initial values
    DateTime initialDate = now;
    TimeOfDay initialTime = TimeOfDay.fromDateTime(now);

    // If pickup date exists and user is selecting drop-off, try to use it as initial.
    if (controller == _dropoffDateTimeController &&
        _pickupDateTimeController.text.trim().isNotEmpty) {
      // Best-effort: backend format is `YYYY-MM-DD HH:mm`; parse safely.
      try {
        final raw = _pickupDateTimeController.text.trim();
        final parsed = DateTime.tryParse(raw.replaceAll(' ', 'T'));
        if (parsed != null) {
          initialDate = parsed;
          initialTime = TimeOfDay.fromDateTime(parsed);
        }
      } catch (_) {}
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate == null) return;

    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (pickedTime == null) return;

    if (!mounted) return;

    final dt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    controller.text = _formatDateTime(dt);
  }

  Future<void> _bookRental() async {
    if (_isBooking) return;

    final rentableItemId = widget.rentableItemId;
    final userName = _nameController.text.trim();
    final userPhone = _phoneController.text.trim();
    final pickupDate = _pickupDateTimeController.text.trim();
    final dropoffDate = _dropoffDateTimeController.text.trim();
    final pickupLocation = _pickupLocationController.text.trim();

    if (rentableItemId <= 0) {
      AppSnackBar.error(
        'common.error'.tr,
        'rental.invalid_item'.tr,
      );
      return;
    }
    if (userName.isEmpty || userPhone.isEmpty) {
      AppSnackBar.error(
        'common.error'.tr,
        'rental.name_phone_required'.tr,
      );
      return;
    }
    if (pickupDate.isEmpty || dropoffDate.isEmpty || pickupLocation.isEmpty) {
      AppSnackBar.error(
        'common.error'.tr,
        'Pickup/Drop-off date and pickup location are required.',
      );
      return;
    }

    final totalPriceNumber = double.tryParse(widget.totalPrice.trim()) ?? 0.0;

    setState(() {
      _isBooking = true;
    });

    try {
      final token = await _storageService.getAuthToken();
      if (token == null || token.isEmpty) {
        AppSnackBar.error(
          'common.error'.tr,
          'You must be logged in to book.',
        );
        return;
      }

      final headers = <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final payload = <String, dynamic>{
        'rentable_item_id': rentableItemId,
        'user_name': userName,
        'user_phone': userPhone,
        'total_price': totalPriceNumber,
        'booking_details': {
          'pickup_date': pickupDate,
          'dropoff_date': dropoffDate,
          'pickup_location': pickupLocation,
          'rental_type': _rentalType,
        },
      };

      // ignore: avoid_print
      print('RentalInformationView booking payload: $payload');

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final response = await _apiClient.post(
        ApiUrls.rentalBook,
        headers: headers,
        body: payload,
      );

      if (Get.isDialogOpen == true) Get.back();

      if (response.statusCode != 200 && response.statusCode != 201) {
        String message = 'Booking failed.';
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          if (decoded['message'] != null) {
            message = decoded['message'].toString();
          }
        } catch (_) {}

        AppSnackBar.error('common.error'.tr, message);
        return;
      }

      AppSnackBar.success('common.success'.tr, 'rental.booking_confirmed'.tr);

      // Show snackbar then navigate back to rental home.
      Future.delayed(const Duration(milliseconds: 400), () {
        Get.offAll(() => const RentalHomeView());
      });
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      // ignore: avoid_print
      print('RentalInformationView book error: $e');
      AppSnackBar.error(
        'common.error'.tr,
        'Something went wrong while booking.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  Future<void> _pickPickupLocation() async {
    // Default position if we can't access current location.
    LatLng initialTarget = const LatLng(24.8607, 67.0011);

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        initialTarget = LatLng(pos.latitude, pos.longitude);
      }
    } catch (_) {
      // Best-effort only; keep initialTarget as default.
    }

    LatLng? pickedLatLng;
    String pickedLabel = '';
    Set<Marker> markers = {};

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          Future<void> reverseGeocodeToLabel(LatLng p) async {
            String label;
            try {
              final placemarks = await placemarkFromCoordinates(
                p.latitude,
                p.longitude,
              );

              if (placemarks.isNotEmpty) {
                final pm = placemarks.first;
                final parts = <String>[];
                if (pm.street != null && pm.street!.isNotEmpty) {
                  parts.add(pm.street!);
                }
                if (pm.locality != null && pm.locality!.isNotEmpty) {
                  parts.add(pm.locality!);
                }
                if (pm.administrativeArea != null &&
                    pm.administrativeArea!.isNotEmpty) {
                  parts.add(pm.administrativeArea!);
                }
                if (pm.country != null && pm.country!.isNotEmpty) {
                  parts.add(pm.country!);
                }

                // Keep it concise.
                final limited = parts.take(3).toList();
                label = limited.join(', ');
                if (label.trim().isEmpty) {
                  label =
                      '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}';
                }
              } else {
                label =
                    '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}';
              }
            } catch (_) {
              label =
                  '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}';
            }

            setState(() {
              pickedLatLng = p;
              pickedLabel = label;
              markers = {
                Marker(
                  markerId: const MarkerId('picked_pickup'),
                  position: p,
                  infoWindow: const InfoWindow(title: 'Pickup'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                ),
              };
            });
          }

          return Dialog(
            insetPadding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 520.h,
              child: SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Get.back(),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: pickedLatLng == null
                                ? null
                                : () {
                                    _pickupLocationController.text =
                                        pickedLabel.isNotEmpty
                                        ? pickedLabel
                                        : _pickupLocationController.text;
                                    Get.back();
                                  },
                            child: Text(
                              'Done',
                              style: TextStyle(
                                color: pickedLatLng == null
                                    ? AppConst.grey
                                    : AppConst.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: initialTarget,
                          zoom: 15.0,
                        ),
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                        markers: markers,
                        onTap: (pos) async {
                          // Reverse geocode and place marker.
                          await reverseGeocodeToLabel(pos);
                        },
                      ),
                    ),
                    if (pickedLatLng != null)
                      Padding(
                        padding: EdgeInsets.only(
                          left: 16.w,
                          right: 16.w,
                          top: 10.h,
                          bottom: 14.h,
                        ),
                        child: Text(
                          pickedLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppConst.black,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      barrierDismissible: false,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pickupDateTimeController.dispose();
    _dropoffDateTimeController.dispose();
    _pickupLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          // Top Header
          CustomAppBar(title: 'appbar.required_user_details'.tr),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoadingProfile) ...[
                    Padding(
                      padding: EdgeInsets.only(bottom: 20.h),
                      child: Center(
                        child: CircularProgressIndicator(color: AppConst.black),
                      ),
                    ),
                  ],
                  // Name Field
                  Text(
                    'rental.name'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your full name (e.g. John Doe)',
                        hintStyle: TextStyle(
                          color: AppConst.grey,
                          fontSize: 14.sp,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16.w),
                      ),
                      style: TextStyle(color: AppConst.black, fontSize: 14.sp),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Phone Number Field
                  Text(
                    'rental.phone'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Enter your phone number',
                        hintStyle: TextStyle(
                          color: AppConst.grey,
                          fontSize: 14.sp,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16.w),
                      ),
                      style: TextStyle(color: AppConst.black, fontSize: 14.sp),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Total Price (from rentable item)
                  Text(
                    'rental.total_price'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '\$ ${widget.totalPrice} ',
                      style: TextStyle(
                        color: AppConst.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Pick-up Date & Time Field
                  Text(
                    'rental.pickup_date'.tr,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: TextField(
                      controller: _pickupDateTimeController,
                      readOnly: true,
                      onTap: () {
                        _pickDateTime(_pickupDateTimeController);
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter your pick-up date & time',
                        hintStyle: TextStyle(
                          color: AppConst.grey,
                          fontSize: 14.sp,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16.w),
                      ),
                      style: TextStyle(color: AppConst.black, fontSize: 14.sp),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Drop-off Date & Time Field
                  Text(
                    'Drop-off Date & Time',
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: TextField(
                      controller: _dropoffDateTimeController,
                      readOnly: true,
                      onTap: () {
                        _pickDateTime(_dropoffDateTimeController);
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter your drop-off date & time',
                        hintStyle: TextStyle(
                          color: AppConst.grey,
                          fontSize: 14.sp,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16.w),
                      ),
                      style: TextStyle(color: AppConst.black, fontSize: 14.sp),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Pick-up Location Field
                  Text(
                    'Pick-up Location',
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: TextField(
                      controller: _pickupLocationController,
                      readOnly: true,
                      onTap: _pickPickupLocation,
                      decoration: InputDecoration(
                        hintText: 'Enter your pick-up location',
                        hintStyle: TextStyle(
                          color: AppConst.grey,
                          fontSize: 14.sp,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16.w),
                      ),
                      style: TextStyle(color: AppConst.black, fontSize: 14.sp),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Rental Type Field
                  Text(
                    'Rental type:',
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _rentalType,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(
                              value: 'Daily',
                              child: Text('rental.daily'.tr),
                            ),
                            DropdownMenuItem(
                              value: 'Monthly',
                              child: Text('rental.monthly'.tr),
                            ),
                            DropdownMenuItem(
                              value: 'Yearly',
                              child: Text('rental.yearly'.tr),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _rentalType = v;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
          // Continue Button
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
                _bookRental();
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: _isBooking
                      ? AppConst.accentWithOpacity(0.55)
                      : AppConst.accent,
                  borderRadius: AppConst.buttonRadius,
                ),
                child: Center(
                  child: Text(
                    _isBooking ? 'rental.booking'.tr : 'common.continue'.tr,
                    style: TextStyle(
                      color: AppConst.black,
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
}

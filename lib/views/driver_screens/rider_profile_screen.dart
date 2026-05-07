import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_ride_rider_app/data/repositories/rides_repository.dart';
import 'package:t_ride_rider_app/views/location/nearby_driver_model.dart';
import '../../consts/appConst.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_appbar.dart';
import 'driver_details_screen.dart';

class RiderProfileScreen extends StatefulWidget {
  final bool isCourierService;
  final NearbyDriver? driver;

  /// Fare to charge (e.g. after coupon). Prefer this over [Get.arguments] `fare`
  /// so `rides/request` always receives the discounted amount.
  final num? fare;

  const RiderProfileScreen({
    super.key,
    this.isCourierService = false,
    this.driver,
    this.fare,
  });

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  final RidesRepository _ridesRepository = RidesRepository();
  bool _isRequesting = false;

  num? _parseFare(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  Map<String, dynamic> _routeArgs() {
    final raw = Get.arguments;
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return {};
  }

  Future<void> _onConfirmPressed(NearbyDriver d) async {
    if (_isRequesting) return;

    final args = _routeArgs();

    final pickupAddress = (args['pickup_address'] as String?)?.trim() ?? '';
    final pickupLat = args['pickup_lat'];
    final pickupLng = args['pickup_lng'];
    final dropoffAddress = (args['dropoff_address'] as String?)?.trim() ?? '';
    final dropoffLat = args['dropoff_lat'];
    final dropoffLng = args['dropoff_lng'];
    final paymentMethod = (args['payment_method'] as String?)?.trim() ?? 'Cash';
    final fare = _parseFare(widget.fare ?? args['fare']);

    final pickupLatNum = pickupLat is num
        ? pickupLat.toDouble()
        : double.tryParse('$pickupLat');
    final pickupLngNum = pickupLng is num
        ? pickupLng.toDouble()
        : double.tryParse('$pickupLng');
    final dropoffLatNum = dropoffLat is num
        ? dropoffLat.toDouble()
        : double.tryParse('$dropoffLat');
    final dropoffLngNum = dropoffLng is num
        ? dropoffLng.toDouble()
        : double.tryParse('$dropoffLng');

    if (pickupAddress.isEmpty ||
        dropoffAddress.isEmpty ||
        pickupLatNum == null ||
        pickupLngNum == null ||
        dropoffLatNum == null ||
        dropoffLngNum == null ||
        fare == null) {
      AppSnackBar.show(
        'common.error'.tr,
        'Pickup/dropoff/fare information is missing.',
      );
      return;
    }

    setState(() {
      _isRequesting = true;
    });

    try {
      final response = await _ridesRepository.requestRide(
        pickupAddress: pickupAddress,
        pickupLat: pickupLatNum,
        pickupLng: pickupLngNum,
        dropoffAddress: dropoffAddress,
        dropoffLat: dropoffLatNum,
        dropoffLng: dropoffLngNum,
        paymentMethod: paymentMethod,
        fare: fare,
        tipAmount: 0,
        driverId: d.id,
      );

      if (response['status'] == true) {
        AppSnackBar.show('common.success'.tr, 'Ride requested successfully');
        Get.to(
          () => DriverDetailsScreen(isCourierService: widget.isCourierService),
          arguments: {
            ...args,
            'driver': d,
            'ride_request': response,
            'fare': fare,
          },
        );
      } else {
        AppSnackBar.show(
          'common.error'.tr,
          (response['message']?.toString() ?? 'Unable to request ride'),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('RiderProfileScreen requestRide error: $e');
      AppSnackBar.show('common.error'.tr, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final argDriver = _routeArgs()['driver'];
    final d = widget.driver ?? (argDriver is NearbyDriver ? argDriver : null);
    final name = d?.name ?? 'Rider';
    final ratingValue = double.tryParse(d?.rating ?? '') ?? 0.0;
    final fullStars = ratingValue.floor().clamp(0, 5);

    return Scaffold(
      backgroundColor: AppConst.background,
      body: Column(
        children: [
          // Top Header
          CustomAppBar(title: 'appbar.rider_profile'.tr),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 40.h),
                  // Profile Picture
                  CircleAvatar(
                    radius: 60.r,
                    backgroundColor: Colors.blue,
                    backgroundImage: (d?.photo != null && d!.photo!.isNotEmpty)
                        ? NetworkImage(d.photo!)
                        : null,
                    child: (d?.photo == null || d!.photo!.isEmpty)
                        ? Text(
                            (d?.initials ?? 'R').toUpperCase(),
                            style: TextStyle(
                              color: AppConst.white,
                              fontSize: 36.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  SizedBox(height: 16.h),
                  // Name
                  Text(
                    name,
                    style: TextStyle(
                      color: AppConst.black,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Rating Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final filled = index < fullStars;
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3.w),
                        child: Icon(
                          filled ? Icons.star : Icons.star_outline,
                          color: AppConst.black,
                          size: 28.sp,
                        ),
                      );
                    }),
                  ),
                  if (d != null) ...[
                    SizedBox(height: 10.h),
                    Text(
                      '${d.eta} • ${d.distance}',
                      style: TextStyle(
                        color: AppConst.grey,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  SizedBox(height: 40.h),
                  // Description Box
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppConst.cardLight,
                      borderRadius: AppConst.borderRadius,
                    ),
                    child: Text(
                      'A Rider is a registered user who requests rides through our platform. Riders can easily book trips, track their drivers in real-time, and enjoy safe, reliable, and convenient transportation. Our system ensures a smooth experience from booking to reaching the destination.',
                      style: TextStyle(
                        color: AppConst.black,
                        fontSize: 14.sp,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
          // Confirm Rider Button
          Container(
            padding: EdgeInsets.all(20.w),
            child: GestureDetector(
              onTap: () {
                if (d == null) {
                  AppSnackBar.show(
                    'ride.select_driver_prompt'.tr,
                    'ride.select_driver_body'.tr,
                  );
                  return;
                }
                _onConfirmPressed(d);
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: AppConst.black,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: _isRequesting
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppConst.white,
                          ),
                        )
                      : Text(
                          'ride.confirm_rider'.tr,
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
}

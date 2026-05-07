import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:t_ride_rider_app/data/models/user_profile_model.dart';

/// Publishes rider-side ride requests to Firestore for the driver app to listen
/// in realtime (`active_rides` collection).
class ActiveRidesFirestoreService {
  ActiveRidesFirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Collection name agreed for rider ↔ driver realtime sync.
  static const String collection = 'active_rides';

  /// High-level lifecycle for driver/rider UIs (e.g. searching → assigned → …).
  static const String generalStatusSearching = 'searching';

  static int? _parseRideId(Map<String, dynamic> apiRideResponse) {
    final raw = apiRideResponse['data'];
    final data = raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{};
    final idVal = data['id'] ?? apiRideResponse['id'];
    if (idVal is num) return idVal.toInt();
    return int.tryParse('$idVal');
  }

  static String? _parseRideCustomId(Map<String, dynamic> apiRideResponse) {
    final raw = apiRideResponse['data'];
    if (raw is! Map) return null;
    final data = Map<String, dynamic>.from(raw);
    final customId = data['ride_custom_id']?.toString().trim();
    if (customId == null || customId.isEmpty) return null;
    return customId;
  }

  static String _parseRideStatus(Map<String, dynamic> apiRideResponse) {
    final raw = apiRideResponse['data'];
    if (raw is! Map) return 'requested';
    final data = Map<String, dynamic>.from(raw);
    final status = data['status']?.toString().trim();
    if (status == null || status.isEmpty) return 'requested';
    return status;
  }

  /// Upserts a document after `rides/request` succeeds.
  /// Firestore doc id is generated randomly to avoid id coupling.
  Future<void> publishRideRequested({
    required Map<String, dynamic> apiRideResponse,
    required UserProfile? rider,
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String dropoffAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String paymentMethod,
    required num fare,
    num tipAmount = 0,
    String? couponCode,
    String rideType = 'T-Go',
    int? assignedDriverId,
  }) async {
    final rideId = _parseRideId(apiRideResponse);
    final rideCustomId = _parseRideCustomId(apiRideResponse);
    final rideStatus = _parseRideStatus(apiRideResponse);
    final docId = _db.collection(collection).doc().id;

    final pickupGeo = GeoPoint(pickupLat, pickupLng);
    final dropoffGeo = GeoPoint(dropoffLat, dropoffLng);

    final payload = <String, dynamic>{
      'ride_id': rideId,
      if (rideCustomId != null) 'ride_custom_id': rideCustomId,
      'status': rideStatus,
      'general_status': generalStatusSearching,
      'service_type': 'ride',
      'ride_type': rideType,
      'fare': fare is int ? fare : fare.toDouble(),
      'tip_amount': tipAmount is int ? tipAmount : tipAmount.toDouble(),
      'payment_method': paymentMethod,
      'coupon_code': couponCode ?? '',
      if (assignedDriverId != null && assignedDriverId > 0)
        'assigned_driver_id': assignedDriverId,
      'pickup': <String, dynamic>{
        'address': pickupAddress,
        'latitude': pickupLat,
        'longitude': pickupLng,
        'geo_point': pickupGeo,
      },
      'dropoff': <String, dynamic>{
        'address': dropoffAddress,
        'latitude': dropoffLat,
        'longitude': dropoffLng,
        'geo_point': dropoffGeo,
      },
      'rider': <String, dynamic>{
        if (rider?.id != null) 'id': rider!.id,
        'name': rider?.name ?? '',
        'email': rider?.email ?? '',
        'phone_number': rider?.phoneNumber ?? '',
        'whatsapp_number': rider?.whatsappNumber ?? '',
        'photo': rider?.photo ?? '',
        'city': rider?.city ?? '',
      },
      'api_status': apiRideResponse['status'],
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'source_app': 'rider',
    };

    await _db.collection(collection).doc(docId).set(payload, SetOptions(merge: true));
    if (kDebugMode) {
      debugPrint('ActiveRidesFirestore: wrote $collection/$docId');
    }
  }

  /// Removes the realtime doc(s) for this ride after backend cancel succeeds.
  Future<void> deleteActiveRideByRideId(int rideId) async {
    if (rideId <= 0) return;
    final snap = await _db
        .collection(collection)
        .where('ride_id', isEqualTo: rideId)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
    if (kDebugMode) {
      debugPrint(
        'ActiveRidesFirestore: deleted ${snap.docs.length} doc(s) for ride_id=$rideId',
      );
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:t_ride_rider_app/data/models/user_profile_model.dart';

/// Publishes rider-side courier requests to Firestore for realtime sync.
class ActiveCourierFirestoreService {
  ActiveCourierFirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Collection name agreed for rider/courier realtime sync.
  static const String collection = 'active_courier';

  /// High-level lifecycle for courier UIs.
  static const String generalStatusSearching = 'searching';

  static int? _parseCourierId(Map<String, dynamic> apiCourierResponse) {
    final raw = apiCourierResponse['data'];
    if (raw is! Map) return null;
    final data = Map<String, dynamic>.from(raw);
    final idVal = data['id'] ?? data['courier_id'] ?? data['courierId'];
    if (idVal is num) return idVal.toInt();
    return int.tryParse('$idVal');
  }

  /// Creates a generated Firestore document after `courier/request` succeeds.
  Future<String> publishCourierRequested({
    required Map<String, dynamic> apiCourierResponse,
    required UserProfile? rider,
    required String senderPickupAddress,
    required double senderPickupLat,
    required double senderPickupLng,
    required String receiverName,
    required String receiverPhone,
    required String receiverDropoffAddress,
    required double receiverDropoffLat,
    required double receiverDropoffLng,
    required String senderPhone,
    required String paymentMethod,
    required num estimatedFare,
    required num packageWeight,
    required String packageSize,
    String? packagePhoto,
    String? pickupInstructions,
    String? dropoffInstructions,
  }) async {
    final courierId = _parseCourierId(apiCourierResponse);
    final docId = 'general_${DateTime.now().millisecondsSinceEpoch}';

    final pickupGeo = GeoPoint(senderPickupLat, senderPickupLng);
    final dropoffGeo = GeoPoint(receiverDropoffLat, receiverDropoffLng);

    final payload = <String, dynamic>{
      'doc_id': docId,
      'courier_id': courierId,
      'status': 'requested',
      'general_status': generalStatusSearching,
      'service_type': 'courier',
      'estimated_fare':
          estimatedFare is int ? estimatedFare : estimatedFare.toDouble(),
      'payment_method': paymentMethod,
      'package': <String, dynamic>{
        'size': packageSize,
        'weight': packageWeight is int ? packageWeight : packageWeight.toDouble(),
        'photo': packagePhoto ?? '',
      },
      'pickup': <String, dynamic>{
        'address': senderPickupAddress,
        'latitude': senderPickupLat,
        'longitude': senderPickupLng,
        'geo_point': pickupGeo,
        'instructions': pickupInstructions ?? '',
      },
      'dropoff': <String, dynamic>{
        'receiver_name': receiverName,
        'receiver_phone': receiverPhone,
        'address': receiverDropoffAddress,
        'latitude': receiverDropoffLat,
        'longitude': receiverDropoffLng,
        'geo_point': dropoffGeo,
        'instructions': dropoffInstructions ?? '',
      },
      'rider': <String, dynamic>{
        if (rider?.id != null) 'id': rider!.id,
        'name': rider?.name ?? '',
        'email': rider?.email ?? '',
        'phone_number': rider?.phoneNumber ?? senderPhone,
        'whatsapp_number': rider?.whatsappNumber ?? '',
        'photo': rider?.photo ?? '',
        'city': rider?.city ?? '',
      },
      'sender_phone': senderPhone,
      'api_status': apiCourierResponse['status'],
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'source_app': 'rider',
    };

    await _db.collection(collection).doc(docId).set(
          payload,
          SetOptions(merge: true),
        );
    if (kDebugMode) {
      debugPrint('ActiveCourierFirestore: wrote $collection/$docId');
    }
    return docId;
  }
}

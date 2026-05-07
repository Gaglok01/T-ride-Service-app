import 'dart:convert';

import 'package:t_ride_rider_app/core/config/api_urls.dart';
import 'package:t_ride_rider_app/data/local/secure_storage_service.dart';
import 'package:t_ride_rider_app/data/network/api_client.dart';

class RidesRepository {
  RidesRepository({
    ApiClient? apiClient,
    SecureStorageService? storageService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storageService = storageService ?? SecureStorageService();

  final ApiClient _apiClient;
  final SecureStorageService _storageService;

  static const _defaultHeaders = {
    'Accept': 'application/json',
  };

  /// POST [ApiUrls.ridesRequest]. When [driverId] is null, `driver_id` is omitted
  /// from the JSON body (open / broadcast booking).
  Future<Map<String, dynamic>> requestRide({
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String dropoffAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String paymentMethod,
    required num fare,
    num tipAmount = 0,
    int? driverId,
  }) async {
    final token = await _storageService.getAuthToken();
    if (token == null || token.isEmpty) {
      throw RidesRepositoryException(
        statusCode: 401,
        body: 'Missing auth token',
      );
    }

    final headers = {
      ..._defaultHeaders,
      'Authorization': 'Bearer $token',
    };

    final payload = <String, dynamic>{
      'pickup_address': pickupAddress,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'dropoff_address': dropoffAddress,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
      'payment_method': paymentMethod,
      'fare': fare,
      'tip_amount': tipAmount,
    };
    if (driverId != null) {
      payload['driver_id'] = driverId;
    }

    // ignore: avoid_print
    print('RidesRepository.requestRide payload: $payload');

    final response = await _apiClient.post(
      ApiUrls.ridesRequest,
      headers: headers,
      body: payload,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = RidesRepositoryException(
        statusCode: response.statusCode,
        body: response.body,
      );
      // ignore: avoid_print
      print('RidesRepository.requestRide error: $error');
      throw error;
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded;
  }

  Future<Map<String, dynamic>> cancelRide({required int rideId}) async {
    final token = await _storageService.getAuthToken();
    if (token == null || token.isEmpty) {
      throw RidesRepositoryException(
        statusCode: 401,
        body: 'Missing auth token',
      );
    }

    final headers = {
      ..._defaultHeaders,
      'Authorization': 'Bearer $token',
    };

    final endpoint = '${ApiUrls.ridesRequest}/$rideId/cancel'
        .replaceFirst('request/', ''); // ensure /api/app/rides/{id}/cancel

    // ignore: avoid_print
    print('RidesRepository.cancelRide endpoint: $endpoint');

    final response = await _apiClient.post(
      endpoint,
      headers: headers,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = RidesRepositoryException(
        statusCode: response.statusCode,
        body: response.body,
      );
      // ignore: avoid_print
      print('RidesRepository.cancelRide error: $error');
      throw error;
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded;
  }

  Future<Map<String, dynamic>> getActiveRide() async {
    final token = await _storageService.getAuthToken();
    if (token == null || token.isEmpty) {
      throw RidesRepositoryException(
        statusCode: 401,
        body: 'Missing auth token',
      );
    }

    final headers = {
      ..._defaultHeaders,
      'Authorization': 'Bearer $token',
    };

    final response = await _apiClient.get(
      ApiUrls.ridesActive,
      headers: headers,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = RidesRepositoryException(
        statusCode: response.statusCode,
        body: response.body,
      );
      // ignore: avoid_print
      print('RidesRepository.getActiveRide error: $error');
      throw error;
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded;
  }
}

class RidesRepositoryException implements Exception {
  RidesRepositoryException({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  @override
  String toString() => 'RidesRepositoryException($statusCode): $body';
}


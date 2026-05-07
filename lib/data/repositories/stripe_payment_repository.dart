import 'dart:convert';

import 'package:t_ride_rider_app/core/config/api_urls.dart';
import 'package:t_ride_rider_app/data/local/secure_storage_service.dart';
import 'package:t_ride_rider_app/data/network/api_client.dart';

class StripePaymentRepository {
  StripePaymentRepository({
    ApiClient? apiClient,
    SecureStorageService? storageService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storageService = storageService ?? SecureStorageService();

  final ApiClient _apiClient;
  final SecureStorageService _storageService;

  static const _defaultHeaders = {
    'Accept': 'application/json',
  };

  Future<Map<String, dynamic>> createRideCompletionPaymentIntent({
    required int rideId,
    required num amount,
    String currency = 'usd',
  }) async {
    final token = await _storageService.getAuthToken();
    if (token == null || token.isEmpty) {
      throw StripePaymentRepositoryException(
        statusCode: 401,
        body: 'Missing auth token',
      );
    }

    final headers = {
      ..._defaultHeaders,
      'Authorization': 'Bearer $token',
    };

    final response = await _apiClient.post(
      ApiUrls.stripeCreatePaymentIntent,
      headers: headers,
      body: {
        'amount': amount,
        'currency': currency,
        'metadata': {
          'ride_id': '$rideId',
          'type': 'ride',
        },
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw StripePaymentRepositoryException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded;
  }
}

class StripePaymentRepositoryException implements Exception {
  StripePaymentRepositoryException({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  @override
  String toString() => 'StripePaymentRepositoryException($statusCode): $body';
}

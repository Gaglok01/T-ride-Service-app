import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:t_ride_rider_app/core/config/api_urls.dart';
import 'package:t_ride_rider_app/data/local/secure_storage_service.dart';
import 'package:t_ride_rider_app/data/network/api_client.dart';

class AuthRepository {
  AuthRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  final SecureStorageService _storageService = SecureStorageService();

  /// Stores the most recent OTP returned by the API for debugging/display.
  static String? lastDebugOtp;

  static const _defaultHeaders = {
    'Accept': 'application/json',
  };

  /// Logs out the current user (requires Bearer token).
  ///
  /// On success, also clears the stored auth token.
  Future<bool> logout() async {
    final token = await _storageService.getAuthToken();
    if (token == null || token.isEmpty) {
      await _storageService.clearAuthToken();
      return true;
    }

    final response = await _apiClient.post(
      ApiUrls.appLogout,
      headers: {
        ..._defaultHeaders,
        'Authorization': 'Bearer $token',
      },
      body: {},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = AuthRepositoryException(
        statusCode: response.statusCode,
        body: response.body,
      );
      // ignore: avoid_print
      print('AuthRepository.logout error: $error');
      throw error;
    }

    await _storageService.clearAuthToken();

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final status = decoded['status'];

    if (status is bool) return status;
    if (status is num) return status == 1;

    return true;
  }

  /// Logs a user in with identifier (phone/email) and password.
  ///
  /// Payload:
  /// {
  ///   "identifier": "+923139873215",
  ///   "password": "Abdulbasit123@"
  /// }
  ///
  /// Returns the decoded JSON (status, user, token).
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiUrls.login,
      headers: _defaultHeaders,
      body: {
        'identifier': identifier,
        'password': password,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = AuthRepositoryException(
        statusCode: response.statusCode,
        body: response.body,
      );
      // ignore: avoid_print
      print('AuthRepository.login error: $error');
      throw error;
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded;
  }

  /// Sends OTP using the given method and identifier.
  ///
  /// Examples:
  /// - WhatsApp:
  ///   method: "whatsapp", whatsappNumber: "+923001234567"
  /// - Phone:
  ///   method: "phone", phoneNumber: "+923001234567"
  /// - Email:
  ///   method: "email", email: "example@example.com"
  Future<bool> sendOtp({
    required String method,
    String? whatsappNumber,
    String? phoneNumber,
    String? email,
  }) async {
    final Map<String, dynamic> body = {
      'method': method,
      if (whatsappNumber != null) 'whatsapp_number': whatsappNumber,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (email != null) 'email': email,
    };

    final response = await _apiClient.post(
      ApiUrls.sendOtp,
      headers: _defaultHeaders,
      body: body,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = AuthRepositoryException(
        statusCode: response.statusCode,
        body: response.body,
      );
      // ignore: avoid_print
      print('AuthRepository.sendOtp error: $error');
      throw error;
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    // Log OTP to console if present in the response
    if (decoded.containsKey('otp')) {
      // ignore: avoid_print
      print('DEBUG OTP from API: ${decoded['otp']}');
      lastDebugOtp = decoded['otp']?.toString();
    }

    final status = decoded['status'];

    if (status is bool) return status;
    if (status is num) return status == 1;

    return true;
  }

  /// Verifies OTP for a given identifier.
  ///
  /// Payload:
  /// {
  ///   "identifier": "+923001234567" or "example@example.com",
  ///   "otp": "1234"
  /// }
  Future<bool> verifyOtp({
    required String identifier,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      ApiUrls.verifyOtp,
      headers: _defaultHeaders,
      body: {
        'identifier': identifier,
        'otp': otp,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = AuthRepositoryException(
        statusCode: response.statusCode,
        body: response.body,
      );
      // ignore: avoid_print
      print('AuthRepository.verifyOtp error: $error');
      throw error;
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final status = decoded['status'];

    if (status is bool) return status;
    if (status is num) return status == 1;

    return true;
  }

  /// Registers a user with the provided profile details.
  ///
  /// The backend used by different T-Ride builds has changed names for a few
  /// fields over time. We send safe aliases so signup is more tolerant while
  /// still keeping the same public method used by the app.
  Future<bool> register({
    required String identifier,
    required String name,
    required String password,
    required String role,
    required int languageId,
    required String address,
    required String city,
    String? region,
  }) async {
    final cleanIdentifier = identifier.trim();
    final cleanPhone = cleanIdentifier.startsWith('+') ? cleanIdentifier : null;
    final cleanEmail = cleanIdentifier.contains('@') ? cleanIdentifier : null;

    final payload = <String, dynamic>{
      'identifier': cleanIdentifier,
      'name': name.trim(),
      'full_name': name.trim(),
      'password': password,
      'password_confirmation': password,
      'role': role.trim().toLowerCase(),
      'user_type': role.trim().toLowerCase(),
      'language_id': languageId,
      'address': address.trim(),
      'city': city.trim(),
      if (region != null && region.trim().isNotEmpty) 'region': region.trim(),
      if (cleanPhone != null) 'phone': cleanPhone,
      if (cleanPhone != null) 'phone_number': cleanPhone,
      if (cleanEmail != null) 'email': cleanEmail,
    };

    http.Response response;
    try {
      response = await _apiClient
          .post(
            ApiUrls.register,
            headers: _defaultHeaders,
            body: payload,
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw AuthRepositoryException(
        statusCode: 408,
        body: 'The registration server took too long to respond.',
      );
    } catch (e) {
      throw AuthRepositoryException(
        statusCode: 0,
        body: 'Unable to connect to the registration server. Please try again.',
      );
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = AuthRepositoryException(
        statusCode: response.statusCode,
        body: response.body,
      );
      // ignore: avoid_print
      print('AuthRepository.register error: $error');
      throw error;
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthRepositoryException(
        statusCode: response.statusCode,
        body: 'Invalid response from registration server.',
      );
    }

    final status = decoded['status'];
    if (status is bool) return status;
    if (status is num) return status == 1;

    // Some Laravel endpoints return only token/user/message without a status flag.
    if (decoded.containsKey('token') || decoded.containsKey('user')) {
      return true;
    }

    return true;
  }

  String friendlyErrorMessage(Object error) {
    if (error is! AuthRepositoryException) {
      return 'Something went wrong. Please try again.';
    }

    final raw = error.body.trim();
    if (error.statusCode == 408) {
      return 'The server is taking too long. Please try again.';
    }
    if (error.statusCode == 0) {
      return 'Unable to connect. Please check your internet and try again.';
    }

    if (raw.startsWith('{')) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final message = decoded['message']?.toString().trim();
        if (message != null && message.isNotEmpty &&
            !message.toLowerCase().contains('sqlstate')) {
          return message;
        }
        final errors = decoded['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
          return first.toString();
        }
      } catch (_) {}
    }

    if (raw.toLowerCase().contains('sqlstate') || raw.toLowerCase().contains('exception')) {
      return 'We could not create the account right now. Please try again later.';
    }

    return raw.isNotEmpty ? raw : 'Registration failed. Please try again.';
  }
}

class AuthRepositoryException implements Exception {
  AuthRepositoryException({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  @override
  String toString() => 'AuthRepositoryException($statusCode): $body';
}


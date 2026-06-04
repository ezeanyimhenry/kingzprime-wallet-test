import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_signature.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this._config);

  final AppConfig _config;

  String get _addToWalletUrl =>
      '${_config.baseUrl}/api/v1/user/virtual-cards/add-to-wallet';

  Map<String, String> _signedHeaders(Map<String, dynamic> params) {
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final signature = ApiSignature.sign(
      params: params,
      timestamp: timestamp,
      jwt: _config.jwtToken,
    );

    return {
      'Authorization': 'Bearer ${_config.jwtToken}',
      'X-API-Timestamp': timestamp,
      'X-API-Signature': signature,
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> addToWallet({
    required String cardId,
    required String walletType,
    bool includePassBase64 = true,
  }) async {
    if (!_config.hasBaseUrl) {
      throw ApiException('API base URL is not set');
    }

    final body = <String, dynamic>{
      'card_id': cardId,
      'wallet_type': walletType,
      if (walletType == 'apple') 'include_pass_base64': includePassBase64,
    };

    final response = await http.post(
      Uri.parse(_addToWalletUrl),
      headers: _signedHeaders(body),
      body: jsonEncode(body),
    );

    return _parseResponse(response);
  }

  Future<List<int>> downloadWalletPass(String downloadUrl) async {
    final uri = Uri.parse(downloadUrl);
    final response = await http.get(
      uri,
      headers: _signedHeaders({}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }

    throw ApiException(
      'Failed to download pass (${response.statusCode})',
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    Map<String, dynamic>? jsonBody;
    try {
      jsonBody = jsonDecode(response.body) as Map<String, dynamic>?;
    } catch (_) {
      throw ApiException(
        'Invalid JSON response (${response.statusCode})',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        jsonBody?['status'] == 'success') {
      final data = jsonBody!['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {'payload': data};
    }

    final message = jsonBody?['message']?.toString() ??
        jsonBody?['error']?.toString() ??
        'Request failed (${response.statusCode})';

    throw ApiException(
      message,
      statusCode: response.statusCode,
      body: response.body,
    );
  }
}

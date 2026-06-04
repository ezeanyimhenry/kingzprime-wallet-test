import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Mirrors [VerifyApiSignature] in kingzprime-api.
class ApiSignature {
  static String buildParamString(Map<String, dynamic> params) {
    final sorted = Map<String, dynamic>.from(params);
    final keys = sorted.keys.toList()..sort();
    final parts = <String>[];

    for (final key in keys) {
      final value = _normalizeValue(sorted[key]);
      parts.add('$key=${Uri.encodeComponent(value)}');
    }

    return parts.join('&');
  }

  static String sign({
    required Map<String, dynamic> params,
    required String timestamp,
    required String jwt,
  }) {
    final paramString = buildParamString(params);
    final data = '$paramString$timestamp$jwt';
    return sha256.convert(utf8.encode(data)).toString();
  }

  static String _normalizeValue(dynamic value) {
    if (value is bool) {
      return value ? 'true' : 'false';
    }
    if (value is Map || value is List) {
      return jsonEncode(value);
    }
    return value.toString();
  }
}

import 'package:flutter/foundation.dart';

/// Session-only configuration for the wallet test harness.
class AppConfig extends ChangeNotifier {
  AppConfig({required this.jwtToken});

  final String jwtToken;
  String? _baseUrl;

  String? get baseUrl => _baseUrl;

  bool get hasBaseUrl => _baseUrl != null && _baseUrl!.isNotEmpty;

  void setBaseUrl(String url) {
    var normalized = url.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    _baseUrl = normalized;
    notifyListeners();
  }
}

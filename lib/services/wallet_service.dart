import 'dart:convert';

import 'package:apple_passkit/apple_passkit.dart';
import 'package:flutter/foundation.dart';
import 'package:google_wallet/google_wallet.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_client.dart';

class WalletAddResult {
  const WalletAddResult({required this.data, required this.message});

  final Map<String, dynamic> data;
  final String message;
}

class WalletService {
  WalletService(this._apiClient);

  final ApiClient _apiClient;
  final ApplePassKit _applePassKit = ApplePassKit();
  final GoogleWallet _googleWallet = GoogleWallet();

  bool get isIos => defaultTargetPlatform == TargetPlatform.iOS;
  bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;

  Future<WalletAddResult> addToWallet({
    required String cardId,
    required String walletType,
  }) async {
    final data = await _apiClient.addToWallet(
      cardId: cardId,
      walletType: walletType,
      includePassBase64: walletType == 'apple',
    );

    final message = walletType == 'apple'
        ? await _addApplePass(data)
        : await _addGooglePass(data);

    return WalletAddResult(data: data, message: message);
  }

  Future<String> _addApplePass(Map<String, dynamic> data) async {
    if (!isIos) {
      return 'API success. Apple Wallet add requires a physical iOS device.';
    }

    final available = await _applePassKit.isPassLibraryAvailable();
    if (!available) {
      throw WalletException(
        'PassKit is not available (use a physical iPhone, not the simulator).',
      );
    }

    final canAdd = await _applePassKit.canAddPasses();
    if (!canAdd) {
      throw WalletException('This device cannot add passes to Wallet.');
    }

    final bytes = await _resolvePkpassBytes(data);
    await _applePassKit.addPass(bytes);
    return 'Pass added to Apple Wallet.';
  }

  Future<Uint8List> _resolvePkpassBytes(Map<String, dynamic> data) async {
    final base64Pass = data['pass_base64'] as String?;
    if (base64Pass != null && base64Pass.isNotEmpty) {
      return Uint8List.fromList(base64Decode(base64Pass));
    }

    final downloadUrl = data['download_url'] as String?;
    if (downloadUrl == null || downloadUrl.isEmpty) {
      throw WalletException(
        'No pass_base64 or download_url in response. Try include_pass_base64 or check API config.',
      );
    }

    final fileBytes = await _apiClient.downloadWalletPass(downloadUrl);
    return Uint8List.fromList(fileBytes);
  }

  Future<String> _addGooglePass(Map<String, dynamic> data) async {
    final jwt = data['jwt'] as String?;
    final addUrl = data['add_to_wallet_url'] as String?;

    if (jwt == null || jwt.isEmpty) {
      throw WalletException('No jwt in Google Wallet response.');
    }

    if (!isAndroid) {
      if (addUrl != null) {
        return 'API success. Open add_to_wallet_url on an Android device with Google Wallet.';
      }
      return 'API success. Google Wallet add requires Android.';
    }

    try {
      final available = await _googleWallet.isAvailable();
      if (available == true) {
        final saved = await _googleWallet.savePassesJwt(jwt);
        if (saved == true) {
          return 'Pass saved to Google Wallet.';
        }
      }
    } catch (e) {
      // Fall through to URL launcher.
    }

    final url = addUrl ?? 'https://pay.google.com/gp/v/save/$jwt';
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      throw WalletException('Cannot open Google Wallet URL.');
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return 'Opened Google Wallet in browser.';
  }
}

class WalletException implements Exception {
  WalletException(this.message);

  final String message;

  @override
  String toString() => message;
}

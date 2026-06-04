import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/api_client.dart';
import '../services/wallet_service.dart';
import '../widgets/response_panel.dart';

class WalletTestScreen extends StatefulWidget {
  const WalletTestScreen({super.key, required this.config});

  final AppConfig config;

  @override
  State<WalletTestScreen> createState() => _WalletTestScreenState();
}

class _WalletTestScreenState extends State<WalletTestScreen> {
  final _cardIdController = TextEditingController();
  String _walletType = 'apple';
  bool _loading = false;
  String _responseText = '';
  String _statusText = '';
  bool _isError = false;

  late final WalletService _walletService;

  @override
  void initState() {
    super.initState();
    _walletService = WalletService(ApiClient(widget.config));
  }

  @override
  void dispose() {
    _cardIdController.dispose();
    super.dispose();
  }

  String get _platformHint {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'Apple Wallet works on this device. Google will call the API only.';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'Google Wallet works on this device. Apple will call the API only.';
    }
    return 'Use a physical iPhone or Android device for native wallet add.';
  }

  Future<void> _addToWallet() async {
    final cardId = _cardIdController.text.trim();
    if (cardId.isEmpty) {
      setState(() {
        _isError = true;
        _statusText = 'Enter card_id';
        _responseText = '';
      });
      return;
    }

    setState(() {
      _loading = true;
      _isError = false;
      _statusText = 'Calling API…';
      _responseText = '';
    });

    try {
      final result = await _walletService.addToWallet(
        cardId: cardId,
        walletType: _walletType,
      );

      final pretty = const JsonEncoder.withIndent('  ').convert(result.data);
      setState(() {
        _responseText = pretty;
        _isError = false;
        _statusText = result.message;
      });
    } on ApiException catch (e) {
      setState(() {
        _isError = true;
        _statusText = e.message;
        _responseText = e.body ?? '';
      });
    } on WalletException catch (e) {
      setState(() {
        _isError = true;
        _statusText = e.message;
      });
    } catch (e) {
      setState(() {
        _isError = true;
        _statusText = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appleSelected = _walletType == 'apple';
    final canNativeAdd = (appleSelected && _walletService.isIos) ||
        (!appleSelected && _walletService.isAndroid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Change API URL',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(_platformHint, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          TextField(
            controller: _cardIdController,
            decoration: const InputDecoration(
              labelText: 'card_id',
              hintText: 'Virtual card UUID',
              border: OutlineInputBorder(),
            ),
            autocorrect: false,
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'apple', label: Text('Apple')),
              ButtonSegment(value: 'google', label: Text('Google')),
            ],
            selected: {_walletType},
            onSelectionChanged: _loading
                ? null
                : (selection) {
                    setState(() => _walletType = selection.first);
                  },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loading ? null : _addToWallet,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wallet),
            label: Text(_loading ? 'Working…' : 'Add to wallet'),
          ),
          if (!canNativeAdd) ...[
            const SizedBox(height: 8),
            Text(
              appleSelected
                  ? 'Native Apple add is disabled on this platform; API response will still be shown.'
                  : 'Native Google add is disabled on this platform; API response will still be shown.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade800,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          ResponsePanel(
            title: _isError ? 'Error' : 'Status',
            content: _statusText,
            isError: _isError,
          ),
          const SizedBox(height: 8),
          ResponsePanel(
            title: 'API response (data)',
            content: _responseText,
            isError: false,
          ),
        ],
      ),
    );
  }
}

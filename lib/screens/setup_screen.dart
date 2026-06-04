import 'package:flutter/material.dart';

import '../config/app_config.dart';
import 'wallet_test_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.config});

  final AppConfig config;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _controller = TextEditingController(
    text: 'http://127.0.0.1:8000',
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    final url = _controller.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Enter the API base URL');
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      setState(() => _error = 'Enter a valid URL (e.g. https://api.example.com)');
      return;
    }

    widget.config.setBaseUrl(url);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => WalletTestScreen(config: widget.config),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet test — setup')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'API base URL',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'https://api.kingzprime.com',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
              onSubmitted: (_) => _continue(),
            ),
            const SizedBox(height: 12),
            Text(
              'JWT loaded from --dart-define=JWT_TOKEN (session only).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            FilledButton(
              onPressed: _continue,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

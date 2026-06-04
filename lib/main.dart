import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'screens/setup_screen.dart';

void main() {
  const jwtToken = String.fromEnvironment('JWT_TOKEN');
  runApp(WalletTestApp(jwtToken: jwtToken));
}

class WalletTestApp extends StatelessWidget {
  const WalletTestApp({super.key, required this.jwtToken});

  final String jwtToken;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KingzPrime Wallet Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: jwtToken.isEmpty
          ? const _MissingTokenScreen()
          : SetupScreen(config: AppConfig(jwtToken: jwtToken)),
    );
  }
}

class _MissingTokenScreen extends StatelessWidget {
  const _MissingTokenScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet test')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: SelectableText(
          'JWT_TOKEN is required.\n\n'
          'Run with:\n'
          'flutter run --dart-define=JWT_TOKEN=\'eyJ...\'',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

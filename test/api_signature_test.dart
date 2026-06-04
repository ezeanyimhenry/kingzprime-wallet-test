import 'package:kingzprime_wallet_test/services/api_signature.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiSignature', () {
    test('builds param string matching PHP middleware', () {
      final paramString = ApiSignature.buildParamString({
        'card_id': 'abc-123',
        'include_pass_base64': true,
        'wallet_type': 'apple',
      });

      expect(
        paramString,
        'card_id=abc-123&include_pass_base64=true&wallet_type=apple',
      );
    });

    test('signs with timestamp and jwt', () {
      final signature = ApiSignature.sign(
        params: {
          'card_id': 'test',
          'wallet_type': 'google',
        },
        timestamp: '1700000000',
        jwt: 'token123',
      );

      expect(signature, isNotEmpty);
      expect(signature.length, 64);
    });

    test('empty params for GET download signing', () {
      expect(ApiSignature.buildParamString({}), '');
      final signature = ApiSignature.sign(
        params: {},
        timestamp: '1700000000',
        jwt: 'token123',
      );
      expect(signature, isNotEmpty);
    });
  });
}

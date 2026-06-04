# KingzPrime Wallet Test App

Minimal Flutter harness to manually test `POST /api/v1/user/virtual-cards/add-to-wallet` against the KingzPrime API and add passes to Apple Wallet (iOS) or Google Wallet (Android).

## Prerequisites

- Flutter SDK
- Physical **iPhone** for Apple Wallet (PassKit is unreliable on the simulator)
- Physical **Android** device with Google Wallet for native Google save
- KingzPrime API with wallet features enabled ([`WALLET_SETUP_GUIDE.md`](../kingzprime-api/WALLET_SETUP_GUIDE.md) in the API repo)
- A valid JWT for a user who owns the virtual card

## Get a JWT

1. Log in through your normal app or API auth flow.
2. If the user has 2FA enabled, complete 2FA so the JWT includes `2fa_passed: true`. Tokens without that claim receive `403` with `"2FA verification required"`.
3. Copy the bearer token (without the `Bearer ` prefix).

## Get a `card_id`

- Call `GET {baseUrl}/api/v1/user/virtual-cards/list` with the same auth headers, or
- Use a card UUID from your database / admin tools.

The card must belong to the JWT user.

## Run the app

```bash
cd /Users/henryezeanyim/development/kingzprime-wallet-test
flutter run --dart-define=JWT_TOKEN='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
```

1. Enter the API base URL (e.g. `https://api.kingzprime.com` or `http://127.0.0.1:8000`) — no trailing path, session only.
2. Enter `card_id`, choose **Apple** or **Google**, tap **Add to wallet**.

## API details

- **Endpoint:** `POST {baseUrl}/api/v1/user/virtual-cards/add-to-wallet`
- **Body:** `card_id`, `wallet_type` (`apple` | `google`), `include_pass_base64: true` for Apple
- **Headers:** `Authorization: Bearer {jwt}`, `X-API-Timestamp`, `X-API-Signature` (SHA-256 of sorted body params + timestamp + jwt)

The route is throttled to **5 requests per minute** — avoid rapid taps.

## Platform behavior

| Platform | Apple | Google |
|----------|-------|--------|
| iOS | Adds `.pkpass` via PassKit | API response shown; use Android for native add |
| Android | API response shown | `savePassesJwt` or opens `add_to_wallet_url` |

**Apple:** Uses `pass_base64` when present; otherwise downloads `download_url` with signed GET.

**Google:** Uses `google_wallet` plugin when available; falls back to opening `add_to_wallet_url` in the browser.

## Troubleshooting

| Symptom | Likely cause |
|---------|----------------|
| Missing API signature / timestamp | Should not happen in this app; check clock skew (>5 min) |
| Invalid signature | Body keys/values must match what is signed |
| 2FA verification required | Use a post-2FA JWT |
| Card not found | Wrong `card_id` or card owned by another user |
| 503 wallet not enabled | `APPLE_WALLET_ENABLED` / `GOOGLE_WALLET_ENABLED` on API |
| PassKit not available | Use a physical iPhone |
| Google Wallet unavailable | Install Google Wallet; check device / Play Services |

## Tests

```bash
flutter test
```

Signature tests verify param string ordering and bool normalization match the Laravel `VerifyApiSignature` middleware.

## Project layout

```
lib/
  config/app_config.dart
  services/api_signature.dart
  services/api_client.dart
  services/wallet_service.dart
  screens/setup_screen.dart
  screens/wallet_test_screen.dart
  widgets/response_panel.dart
  main.dart
```

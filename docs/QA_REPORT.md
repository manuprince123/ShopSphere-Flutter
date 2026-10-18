# Android release QA

Verified on 18 October 2026. This report separates manual release-app checks from automated checks that use a dedicated test entry point.

## Release artifact

- File: `release/ShopSphere_Manu_R_v1.0.0.apk` (local build artifact; excluded from Git).
- Size: 53,866,410 bytes (53.9 MB decimal).
- SHA-256: `464415f45b867bf4566cd13c3762cb1f58f1691257d24ec11eaf156a10030b62`.
- Package: `com.example.shopsphere`; version `1.0.0`, build `1`.
- Minimum Android API: 26; target API: 36; Internet permission present.
- `apksigner verify --verbose`: verification passes using APK Signature Scheme v2.
- Build: `flutter build apk --release`, using Flutter 3.47.7 / Dart 3.13.5.
- Signing: local Android debug key in a release-mode APK, as disclosed in the README. No key is committed. Production signing-key management is outside this assignment demo.

## Devices and layouts

Both are Android 8.0 / API 26 Google APIs ARM64 emulators. No physical-device or newer-Android-version claim is made.

| Device | Display | Checks |
| --- | --- | --- |
| Phone | 1080×1920 px, 420 dpi (about 411×731 dp) | Portrait two-column catalogue and bottom navigation; landscape navigation rail; 1.0× and 1.3× system text; offline error scroll and retry |
| Pixel C tablet | 2560×1800 px, 320 dpi (1280×900 dp) | Landscape master-detail and navigation rail; rotated portrait three-column grid; 1.0× and 1.3× system text |

The final APK was installed successfully on both emulators and launched after installation. Tablet screenshots were recaptured from that final APK. Normal phone flow captures precede only the shared error/empty-state scrolling fix; final large-text/recovery captures include it.

## Manual release-app checks

| Check | Observed result |
| --- | --- |
| Cold launch and valid login | Login rendered; public `emilys` account signed in; products and category chips loaded |
| Product details | Real product image, title, price/discount, stock, description and customer reviews rendered; quantity changed from one to two |
| Cart and badge | Adding two units showed quantity two and badge two; subtotal $19.98, discount $2.09, total $17.89 |
| Restart persistence | Force-stop/relaunch restored the session and the two-unit cart |
| Checkout | DummyJSON simulated order #209 returned; confirmation appeared and cart badge cleared |
| Profile | `/auth/me` data displayed the avatar, Emily Johnson, email and phone |
| Search/category | `phone` produced 23 search results; Beauty and Fragrances each produced five products |
| Session expiry | Tablet restart after the token expired returned to login with an explanatory session-expired message; sign-in recovered |
| Airplane mode | Wi-Fi disabled and airplane mode enabled; Android reported no active default network; requesting a new category displayed offline feedback |
| Offline retry/recovery | Retry remained reachable after scrolling in phone landscape at 1.3× text; after restoring connectivity, retry loaded the five Fragrances products |
| Responsive layouts | Reviewed phone/tablet portrait and landscape captures; tablet product selection populated the adjacent detail pane; enlarged text retained reachable controls |

Pagination, sorting permutations, out-of-stock behavior, model parsing, repository failures and controller transitions also have automated coverage. This report does not label every possible product and device combination as manually verified.

## Live HTTP error scenarios

`integration_test/live_api_test.dart` ran successfully on the API 26 phone in a debug integration build. It renders the real app and uses actual Dio, secure storage, repositories and controllers. Test-only routing sends a catalogue request to `/http/500`, navigates to product 9999, and adds delay parameters. Responses are not mocked. These hooks are absent from the delivered release entry point.

| Scenario | Verified response and UI |
| --- | --- |
| Invalid login | `POST /auth/login` returned 400; inline “Invalid username or password.” |
| Server error | `GET /http/500` returned 500; friendly error and retry; subsequent normal request recovered |
| Not found | `GET /products/9999` returned 404; “Product not found” and working app-bar back action |
| Slow network | `GET /products?limit=20&skip=0&delay=3000`; skeleton visible during delay; real products appeared after 3,721 ms in this run |
| Timeout | `delay=5000` with a test-only 500 ms receive timeout; typed timeout and retry UI; normal retry recovered |
| Unauthorized | Invalid token in secure storage caused real `/auth/me` 401; UI returned to login with session-expired text and both tokens/cart were cleared |
| Bad refresh token | Not an app flow: automatic token refresh is an unimplemented optional bonus. 403-to-unauthorized mapping has unit coverage |

Evidence: [request/results JSON](live-api-results.json) and [screenshots](../screenshots/README.md). No access or refresh token is written to the result JSON.

## Bugs found and fixed during device QA

1. **Release startup crash:** Android R8 renamed Kotlin coroutine/runtime types referenced by the shared-preferences JNI bindings. Added targeted keep rules in `android/app/proguard-rules.pro`; rebuilt, reinstalled, and verified login, cart persistence and restart.
2. **Short-screen error actions:** Error/empty columns could extend beyond the available landscape height. Made the state views scrollable, added two regression tests, and checked the final APK's landscape retry button at 1.3× text.

The emulator environment temporarily lost DNS resolution. Host HTTPS and emulator IP connectivity still worked. Restarting the test AVDs with `-dns-server 8.8.8.8,1.1.1.1` restored name resolution; the live suite subsequently passed.

## Automated checks and reproduction

```sh
flutter analyze
flutter test --coverage
flutter drive --driver=test_driver/live_api_test.dart --target=integration_test/live_api_test.dart -d <android-device-id> --debug
flutter build apk --release
adb -s <android-device-id> install -r build/app/outputs/flutter-apk/app-release.apk
adb -s <android-device-id> shell am start -n com.example.shopsphere/.MainActivity
```

Use a test device for the integration scenario: it clears this app's tokens/cart and intentionally replaces them with invalid values for the expiry check. Build with the default pub step when switching from integration to release so generated plugin registration matches the build mode.

- Analysis: zero issues.
- Unit/widget suite: 59 passed.
- Coverage: 932 / 1,147 measured lines, 81.3%.
- Live Android integration scenario: passed, with seven recorded checks and six captured states.
- Capture inventory: eight phone images, two tablet images, six integration-test images.

## Remaining submission work

The local APK, device QA and screenshots requested in this work are complete. A 2–4 minute demo video, repository publication, GitHub Release `v1.0.0` attachment, Drive upload/sharing, incognito link verification, author contact details and submission email remain. None are claimed completed by this report.

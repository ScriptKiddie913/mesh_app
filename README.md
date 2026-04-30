# Mesh Chat - Offline P2P Mesh Messaging

Production-ready Flutter Android app for offline chat using Bluetooth BLE discovery + WiFi/Bluetooth P2P mesh networking. Like Bridgefy/BitChat. No internet/server.

## Features
- Auto peer discovery (BLE beacons)
- Multi-hop message relay (TTL 7 hops)
- E2E encryption (RSA key exchange + AES)
- Text + image messaging (compressed)
- Dark theme UI
- Background operation (foreground service)

## Project Structure
```
clean arch MVVM:
lib/
  models/ (Message, Peer, KeyPair)
  services/ (crypto, storage, ble, nearby, mesh)
  ui/screens/ (onboarding, peers, chat)
  utils/
android/ (perms, gradle config)
```

## Setup & Build APK (WSL Ubuntu or Windows)

### Option 1: WSL Ubuntu (recommended)
1. Complete active terminal sudo pass for `snap install flutter --classic`
2. `cd /mnt/c/Users/KIIT/Downloads/apker1`
3. `flutter doctor` (install Android SDK if prompted)
4. `flutter pub get`
5. `flutter pub run build_runner build` (generate .g.dart)
6. `flutter build apk --release`

### Option 2: Windows Flutter
1. Download: https://docs.flutter.dev/get-started/install/windows
2. Extract to C:\flutter, add bin to PATH
3. Install Android Studio + SDK (API 34)
4. `cd c:/Users/KIIT/Downloads/apker1`
5. `flutter pub get`
6. `flutter pub run build_runner build`
7. `flutter build apk --release`

### Create local.properties (Android SDK path)
```
sdk.dir=C:\\Users\\KIIT\\AppData\\Local\\Android\\Sdk
flutter.sdk=C:\\flutter
```

## Test
1. Install `build/app/outputs/flutter-apk/app-release.apk` on 2+ Android phones (API 21+)
2. Enable Bluetooth, Location perms
3. Open app → set username → grant perms
4. Devices discover each other → tap peer → send text/image
5. Test multi-hop: 3+ devices chain

## Permissions Explained
- **Bluetooth**: P2P communication
- **Location**: BLE scanning (OS requirement)
- **Nearby WiFi**: High-bandwidth P2P

## Tech Stack
- Flutter 3.16+
- nearby_connections (P2P)
- flutter_blue_plus (BLE discovery)
- hive (local DB)
- pointycastle (RSA E2E crypto)
- image_picker/compress

## Limitations (Android OS)
- Background scanning limited (foreground service used)
- iOS not supported (Nearby API Android-only)
- Large groups: TTL prevents loops

Enjoy offline mesh chatting! 🚀


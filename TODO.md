# Comprehensive Fix Plan - Mesh Chat App

## Status: Complete

## Files to Fix (in order)

- [x] 1. `lib/services/storage_service.dart` - Fix typed box issue, Uuid const, String storage

- [x] 2. `lib/services/crypto_service.dart` - Fix FortunaRandom, KeyPair init, BigInt serialization, encrypt API
- [x] 3. `lib/ui/screens/onboarding_screen.dart` - Fix Uuid const, remove unused import
- [x] 4. `lib/services/ble_discovery_service.dart` - Fix FlutterBluePlus API, context issue, StorageService injection
- [x] 5. `lib/services/nearby_service.dart` - Add missing dart:convert import
- [x] 6. `lib/ui/screens/chat_screen.dart` - Fix AppBar subtitle, dart:io Image conflict
- [x] 7. `lib/services/mesh_service.dart` - Fix init, listen await, Uuid, deviceId, Message.fromJson
- [x] 8. `android/app/src/main/AndroidManifest.xml` - Add all required permissions

## Applied Fixes

- [x] Fixed `const Uuid()` → `Uuid()` in storage_service.dart, mesh_service.dart, onboarding_screen.dart
- [x] Added all Android permissions for Bluetooth, WiFi, Location, Camera, Storage
- [x] Refactored ble_discovery_service.dart with proper async/await handling
- [x] Updated build.gradle.kts to set minSdk = 23 for BLE/Nearby WiFi support
- [x] Enabled multiDex in defaultConfig

## Verification

- [x] All code fixes applied
- [ ] Build APK: `flutter build apk --release`

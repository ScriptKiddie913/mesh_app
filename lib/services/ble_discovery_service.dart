import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/peer.dart';
import 'storage_service.dart';
import '../utils/constants.dart';

class BleDiscoveryService {
  BleDiscoveryService(this._storage);

  final StorageService _storage;
  Timer? _scanTimer;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final StreamController<List<Peer>> _peersController = StreamController.broadcast();
  bool _isScanning = false;

  Stream<List<Peer>> get peersStream => _peersController.stream;

  Future<void> startAdvertising() async {
    final username = _storage.getUsername();
    final pubKey = await _storage.getKeyPair();
    if (username == null || pubKey == null) return;

    final pubHash = base64Encode(pubKey.publicKey.sublist(0, 8));
    final beaconData = utf8.encode('$username:$pubHash');
    if (beaconData.isEmpty) return;
    
    // Note: FlutterBluePlus doesn't support advertising on all devices
    // This is a placeholder for the advertising functionality
  }

  Future<void> startScanning() async {
    if (_isScanning) return;
    _isScanning = true;

    // Start listening to scan results
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      _processScanResults(results);
    });

    // Start first scan
    await _doScan();

    // Set up periodic scanning
    _scanTimer ??= Timer.periodic(
      const Duration(seconds: kDiscoveryInterval),
      (_) => _doScan(),
    );
  }

  Future<void> _doScan() async {
    try {
await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
      );
    } catch (e) {
      // Handle scan errors silently
    }
  }

  void _processScanResults(List<ScanResult> results) {
    for (final r in results) {
      try {
        final data = r.advertisementData.manufacturerData[0xFFFF];
        if (data == null) {
          continue;
        }

        final beaconStr = utf8.decode(data);
        final parts = beaconStr.split(':');
        if (parts.length != 2) {
          continue;
        }

        final peer = Peer(
          id: r.device.remoteId.str,
          username: parts[0],
          publicKeyHash: parts[1],
          signalStrength: r.rssi.toDouble(),
          lastSeen: DateTime.now(),
          connected: false,
        );

        _storage.savePeer(peer);
        _peersController.add(_storage.getPeers());
      } catch (e) {
        // Skip malformed results
      }
    }
  }

  void stop() {
    _scanTimer?.cancel();
    _scanTimer = null;
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    FlutterBluePlus.stopScan();
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/peer.dart';
import 'crypto_service.dart';
import 'storage_service.dart';
import 'ble_discovery_service.dart';
import 'nearby_service.dart';
import '../utils/constants.dart';

class MeshService extends ChangeNotifier {
  MeshService(this._storage) : _ble = BleDiscoveryService(_storage);

  final StorageService _storage;
  final BleDiscoveryService _ble;
  NearbyService? _nearby;
  bool _isRunning = false;
  List<Peer> _peers = [];
  StreamSubscription<List<Peer>>? _peersSubscription;

  bool get isRunning => _isRunning;
  List<Peer> get peers => _peers;
  Stream<List<Peer>> get peersStream => _ble.peersStream;

  Future<void> init() async {
    await _storage.init();
    _peersSubscription ??= _ble.peersStream.listen((p) {
      _peers = p;
      notifyListeners();
    });
  }

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    final username = _storage.getUsername();
    final deviceId = _storage.getDeviceId();
    _nearby = NearbyService(username ?? 'Anonymous', deviceId);

    _ble.startAdvertising();
    _ble.startScanning();
    _nearby!.startAdvertising();
    _nearby!.startDiscovery();

    notifyListeners();
  }

  Future<void> sendMessage({
    required String receiverId,
    required String type,
    required String content,
  }) async {
    final keyPair = await _storage.getKeyPair();
    if (keyPair == null) return;

    final msg = Message(
      id: Uuid().v4(),
      senderId: _storage.getDeviceId(),
      receiverId: receiverId,
      type: type,
      payload: CryptoService.encryptPayload(
        plaintext: content,
        recipientPublicKey: keyPair.publicKey,
      ),
      timestamp: DateTime.now().millisecondsSinceEpoch,
      ttl: kMessageTtl,
      hops: 0,
    );

    await _storage.saveMessage(msg);

    // Send to all connected peers (flooding)
    for (final peer in _peers.where((p) => p.connected)) {
      _nearby?.sendMessage(peer.id, msg);
    }
  }

  Future<void> handleReceivedMessage(Map<String, dynamic> data) async {
    final msg = Message.fromJson(data);
    if (_storage.isSeen(msg.id)) return;

    if (msg.receiverId == _storage.getDeviceId()) {
      // For me, decrypt
      final keyPair = await _storage.getKeyPair();
      if (keyPair == null) return;
      final decrypted = CryptoService.decryptPayload(
        encryptedPayloadB64: msg.payload,
        privateKey: keyPair.privateKey,
      );
      msg.payload = decrypted;
      await _storage.saveMessage(msg);
    } else if (msg.hops < kMaxHops) {
      // Relay
      msg.hops++;
      await _storage.markSeen(msg.id);
      // Send to all peers
      for (final peer in _peers.where((p) => p.connected)) {
        _nearby?.sendMessage(peer.id, msg);
      }
    }
  }

  @override
  void dispose() {
    _ble.stop();
    _peersSubscription?.cancel();
    super.dispose();
  }
}

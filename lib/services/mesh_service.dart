import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/peer.dart';
import '../models/enums.dart';
import 'storage_service.dart';
import 'nearby_service.dart';
import 'crypto_service.dart';
import 'location_service.dart';
import '../utils/constants.dart';

class MeshService extends ChangeNotifier {
  MeshService(this._storage) {
    _location = LocationService(this);
  }

  final StorageService _storage;
  late final LocationService _location;
  LocationService get locationService => _location;
  NearbyService? _nearby;
  bool _isRunning = false;
  bool _isScanning = false;
  String? _error;
  final Map<String, Peer> _discoveredPeers = {};

  final Map<String, String> _endpointToDeviceId = {};
  final Map<String, String> _deviceIdToEndpoint = {};

  bool get isRunning => _isRunning;
  bool get isScanning => _isScanning;
  String? get error => _error;
  List<Peer> get peers => _discoveredPeers.values.toList()
    ..sort((a, b) => b.signalStrength.compareTo(a.signalStrength));

  Future<void> init() async {
    await _storage.init();
    for (final p in _storage.getPeers()) {
      _discoveredPeers[p.id] = p;
    }
  }

  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
    ].request();
    return (statuses[Permission.location]?.isGranted ?? false) ||
        (statuses[Permission.locationWhenInUse]?.isGranted ?? false);
  }

  Future<void> start() async {
    _error = null;
    notifyListeners();

    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        _error = 'Location permission required for mesh networking';
        notifyListeners();
        return;
      }

      final username = _storage.getUsername() ?? 'Anonymous';
      final deviceId = _storage.getDeviceId();

      await _nearby?.stop();

      _nearby = NearbyService(
        userName: username,
        deviceId: deviceId,
        onPeerFound: _handlePeerFound,
        onPeerConnected: _handlePeerConnected,
        onPeerDisconnected: _handlePeerDisconnected,
        onMessageReceived: _handleMessageReceived,
        onPeerLost: _handlePeerLost,
      );

      await _nearby!.startAdvertising();
      await _nearby!.startDiscovery();
      await _location.startLocationSharing();

      _isRunning = true;
      _isScanning = true;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Mesh start failed: $e';
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _nearby?.stop();
    _location.stop();
    _isRunning = false;
    _isScanning = false;
    notifyListeners();
  }

  Future<void> connectToPeer(Peer peer) async {
    final endpointId = _deviceIdToEndpoint[peer.id];
    if (endpointId != null) {
      await _nearby?.connectToPeer(endpointId);
    }
  }

  void _handlePeerFound(String endpointId, String name) {
    final parts = name.split(':');
    final deviceId = parts[0];
    final username = parts.length > 1 ? parts.sublist(1).join(':') : name;

    _endpointToDeviceId[endpointId] = deviceId;
    _deviceIdToEndpoint[deviceId] = endpointId;

    final existing = _discoveredPeers[deviceId];
    if (existing != null) {
      existing.username = username;
      existing.lastSeen = DateTime.now();
      _storage.savePeer(existing);
    } else {
      final peer = Peer(
        id: deviceId,
        username: username,
        publicKeyHash: '',
        signalStrength: -50,
        lastSeen: DateTime.now(),
        connected: false,
      );
      _discoveredPeers[deviceId] = peer;
      _storage.savePeer(peer);
    }
    notifyListeners();
  }

  void _handlePeerConnected(String endpointId) async {
    final deviceId = _endpointToDeviceId[endpointId];
    if (deviceId == null) return;

    final existing = _discoveredPeers[deviceId];
    if (existing != null) {
      existing.connected = true;
      existing.lastSeen = DateTime.now();
      _storage.savePeer(existing);
      notifyListeners();

      final keyPair = await _storage.getKeyPair();
      if (keyPair != null) {
        await _nearby?.sendMessage(endpointId, {
          'id': const Uuid().v4(),
          'senderId': _storage.getDeviceId(),
          'receiverId': deviceId,
          'type': 'key_exchange',
          'payload': base64Encode(keyPair.publicKey),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'ttl': kMessageTtl,
          'hops': 0,
        });
      }
    }
  }

  void _handlePeerDisconnected(String endpointId) {
    final deviceId = _endpointToDeviceId[endpointId];
    if (deviceId == null) return;

    final existing = _discoveredPeers[deviceId];
    if (existing != null) {
      existing.connected = false;
      _storage.savePeer(existing);
      notifyListeners();
    }
  }

  void _handlePeerLost(String? endpointId) {
    if (endpointId != null) {
      _handlePeerDisconnected(endpointId);
      final deviceId = _endpointToDeviceId.remove(endpointId);
      if (deviceId != null) {
        _deviceIdToEndpoint.remove(deviceId);
        notifyListeners();
      }
    }
  }

  void _handleMessageReceived(String endpointId, Map<String, dynamic> data) async {
    try {
      if (data['type'] == 'location_update') {
        _handleLocationUpdate(endpointId, data);
        return;
      }

      final msg = Message.fromJson(data);
      if (_storage.isSeen(msg.id)) return;

      if (msg.type == 'key_exchange') {
        _storage.markSeen(msg.id);
        final existing = _discoveredPeers[msg.senderId];
        if (existing != null) {
          existing.publicKeyHash = msg.payload;
          _storage.savePeer(existing);
          notifyListeners();
        }
      } else {
        final isForUs = msg.receiverId == _storage.getDeviceId() || msg.receiverId.isEmpty;
        if (isForUs) {
          if (msg.type == 'text' || msg.type == 'image') {
            final keyPair = await _storage.getKeyPair();
            if (keyPair != null) {
              msg.payload = CryptoService.decryptPayload(
                encryptedPayloadB64: msg.payload,
                privateKey: keyPair.privateKey,
              );
            }
          }
          _storage.saveMessage(msg);
          notifyListeners();
        } else {
          _storage.markSeen(msg.id);
        }
      }

      if (msg.hops < kMaxHops && (msg.type == 'text' || msg.type == 'image')) {
        msg.hops++;
        final relayData = msg.toJson();
        for (final peerId in _nearby?.connectedEndpoints ?? <String>{}) {
          if (peerId != endpointId) {
            _nearby?.sendMessage(peerId, relayData);
          }
        }
      }
    } catch (e) {
      debugPrint('[MeshService] Message error: $e');
    }
  }

  void _handleLocationUpdate(String endpointId, Map<String, dynamic> data) {
    try {
      final content = data['payload']?.toString();
      if (content == null || !content.contains(',')) return;
      final coords = content.split(',');
      final lat = double.tryParse(coords[0]);
      final lng = double.tryParse(coords[1]);
      if (lat == null || lng == null) return;
      final deviceId = _endpointToDeviceId[endpointId];
      if (deviceId != null) {
        final peer = _discoveredPeers[deviceId];
        if (peer != null) {
          peer.latitude = lat;
          peer.longitude = lng;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> sendMessage({
    required String receiverId,
    required String type,
    required String content,
    MessagePriority priority = MessagePriority.normal,
  }) async {
    String finalPayload = content;
    if ((type == 'text' || type == 'image') && receiverId.isNotEmpty) {
      final peer = _discoveredPeers[receiverId];
      if (peer != null && peer.publicKeyHash.isNotEmpty) {
        try {
          final pubKeyBytes = base64Decode(peer.publicKeyHash);
          finalPayload = CryptoService.encryptPayload(
            plaintext: content,
            recipientPublicKey: pubKeyBytes,
          );
        } catch (_) {}
      }
    }

    final msg = Message(
      id: const Uuid().v4(),
      senderId: _storage.getDeviceId(),
      receiverId: receiverId,
      type: type,
      payload: finalPayload,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      ttl: kMessageTtl,
      hops: 0,
      priorityIndex: priority.index,
    );

    if (type == 'text' || type == 'image') {
      final localMsg = Message(
        id: msg.id,
        senderId: msg.senderId,
        receiverId: msg.receiverId,
        type: msg.type,
        payload: content,
        timestamp: msg.timestamp,
        ttl: msg.ttl,
        hops: msg.hops,
        priorityIndex: msg.priorityIndex,
      );
      await _storage.saveMessage(localMsg);
    }

    final data = msg.toJson();
    if (receiverId.isEmpty) {
      await _nearby?.sendToAll(data);
    } else {
      final endpointId = _deviceIdToEndpoint[receiverId];
      if (endpointId != null) {
        await _nearby?.sendMessage(endpointId, data);
      } else {
        await _nearby?.sendToAll(data);
      }
    }
  }

  @override
  void dispose() {
    _nearby?.stop();
    _location.stop();
    super.dispose();
  }
}

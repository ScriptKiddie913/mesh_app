import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/message.dart';
import '../models/peer.dart';
import 'storage_service.dart';
import 'nearby_service.dart';
import 'crypto_service.dart';
import '../utils/constants.dart';

class MeshService extends ChangeNotifier {
  MeshService(this._storage);

  final StorageService _storage;
  NearbyService? _nearby;
  bool _isRunning = false;
  bool _isScanning = false;
  String? _error;
  final Map<String, Peer> _discoveredPeers = {};

  // Maps temporary endpointId to persistent deviceId and vice versa
  final Map<String, String> _endpointToDeviceId = {};
  final Map<String, String> _deviceIdToEndpoint = {};

  bool get isRunning => _isRunning;
  bool get isScanning => _isScanning;
  String? get error => _error;
  List<Peer> get peers => _discoveredPeers.values.toList()
    ..sort((a, b) => b.signalStrength.compareTo(a.signalStrength));

  Future<void> init() async {
    await _storage.init();
    // Load previously saved peers
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

      _isRunning = true;
      _isScanning = true;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Mesh start failed: $e';
      debugPrint('[MeshService] Start error: $e');
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _nearby?.stop();
    _isRunning = false;
    _isScanning = false;
    notifyListeners();
  }

  Future<void> connectToPeer(Peer peer) async {
    final endpointId = _deviceIdToEndpoint[peer.id];
    if (endpointId != null) {
      await _nearby?.connectToPeer(endpointId);
    } else {
      debugPrint('[MeshService] No endpoint found for peer ${peer.id}');
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

  final Map<String, LatLng> _peerLocations = {};
  bool _isSharingLocation = false;
  Timer? _locationTimer;

  bool get isSharingLocation => _isSharingLocation;
  Map<String, LatLng> get peerLocations => Map.unmodifiable(_peerLocations);

  void toggleLocationSharing(bool share) {
    _isSharingLocation = share;
    notifyListeners();
    if (share) {
      _startLocationBroadcast();
    } else {
      _locationTimer?.cancel();
      // Broadcast stop signal
      sendMessage(receiverId: '', type: 'stop_location', content: '');
    }
  }

  void _startLocationBroadcast() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!_isSharingLocation) {
        timer.cancel();
        return;
      }
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await sendMessage(
          receiverId: '',
          type: 'location',
          content: '${pos.latitude},${pos.longitude}',
        );
      } catch (_) {}
    });
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

      // Key Exchange
      final keyPair = _storage.getKeyPair();
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
    _peerLocations.remove(deviceId);
    notifyListeners();
  }

  void _handlePeerLost(String? endpointId) {
    if (endpointId != null) {
      _handlePeerDisconnected(endpointId);
      final deviceId = _endpointToDeviceId.remove(endpointId);
      if (deviceId != null) {
        _deviceIdToEndpoint.remove(deviceId);
        _peerLocations.remove(deviceId);
        notifyListeners();
      }
    }
  }

  void _handleMessageReceived(String endpointId, Map<String, dynamic> data) async {
    try {
      final msg = Message.fromJson(data);
      if (_storage.isSeen(msg.id)) return;

      // Handle system messages (Key Exchange, Location)
      if (msg.type == 'key_exchange') {
        _storage.markSeen(msg.id);
        final existing = _discoveredPeers[msg.senderId];
        if (existing != null) {
          existing.publicKeyHash = msg.payload; // Store Base64 public key here
          _storage.savePeer(existing);
        }
      } else if (msg.type == 'location') {
        _storage.markSeen(msg.id);
        final parts = msg.payload.split(',');
        if (parts.length == 2) {
          _peerLocations[msg.senderId] = LatLng(double.parse(parts[0]), double.parse(parts[1]));
          notifyListeners();
        }
      } else if (msg.type == 'stop_location') {
        _storage.markSeen(msg.id);
        _peerLocations.remove(msg.senderId);
        notifyListeners();
      } else {
        // Standard payload message
        final isForUs = msg.receiverId == _storage.getDeviceId() || msg.receiverId.isEmpty;
        if (isForUs) {
          // Decrypt if it's E2E encrypted text or image
          if (msg.type == 'text' || msg.type == 'image') {
            final keyPair = _storage.getKeyPair();
            if (keyPair != null) {
              msg.payload = CryptoService.decryptPayload(
                encryptedPayloadB64: msg.payload,
                privateKey: keyPair.privateKey,
              );
            }
          }
          _storage.saveMessage(msg);
        } else {
          _storage.markSeen(msg.id);
        }
      }

      // Relay flooded messages (only text/image, or locations if hops < 2 to prevent network storm)
      if (msg.hops < kMaxHops && (msg.type == 'text' || msg.type == 'image' || msg.type == 'location')) {
        msg.hops++;
        final relayData = msg.toJson();
        for (final peerId in _nearby?.connectedEndpoints ?? <String>{}) {
          if (peerId != endpointId) {
            _nearby?.sendMessage(peerId, relayData);
          }
        }
      }
    } catch (e) {
      debugPrint('[MeshService] Message handling error: $e');
    }
  }

  Future<void> sendMessage({
    required String receiverId,
    required String type,
    required String content,
  }) async {
    String finalPayload = content;

    // Encrypt E2E payload if recipient public key is known
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
    );

    // Save locally unencrypted so sender can see it
    if (type == 'text' || type == 'image') {
      final localMsg = Message(
        id: msg.id,
        senderId: msg.senderId,
        receiverId: msg.receiverId,
        type: msg.type,
        payload: content, // Keep original plaintext for local view
        timestamp: msg.timestamp,
        ttl: msg.ttl,
        hops: msg.hops,
      );
      await _storage.saveMessage(localMsg);
    }

    final data = msg.toJson();

    if (receiverId.isEmpty) {
      // Broadcast (like location)
      await _nearby?.sendToAll(data);
    } else {
      final endpointId = _deviceIdToEndpoint[receiverId];
      if (endpointId != null && _nearby?.connectedEndpoints.contains(endpointId) == true) {
        await _nearby?.sendMessage(endpointId, data);
      } else {
        await _nearby?.sendToAll(data);
      }
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _nearby?.stop();
    super.dispose();
  }
}

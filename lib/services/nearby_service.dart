import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import '../utils/constants.dart';

class NearbyService {
  final String userName;
  final String deviceId;
  final Strategy strategy = Strategy.P2P_CLUSTER;

  final void Function(String endpointId, String endpointName)? onPeerFound;
  final void Function(String endpointId)? onPeerConnected;
  final void Function(String endpointId)? onPeerDisconnected;
  final void Function(String endpointId, Map<String, dynamic> data)? onMessageReceived;
  final void Function(String? endpointId)? onPeerLost;

  final Set<String> _connectedEndpoints = {};

  NearbyService({
    required this.userName,
    required this.deviceId,
    this.onPeerFound,
    this.onPeerConnected,
    this.onPeerDisconnected,
    this.onMessageReceived,
    this.onPeerLost,
  });

  Set<String> get connectedEndpoints => Set.unmodifiable(_connectedEndpoints);

  Future<void> startAdvertising() async {
    try {
      final ok = await Nearby().startAdvertising(
        '$deviceId:$userName',
        strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: kServiceId,
      );
      debugPrint('[NearbyService] Advertising started: $ok');
    } catch (e) {
      debugPrint('[NearbyService] Advertising error: $e');
    }
  }

  Future<void> startDiscovery() async {
    try {
      final ok = await Nearby().startDiscovery(
        '$deviceId:$userName',
        strategy,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
        serviceId: kServiceId,
      );
      debugPrint('[NearbyService] Discovery started: $ok');
    } catch (e) {
      debugPrint('[NearbyService] Discovery error: $e');
    }
  }

  void _onEndpointFound(String id, String name, String serviceId) {
    debugPrint('[NearbyService] Found: $name ($id)');
    onPeerFound?.call(id, name);
  }

  Future<void> connectToPeer(String endpointId) async {
    try {
      await Nearby().requestConnection(
        '$deviceId:$userName',
        endpointId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (e) {
      debugPrint('[NearbyService] requestConnection error: $e');
    }
  }

  void _onEndpointLost(String? id) {
    debugPrint('[NearbyService] Lost: $id');
    if (id != null) _connectedEndpoints.remove(id);
    onPeerLost?.call(id);
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    debugPrint('[NearbyService] Connection initiated: ${info.endpointName}');
    // Make sure we register this peer's device ID mapping from the endpointName
    onPeerFound?.call(id, info.endpointName);
    
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: _onPayloadReceived,
      onPayloadTransferUpdate: (_, __) {},
    );
  }

  void _onConnectionResult(String id, Status status) {
    debugPrint('[NearbyService] Connection result $id: $status');
    if (status == Status.CONNECTED) {
      _connectedEndpoints.add(id);
      onPeerConnected?.call(id);
    } else {
      _connectedEndpoints.remove(id);
    }
  }

  void _onDisconnected(String id) {
    debugPrint('[NearbyService] Disconnected: $id');
    _connectedEndpoints.remove(id);
    onPeerDisconnected?.call(id);
  }

  void _onPayloadReceived(String endpointId, Payload payload) {
    if (payload.bytes == null) return;
    try {
      final jsonStr = utf8.decode(payload.bytes!);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      onMessageReceived?.call(endpointId, data);
    } catch (e) {
      debugPrint('[NearbyService] Payload parse error: $e');
    }
  }

  Future<void> sendMessage(String endpointId, Map<String, dynamic> data) async {
    try {
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(data)));
      await Nearby().sendBytesPayload(endpointId, bytes);
    } catch (e) {
      debugPrint('[NearbyService] Send error: $e');
    }
  }

  Future<void> sendToAll(Map<String, dynamic> data) async {
    for (final id in _connectedEndpoints.toList()) {
      await sendMessage(id, data);
    }
  }

  Future<void> stop() async {
    try {
      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();
      await Nearby().stopAllEndpoints();
      _connectedEndpoints.clear();
    } catch (e) {
      debugPrint('[NearbyService] Stop error: $e');
    }
  }
}

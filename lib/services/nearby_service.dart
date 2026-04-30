import 'dart:typed_data';
import 'dart:convert';
import 'package:nearby_connections/nearby_connections.dart';
import '../models/message.dart';
import 'crypto_service.dart';
import '../utils/constants.dart';

class NearbyService {
  final String userName;
  final String deviceId;
  final Strategy strategy = Strategy.P2P_CLUSTER;

  NearbyService(this.userName, this.deviceId);

  Future<void> startAdvertising() async {
    await Nearby().startAdvertising(
      userName,
      strategy,
      onConnectionInitiated: onConnectionInitiated,
      onConnectionResult: onConnectionResult,
      onDisconnected: onDisconnected,
      serviceId: kAppName,
    );
  }

  Future<void> startDiscovery() async {
    await Nearby().startDiscovery(
      kAppName,
      strategy,
      onEndpointFound: onEndpointFound,
      onEndpointLost: onEndpointLost,
    );
  }

  void onConnectionInitiated(String id, ConnectionInfo info) {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: onPayloadReceived,
      onPayloadTransferUpdate: onPayloadTransferUpdate,
    );
  }

  void onConnectionResult(String id, Status status) {
    if (status == Status.CONNECTED) {
      // Connected
    }
  }

  void onDisconnected(String id) {
    // Disconnected
  }

  void onEndpointFound(String id, String name, String serviceId) {
    Nearby().requestConnection(
      userName,
      id,
      onConnectionInitiated: onConnectionInitiated,
      onConnectionResult: onConnectionResult,
      onDisconnected: onDisconnected,
    );
  }

  void onEndpointLost(String? id) {
    // Lost peer
  }

  void onPayloadTransferUpdate(String id, PayloadTransferUpdate update) {
    // No-op for bytes payloads.
  }

  Future<void> sendMessage(String endpointId, Message msg) async {
    final payload = jsonEncode({
      'id': msg.id,
      'senderId': msg.senderId,
      'receiverId': msg.receiverId,
      'type': msg.type,
      'payload': msg.payload,
      'timestamp': msg.timestamp,
      'ttl': msg.ttl,
      'hops': msg.hops,
    });
    final encrypted = CryptoService.encryptPayload(
      plaintext: payload,
      recipientPublicKey: Uint8List.fromList([]), // get from peer
    );
    await Nearby().sendBytesPayload(endpointId, utf8.encode(encrypted));
  }

  void onPayloadReceived(String id, Payload payload) {
    final bytes = payload.bytes;
    if (bytes != null) {
      // Decrypt or relay
      // Call mesh service handle
    }
  }
}


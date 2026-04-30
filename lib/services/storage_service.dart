import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/peer.dart';
import '../models/key_pair.dart';
import '../utils/constants.dart';

class StorageService extends ChangeNotifier {
  late Box<Message> _messagesBox;
  late Box<Peer> _peersBox;
  late Box<dynamic> _keysBox;

  String? _deviceId;
  late final Future<void> _initFuture;

  StorageService() {
    _initFuture = _init();
  }

  Future<void> init() {
    return _initFuture;
  }

  Future<void> _init() async {
    _messagesBox = Hive.box<Message>(kMessagesBox);
    _peersBox = Hive.box<Peer>(kPeersBox);
    _keysBox = Hive.box<dynamic>(kKeysBox);
    _deviceId = _keysBox.get(kDeviceIdKey) as String?;
    if (_deviceId == null) {
      _deviceId = Uuid().v4();
      await _keysBox.put(kDeviceIdKey, _deviceId);
    }
  }

  String getDeviceId() => _deviceId ?? Uuid().v4();

  // Keys
  Future<KeyPair?> getKeyPair() async {
    return _keysBox.get('keypair') as KeyPair?;
  }

  Future<void> saveKeyPair(KeyPair keyPair, [String? deviceId]) async {
    await _keysBox.put('keypair', keyPair);
    if (deviceId != null) {
      await _keysBox.put(kDeviceIdKey, deviceId);
    }
    notifyListeners();
  }

  String? getUsername() => _keysBox.get(kUsernameKey) as String?;

  Future<void> saveUsername(String username) async {
    await _keysBox.put(kUsernameKey, username);
    notifyListeners();
  }

  // Messages
  List<Message> getMessages({String? peerId}) {
    final all = _messagesBox.values.toList();
    if (peerId == null) return all;
    return all.where((m) => m.senderId == peerId || m.receiverId == peerId).toList();
  }

  Future<void> saveMessage(Message msg) async {
    await _messagesBox.put(msg.id, msg);
    notifyListeners();
  }

  Future<void> markDelivered(String msgId) async {
    final msg = _messagesBox.get(msgId);
    if (msg != null) {
      final updatedMsg = Message(
        id: msg.id,
        senderId: msg.senderId,
        receiverId: msg.receiverId,
        type: msg.type,
        payload: msg.payload,
        timestamp: msg.timestamp,
        ttl: msg.ttl,
        hops: msg.hops,
        delivered: true,
      );
      await _messagesBox.put(msgId, updatedMsg);
      notifyListeners();
    }
  }

  // Peers
  List<Peer> getPeers() => _peersBox.values.toList();

  Future<void> savePeer(Peer peer) async {
    await _peersBox.put(peer.id, peer);
    notifyListeners();
  }

  Future<void> updatePeer(String id, {double? signalStrength, bool? connected}) async {
    final peer = _peersBox.get(id);
    if (peer != null) {
      final updatedPeer = Peer(
        id: peer.id,
        username: peer.username,
        publicKeyHash: peer.publicKeyHash,
        signalStrength: signalStrength ?? peer.signalStrength,
        lastSeen: DateTime.now(),
        connected: connected ?? peer.connected,
      );
      await _peersBox.put(id, updatedPeer);
      notifyListeners();
    }
  }

  // Seen messages for dedup
  bool isSeen(String msgId) => _messagesBox.containsKey(msgId);

  Future<void> markSeen(String msgId) async {
    // Store a marker message
    final markerMsg = Message(
      id: msgId,
      senderId: '',
      receiverId: '',
      type: 'marker',
      payload: '',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      ttl: 0,
      hops: 0,
      delivered: true,
    );
    await _messagesBox.put(msgId, markerMsg);
  }

  // Clear offline queue
  Future<void> clearOfflineQueue() async {
    final keys = _messagesBox.keys.toList();
    for (final key in keys) {
      final msg = _messagesBox.get(key);
      if (msg != null && msg.type == 'queued') {
        await _messagesBox.delete(key);
      }
    }
  }
}

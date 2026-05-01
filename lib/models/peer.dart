import 'package:hive/hive.dart';
part 'peer.g.dart';

@HiveType(typeId: 1)
class Peer extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String username;

  @HiveField(2)
  String publicKeyHash; // sha256(pubkey)

  @HiveField(3)
  double signalStrength;

  @HiveField(4)
  DateTime lastSeen;

  @HiveField(5)
  bool connected;

  @HiveField(6)
  double latitude;

  @HiveField(7)
  double longitude;

  Peer({
    required this.id,
    required this.username,
    required this.publicKeyHash,
    this.signalStrength = -100.0,
    required this.lastSeen,
    this.connected = false,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });
}

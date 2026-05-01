import 'package:hive/hive.dart';

part 'identity.g.dart';

@HiveType(typeId: 3)
class NodeIdentity extends HiveObject {
  @HiveField(0) 
  String deviceId;
  
  @HiveField(1) 
  String displayName;
  
  @HiveField(2) 
  String role;       // 'operator', 'leader', 'relay', 'guest'
  
  @HiveField(3) 
  int trustScore;    // 0-100
  
  @HiveField(4) 
  int messagesRelayed;
  
  @HiveField(5) 
  bool isVerified;
  
  @HiveField(6) 
  int firstSeen;
  
  @HiveField(7) 
  int lastSeen;
  
  @HiveField(8) 
  List<String> endorsedBy; // deviceIds of endorsers

  NodeIdentity({
    required this.deviceId,
    required this.displayName,
    this.role = 'guest',
    this.trustScore = 0,
    this.messagesRelayed = 0,
    this.isVerified = false,
    required this.firstSeen,
    required this.lastSeen,
    List<String>? endorsedBy,
  }) : endorsedBy = endorsedBy ?? [];
}

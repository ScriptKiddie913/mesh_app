import 'enums.dart';

class BroadcastMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final MessagePriority priority;
  final BroadcastZone zone;
  final int timestamp;
  final double? originLat;
  final double? originLng;

  BroadcastMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.priority,
    required this.zone,
    required this.timestamp,
    this.originLat,
    this.originLng,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'priority': priority.index,
      'zone': zone.index,
      'timestamp': timestamp,
      'originLat': originLat,
      'originLng': originLng,
    };
  }

  factory BroadcastMessage.fromJson(Map<String, dynamic> json) {
    return BroadcastMessage(
      id: (json['id'] as String?) ?? '',
      senderId: (json['senderId'] as String?) ?? '',
      senderName: (json['senderName'] as String?) ?? 'Unknown',
      content: (json['content'] as String?) ?? '',
      priority: MessagePriority.values[((json['priority'] as num?)?.toInt() ?? 0).clamp(0, 2)],
      zone: BroadcastZone.values[((json['zone'] as num?)?.toInt() ?? 0).clamp(0, 3)],
      timestamp: (json['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      originLat: (json['originLat'] as num?)?.toDouble(),
      originLng: (json['originLng'] as num?)?.toDouble(),
    );
  }
}

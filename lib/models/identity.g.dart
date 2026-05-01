// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NodeIdentityAdapter extends TypeAdapter<NodeIdentity> {
  @override
  final int typeId = 3;

  @override
  NodeIdentity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NodeIdentity(
      deviceId: fields[0] as String,
      displayName: fields[1] as String,
      role: fields[2] as String,
      trustScore: fields[3] as int,
      messagesRelayed: fields[4] as int,
      isVerified: fields[5] as bool,
      firstSeen: fields[6] as int,
      lastSeen: fields[7] as int,
      endorsedBy: (fields[8] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, NodeIdentity obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.deviceId)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.role)
      ..writeByte(3)
      ..write(obj.trustScore)
      ..writeByte(4)
      ..write(obj.messagesRelayed)
      ..writeByte(5)
      ..write(obj.isVerified)
      ..writeByte(6)
      ..write(obj.firstSeen)
      ..writeByte(7)
      ..write(obj.lastSeen)
      ..writeByte(8)
      ..write(obj.endorsedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeIdentityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

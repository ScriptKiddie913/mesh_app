// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'peer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PeerAdapter extends TypeAdapter<Peer> {
  @override
  final int typeId = 1;

  @override
  Peer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Peer(
      id: fields[0] as String,
      username: fields[1] as String,
      publicKeyHash: fields[2] as String,
      signalStrength: fields[3] as double,
      lastSeen: fields[4] as DateTime,
      connected: fields[5] as bool,
      latitude: fields[6] as double,
      longitude: fields[7] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Peer obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.publicKeyHash)
      ..writeByte(3)
      ..write(obj.signalStrength)
      ..writeByte(4)
      ..write(obj.lastSeen)
      ..writeByte(5)
      ..write(obj.connected)
      ..writeByte(6)
      ..write(obj.latitude)
      ..writeByte(7)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

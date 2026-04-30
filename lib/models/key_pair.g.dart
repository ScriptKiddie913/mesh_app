// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'key_pair.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KeyPairAdapter extends TypeAdapter<KeyPair> {
  @override
  final int typeId = 2;

  @override
  KeyPair read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KeyPair(
      privateKey: fields[0] as Uint8List,
      publicKey: fields[1] as Uint8List,
    );
  }

  @override
  void write(BinaryWriter writer, KeyPair obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.privateKey)
      ..writeByte(1)
      ..write(obj.publicKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyPairAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

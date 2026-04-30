import 'dart:typed_data';
import 'package:hive/hive.dart';
part 'key_pair.g.dart';

@HiveType(typeId: 2)
class KeyPair extends HiveObject {
  @HiveField(0)
  Uint8List privateKey;

  @HiveField(1)
  Uint8List publicKey;

  KeyPair({
    required this.privateKey,
    required this.publicKey,
  });
}


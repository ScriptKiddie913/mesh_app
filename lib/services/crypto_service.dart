import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/export.dart';
import '../models/key_pair.dart';

class CryptoService {
  static final _secureRandom = Random.secure();
  static const int _keySize = 2048;

  /// Generate raw key bytes — safe to call inside compute() isolate
  static Map<String, Uint8List> generateKeyPairRaw(dynamic _) {
    final random = FortunaRandom();
    final seed = Uint8List(32);
    final sr = Random.secure();
    for (int i = 0; i < 32; i++) {
      seed[i] = sr.nextInt(256);
    }
    random.seed(KeyParameter(seed));

    final params = RSAKeyGeneratorParameters(
      BigInt.parse('65537'),
      _keySize,
      64,
    );
    final generator = RSAKeyGenerator();
    generator.init(ParametersWithRandom(params, random));

    final pair = generator.generateKeyPair();
    final publicKey = pair.publicKey as RSAPublicKey;
    final privateKey = pair.privateKey as RSAPrivateKey;

    return {
      'private': _serializeRSAPrivateKey(privateKey),
      'public': _serializeRSAPublicKey(publicKey),
    };
  }

  /// Generate RSA keypair using pointycastle
  static KeyPair generateKeyPair() {
    final random = FortunaRandom();
    final seed = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      seed[i] = _secureRandom.nextInt(256);
    }
    random.seed(KeyParameter(seed));

    final params = RSAKeyGeneratorParameters(
      BigInt.parse('65537'), // public exponent
      _keySize,
      64, // certainty
    );
    final generator = RSAKeyGenerator();
    generator.init(ParametersWithRandom(params, random));

    final pair = generator.generateKeyPair();
    final publicKey = pair.publicKey as RSAPublicKey;
    final privateKey = pair.privateKey as RSAPrivateKey;

    return KeyPair(
      privateKey: _serializeRSAPrivateKey(privateKey),
      publicKey: _serializeRSAPublicKey(publicKey),
    );
  }

  /// Encrypt message payload for recipient public key (RSA + AES hybrid)
  static String encryptPayload({
    required String plaintext,
    required Uint8List recipientPublicKey,
  }) {
    try {
      final aesKey = Key.fromSecureRandom(32); // 256-bit key
      final iv = IV.fromSecureRandom(16);
      final aesEncrypter = Encrypter(AES(aesKey, mode: AESMode.cbc));
      final encryptedPayload = aesEncrypter.encrypt(plaintext, iv: iv);
      final rsaPublicKey = _parseRSAPublicKey(recipientPublicKey);
      final rsaEngine = PKCS1Encoding(RSAEngine())
        ..init(true, PublicKeyParameter<RSAPublicKey>(rsaPublicKey));
      final encryptedAesKey = rsaEngine.process(aesKey.bytes);

      final combined = <String, dynamic>{
        'iv': base64Encode(iv.bytes),
        'ciphertext': encryptedPayload.base64,
        'aesKey': base64Encode(encryptedAesKey),
        'encrypted': true,
      };
      
      return base64Encode(utf8.encode(jsonEncode(combined)));
    } catch (_) {
      return plaintext; // Fallback to plaintext if encryption fails entirely
    }
  }

  /// Decrypt message payload with private key
  static String decryptPayload({
    required String encryptedPayloadB64,
    required Uint8List privateKey,
  }) {
    try {
      final decoded = utf8.decode(base64Decode(encryptedPayloadB64));
      final combined = jsonDecode(decoded) as Map<String, dynamic>;
      
      if (combined['encrypted'] != true) return encryptedPayloadB64;

      final iv = IV.fromBase64(combined['iv'] as String);
      final ciphertext = combined['ciphertext'] as String;
      final encryptedAesKey = base64Decode(combined['aesKey'] as String);
      final rsaPrivateKey = _parseRSAPrivateKey(privateKey);
      final rsaEngine = PKCS1Encoding(RSAEngine())
        ..init(false, PrivateKeyParameter<RSAPrivateKey>(rsaPrivateKey));
      final aesKeyBytes = rsaEngine.process(encryptedAesKey);

      final aesEncrypter = Encrypter(AES(Key(aesKeyBytes), mode: AESMode.cbc));
      return aesEncrypter.decrypt(Encrypted.fromBase64(ciphertext), iv: iv);
    } catch (_) {
      // If any decryption fails, return the original payload so we don't leak JSON
      return encryptedPayloadB64;
    }
  }

  // Serialization helpers
  static Uint8List _serializeRSAPublicKey(RSAPublicKey key) {
    final modulusBytes = _bigIntToBytes(key.modulus!);
    final exponentBytes = _bigIntToBytes(key.exponent!);
    
    final result = BytesBuilder();
    result.add(_encodeLength(modulusBytes.length));
    result.add(modulusBytes);
    result.add(_encodeLength(exponentBytes.length));
    result.add(exponentBytes);
    
    return result.toBytes();
  }

  static Uint8List _serializeRSAPrivateKey(RSAPrivateKey key) {
    final modulusBytes = _bigIntToBytes(key.modulus!);
    final privExpBytes = _bigIntToBytes(key.privateExponent!);
    
    final result = BytesBuilder();
    result.add(_encodeLength(modulusBytes.length));
    result.add(modulusBytes);
    result.add(_encodeLength(privExpBytes.length));
    result.add(privExpBytes);
    
    return result.toBytes();
  }

  static RSAPublicKey _parseRSAPublicKey(Uint8List data) {
    final modulusLength = _decodeLength(data, 0);
    const modulusStart = 4;
    final modulusEnd = modulusStart + modulusLength;
    final exponentLength = _decodeLength(data, modulusEnd);
    const exponentStartOffset = 4;
    final exponentStart = modulusEnd + exponentStartOffset;
    final exponentEnd = exponentStart + exponentLength;

    final modulus = _bytesToBigInt(data.sublist(modulusStart, modulusEnd));
    final exponent = _bytesToBigInt(data.sublist(exponentStart, exponentEnd));

    return RSAPublicKey(modulus, exponent);
  }

  static RSAPrivateKey _parseRSAPrivateKey(Uint8List data) {
    final modulusLength = _decodeLength(data, 0);
    const modulusStart = 4;
    final modulusEnd = modulusStart + modulusLength;
    final privateExponentLength = _decodeLength(data, modulusEnd);
    const privateExponentStartOffset = 4;
    final privateExponentStart = modulusEnd + privateExponentStartOffset;
    final privateExponentEnd = privateExponentStart + privateExponentLength;

    final modulus = _bytesToBigInt(data.sublist(modulusStart, modulusEnd));
    final privateExponent = _bytesToBigInt(
      data.sublist(privateExponentStart, privateExponentEnd),
    );

    return RSAPrivateKey(modulus, privateExponent, null, null);
  }

  static Uint8List _bigIntToBytes(BigInt value) {
    var hex = value.toRadixString(16);
    if (hex.length.isOdd) {
      hex = '0$hex';
    }

    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return bytes;
  }

  static BigInt _bytesToBigInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (final byte in bytes) {
      result = (result << 8) | BigInt.from(byte);
    }
    return result;
  }

  static Uint8List _encodeLength(int length) {
    final bytes = ByteData(4);
    bytes.setUint32(0, length, Endian.big);
    return bytes.buffer.asUint8List();
  }

  static int _decodeLength(Uint8List data, int offset) {
    return ByteData.sublistView(data, offset, offset + 4).getUint32(0, Endian.big);
  }
}

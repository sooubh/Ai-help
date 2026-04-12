import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles all client-side AES encryption and decryption for sensitive data.
class EncryptionService {
  EncryptionService._();

  static final EncryptionService instance = EncryptionService._();

  static const _storage = FlutterSecureStorage();
  static const _keyStorageKey = 'care_ai_aes_key_v1';
  static const _ivStorageKey = 'care_ai_aes_iv_v1';

  encrypt.Key? _key;
  encrypt.IV? _iv;
  encrypt.Encrypter? _encrypter;

  /// Ensures key/IV are available (creates and persists them on first launch).
  Future<void> initialize() async {
    if (_encrypter != null) return;

    final storedKey = await _storage.read(key: _keyStorageKey);
    final storedIv = await _storage.read(key: _ivStorageKey);

    if (storedKey == null || storedIv == null) {
      final random = Random.secure();
      final keyBytes = Uint8List.fromList(
        List<int>.generate(32, (_) => random.nextInt(256)),
      );
      final ivBytes = Uint8List.fromList(
        List<int>.generate(16, (_) => random.nextInt(256)),
      );

      await _storage.write(key: _keyStorageKey, value: base64Encode(keyBytes));
      await _storage.write(key: _ivStorageKey, value: base64Encode(ivBytes));

      _key = encrypt.Key(keyBytes);
      _iv = encrypt.IV(ivBytes);
    } else {
      _key = encrypt.Key(base64Decode(storedKey));
      _iv = encrypt.IV(base64Decode(storedIv));
    }

    _encrypter = encrypt.Encrypter(
      encrypt.AES(_key!, mode: encrypt.AESMode.cbc),
    );
  }

  /// Encrypts plain text and returns a Base64 ciphertext.
  /// Returns the original input for null/empty values.
  String encryptText(String plainText) {
    if (plainText.isEmpty) return plainText;
    if (_encrypter == null || _iv == null) return plainText;

    try {
      return _encrypter!.encrypt(plainText, iv: _iv!).base64;
    } catch (e) {
      throw StateError('Encryption failed: $e');
    }
  }

  /// Decrypts a Base64 ciphertext and returns plain text.
  /// Returns the original input for null/empty values or decryption failures.
  String decryptText(String encryptedText) {
    if (encryptedText.isEmpty) return encryptedText;
    if (_encrypter == null || _iv == null) return encryptedText;

    try {
      return _encrypter!.decrypt64(encryptedText, iv: _iv!);
    } catch (_) {
      return encryptedText;
    }
  }

  /// Encrypts only the provided fields in a map.
  /// Non-string values are JSON-serialized before encryption.
  Map<String, dynamic> encryptMap(
    Map<String, dynamic> data,
    List<String> fieldsToEncrypt,
  ) {
    final encryptedData = Map<String, dynamic>.from(data);

    for (final field in fieldsToEncrypt) {
      if (!encryptedData.containsKey(field) || encryptedData[field] == null) {
        continue;
      }

      final value = encryptedData[field];
      if (value is String) {
        encryptedData[field] = encryptText(value);
      } else {
        encryptedData[field] = encryptText(jsonEncode(value));
      }
    }

    return encryptedData;
  }

  /// Decrypts only the provided fields in a map.
  /// If a decrypted value is JSON, it is converted back to object/list.
  /// Falls back to original value when decryption/parsing fails.
  Map<String, dynamic> decryptMap(
    Map<String, dynamic> data,
    List<String> fieldsToDecrypt,
  ) {
    final decryptedData = Map<String, dynamic>.from(data);

    for (final field in fieldsToDecrypt) {
      if (!decryptedData.containsKey(field) || decryptedData[field] == null) {
        continue;
      }

      final value = decryptedData[field];
      if (value is! String) continue;

      final decryptedValue = decryptText(value);
      if (decryptedValue == value) {
        decryptedData[field] = value;
        continue;
      }

      try {
        decryptedData[field] = jsonDecode(decryptedValue);
      } catch (_) {
        decryptedData[field] = decryptedValue;
      }
    }

    return decryptedData;
  }
}

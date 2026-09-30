import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TasklySecurityService {
  TasklySecurityService._();
  static final instance = TasklySecurityService._();
  static const _lockEnabledKey = 'taskly_security_lock_enabled';
  static const _biometricKey = 'taskly_security_biometric_enabled';
  static const _pinHashKey = 'taskly_security_pin_hash';
  static const _encryptionKey = 'taskly_security_encryption_key';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> isLockEnabled() async => (await SharedPreferences.getInstance()).getBool(_lockEnabledKey) ?? false;
  Future<bool> isBiometricEnabled() async => (await SharedPreferences.getInstance()).getBool(_biometricKey) ?? true;
  Future<void> setLockEnabled(bool value) async => (await SharedPreferences.getInstance()).setBool(_lockEnabledKey, value);
  Future<void> setBiometricEnabled(bool value) async => (await SharedPreferences.getInstance()).setBool(_biometricKey, value);
  Future<bool> hasPin() async => (await _secure.read(key: _pinHashKey)) != null;

  Future<void> setPin(String pin) async {
    final value = pin.trim();
    if (!RegExp(r'^\d{4,8}$').hasMatch(value)) throw const FormatException('PIN must contain 4 to 8 digits.');
    await _secure.write(key: _pinHashKey, value: await _hashPin(value));
  }
  Future<bool> verifyPin(String pin) async => (await _secure.read(key: _pinHashKey)) == await _hashPin(pin.trim());
  Future<void> removePin() async => _secure.delete(key: _pinHashKey);

  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.isDeviceSupported() && (await _localAuth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) { return false; }
  }

  Future<bool> authenticateBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Unlock Taskly Pro to access your private workspace.',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) { return false; }
  }

  Future<String> _getEncryptionKey() async {
    var value = await _secure.read(key: _encryptionKey);
    if (value == null) {
      value = base64UrlEncode(List<int>.generate(32, (_) => Random.secure().nextInt(256)));
      await _secure.write(key: _encryptionKey, value: value);
    }
    return value;
  }

  Future<String> encryptText(String plainText) async {
    final key = enc.Key(base64Url.decode(await _getEncryptionKey()));
    final ivBytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final iv = enc.IV(Uint8List.fromList(ivBytes));
    final encrypted = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc, padding: 'PKCS7')).encrypt(plainText, iv: iv);
    return '${base64UrlEncode(ivBytes)}.${encrypted.base64}';
  }

  Future<String?> decryptText(String payload) async {
    try {
      final parts = payload.split('.');
      if (parts.length != 2) return null;
      final key = enc.Key(base64Url.decode(await _getEncryptionKey()));
      final iv = enc.IV(base64Url.decode(parts[0]));
      return enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc, padding: 'PKCS7')).decrypt64(parts[1], iv: iv);
    } catch (_) { return null; }
  }

  Future<String> _hashPin(String pin) async => sha256.convert(utf8.encode('taskly:$pin:${await _getEncryptionKey()}')).toString();
}

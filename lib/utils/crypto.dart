import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import "package:pointycastle/pointycastle.dart";

Uint8List deriveKey(String password, String salt) {
  final derivator = KeyDerivator('argon2');
  final parameter = Argon2Parameters(
      Argon2Parameters.ARGON2_id, base64Decode(salt),
      desiredKeyLength: 32);

  derivator.init(parameter);

  final digest = derivator.process(Uint8List.fromList(password.codeUnits));

  return digest;
}

String generateSalt(int length) {
  final Random random = Random.secure();

  final digest = List<int>.generate(length, (i) => random.nextInt(256));

  return base64Encode(digest);
}

String deriveHash(Uint8List input) {
  final hash = Digest('SHA-256');

  final digest = hash.process(Uint8List.fromList(input));

  return base64Encode(digest);
}
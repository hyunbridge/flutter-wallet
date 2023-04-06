import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './crypto.dart';
import '../models/card.dart';

class HiveHelper {
  static final HiveHelper _singleton = HiveHelper._internal();

  factory HiveHelper() {
    return _singleton;
  }

  HiveHelper._internal();

  static const _boxName = "cards";
  late Box<Card> _box;

  Future<void> _openBox(Uint8List key) async {
    _box = await Hive.openBox(_boxName, encryptionCipher: HiveAesCipher(key));
  }

  Future<void> init(String password) async {
    late String? salt;
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    salt = prefs.getString("salt");
    if (salt == null) {
      salt = generateSalt(32);
      prefs.setString("salt", salt);

      final key = deriveKey(password, salt);
      final hash = deriveHash(key);
      prefs.setString("keyHash", hash);

      return _openBox(key);
    }

    final key = deriveKey(password, salt);
    final hash = deriveHash(key);

    if (prefs.getString("keyHash") == hash) {
      return _openBox(key);
    } else {
      throw Error();
    }
  }

  Future<int> add(Card card) async {
    return await _box.add(card);
  }

  Future<void> update(dynamic key, Card card) async {
    await _box.put(key, card);
  }

  List<Card> getAll() {
    return _box.values.toList();
  }
}

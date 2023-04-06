import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import './models/card.dart' as card_model;
import './screens/home.dart';

Future<void> main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(card_model.CardAdapter());

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallet',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

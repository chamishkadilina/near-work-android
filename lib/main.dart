import 'package:flutter/material.dart';
import 'package:nearwork/core/navigation/navigation_bar.dart';

void main() {
  runApp(const NearWorkApp());
}

class NearWorkApp extends StatelessWidget {
  const NearWorkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NearWork',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const NavBar(),
    );
  }
}

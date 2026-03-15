import 'package:flutter/material.dart';

void main() {
  runApp(const PersonalityApp());
}

class PersonalityApp extends StatelessWidget {
  const PersonalityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personality',
      home: const Scaffold(
        body: Center(
          child: Text('Personality + Tarot'),
        ),
      ),
    );
  }
}

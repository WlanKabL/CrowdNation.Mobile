import 'package:flutter/material.dart';

class SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Zweite Seite'),
      ),
      body: Center(
        child: Text('Dies ist die zweite Seite.'),
      ),
    );
  }
}

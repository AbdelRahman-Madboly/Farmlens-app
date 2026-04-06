import 'package:flutter/material.dart';

class LogDetailScreen extends StatelessWidget {
  final String cycleId;

  const LogDetailScreen({super.key, required this.cycleId});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Log Detail')),
    );
  }
}
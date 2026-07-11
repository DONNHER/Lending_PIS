import 'package:flutter/material.dart';

class UserGrowthChart extends StatelessWidget {
  final List<dynamic> data;
  const UserGrowthChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 200,
      child: Center(child: Text('User Growth Chart')),
    );
  }
}

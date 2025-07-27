import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const AquaculturePredictionApp());
}

class AquaculturePredictionApp extends StatelessWidget {
  const AquaculturePredictionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aquaculture Trade Predictor',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'src/app.dart';
import 'src/core/di/service_locator.dart';
import 'src/core/logging/log_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Lock orientation to landscape for the game
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Setup Logging
  setupLogging();
  
  // Setup Dependency Injection
  await setupServiceLocator();

  runApp(const SpiritWorldCityApp());
}

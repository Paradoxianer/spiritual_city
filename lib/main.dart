import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'src/app.dart';
import 'src/core/di/service_locator.dart';
import 'src/core/logging/log_config.dart';
import 'src/features/menu/domain/models/app_settings.dart';
import 'src/features/menu/domain/models/game_save.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters (manual – no build_runner needed)
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(GameSaveAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(AppSettingsAdapter());
  }

  // Setup Logging
  setupLogging();

  // Setup Dependency Injection
  await setupServiceLocator();

  runApp(const SpiritWorldCityApp());
}

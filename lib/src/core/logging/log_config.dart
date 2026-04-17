import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

void setupLogging() {
  // CONFIG = show INFO/WARNING/SEVERE but suppress FINE/FINER/FINEST chatter.
  Logger.root.level = kDebugMode ? Level.CONFIG : Level.INFO;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
}

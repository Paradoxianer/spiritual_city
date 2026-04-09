import 'package:logging/logging.dart';

class ErrorHandler {
  static final _log = Logger('ErrorHandler');

  static void handle(Object error, StackTrace stackTrace, {String? context}) {
    final contextStr = context != null ? ' [context: $context]' : '';
    _log.severe('Error$contextStr: $error', error, stackTrace);
  }
}

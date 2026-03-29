import 'dart:async';
import 'package:flutter/foundation.dart';

/// Debouncer cancels previous calls and only fires the action after [delay]
/// has elapsed without another call. ideal for search-as-you-type scenarios.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancel any pending debounced call
  void cancel() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
  }
}

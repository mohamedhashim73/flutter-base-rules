import 'package:flutter/material.dart';
import 'package:base/core/services/base/debouncer.dart';
import 'package:base/core/services/base/safe_executer.dart';

class SearchManager {
  SearchManager({Debouncer? debouncer, String? initialValue})
    : _debouncer = debouncer ?? Debouncer() {
    if (initialValue != null) {
      controller.text = initialValue;
    }
  }

  final TextEditingController controller = TextEditingController();
  final Debouncer _debouncer;

  String get query => controller.text.trim();

  bool get isEmpty => query.isEmpty;

  void onChanged(VoidCallback callback) {
    _debouncer(callback);
  }

  void searchNow(VoidCallback callback) {
    _debouncer.cancel();
    callback();
  }

  void clear() {
    controller.clear();
    _debouncer.cancel();
  }

  void dispose() {
    SafeExecutor.run(() => controller.dispose());
    SafeExecutor.run(() => _debouncer.dispose());
  }
}

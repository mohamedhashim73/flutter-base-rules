part of '../services.dart';

class SafeExecutor {
  const SafeExecutor._();

  static T? run<T>(T Function() action) {
    try {
      return action();
    } catch (_) {
      return null;
    }
  }
}

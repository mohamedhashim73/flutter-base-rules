import 'dart:async';

class Debouncer {
  Debouncer({
    this.delay = const Duration(milliseconds: 500),
  });

  final Duration delay;

  Timer? _timer;

  void call(FutureOr<void> Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, () async {
      await action();
    });
  }

  void cancel() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
  }
}

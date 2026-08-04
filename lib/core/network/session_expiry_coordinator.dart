typedef SessionExpiredCallback = Future<void> Function();

class SessionExpiryCoordinator {
  SessionExpiryCoordinator({
    required this.onSessionExpired,
  });

  final SessionExpiredCallback onSessionExpired;

  Future<void>? _inProgress;
  String? _handledToken;
  bool _handledWithoutToken = false;

  Future<void> handle({
    String? requestToken,
  }) {
    final token = requestToken?.trim();

    if (token != null && token.isNotEmpty) {
      if (_handledToken == token) {
        return Future.value();
      }
    } else {
      if (_handledWithoutToken) {
        return Future.value();
      }
    }

    final currentOperation = _inProgress;

    if (currentOperation != null) {
      return currentOperation;
    }

    if (token != null && token.isNotEmpty) {
      _handledToken = token;
    } else {
      _handledWithoutToken = true;
    }

    final operation = _execute(
      requestToken: token,
    );

    _inProgress = operation;

    return operation;
  }

  Future<void> _execute({
    String? requestToken,
  }) async {
    try {
      await onSessionExpired();
    } catch (_) {
      if (requestToken != null && requestToken.isNotEmpty) {
        _handledToken = null;
      } else {
        _handledWithoutToken = false;
      }

      rethrow;
    } finally {
      _inProgress = null;
    }
  }

  void reset() {
    _handledToken = null;
    _handledWithoutToken = false;
    _inProgress = null;
  }
}
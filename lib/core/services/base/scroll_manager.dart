import 'package:flutter/material.dart';
import 'package:base/core/services/base/safe_executer.dart';

class ScrollManager {
  ScrollController? _controller;
  VoidCallback? _onScroll;
  bool _isListening = false;

  ScrollController? get controller => _controller;

  bool get hasClients => _controller?.hasClients ?? false;
  
  bool get isPaginationReady =>
      hasClients &&
      _controller?.position.maxScrollExtent == _controller?.offset &&
      extentAfter == 0;

  double get extentAfter => _controller?.position.extentAfter ?? 0;

  void init({required VoidCallback onScroll}) {
    _disposeController();
    _controller = ScrollController();
    _onScroll = onScroll;
    _addListener();
  }

  void _addListener() {
    if (_controller != null && !_isListening && _onScroll != null) {
      _controller!.addListener(_onScroll!);
      _isListening = true;
    }
  }

  void _removeListener() {
    if (_controller != null && _isListening && _onScroll != null) {
      _controller!.removeListener(_onScroll!);
      _isListening = false;
    }
  }

  void _disposeController() {
    _removeListener();
    SafeExecutor.run(() => _controller?.dispose());
    _controller = null;
  }

  void dispose() {
    _disposeController();
    _onScroll = null;
  }
}

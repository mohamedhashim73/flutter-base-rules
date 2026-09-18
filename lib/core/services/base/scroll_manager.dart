part of '../services.dart';

class ScrollManager {
  ScrollController? _controller;
  VoidCallback? _onScroll;
  bool _isListening = false;
  bool _isPaging = false;

  ScrollController? get controller => _controller;

  bool get hasClients => _controller?.hasClients ?? false;

  bool get isPaginationReady {
  if (_isPaging) return false;
  if (!hasClients) return false;

  final maxExtent = _controller?.position.maxScrollExtent ?? 0;
  final pixels = _controller?.position.pixels ?? 0;

  // لو القايمة مش بتعمل overflow (كل العناصر ظاهرة على الشاشة)
  // يبقى مفيش داعي ننتظر scroll، نعتبرها جاهزة على طول
  if (maxExtent <= 0) {
    LoggingService.showMsg(
      '[ScrollManager] isPaginationReady → no-overflow case, ready:true',
    );
    return true;
  }

  final ready = pixels >= maxExtent - 80;
  return ready;
}

  void lockPaging() {
    _isPaging = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isPaging = false;
      });
    });
  }

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

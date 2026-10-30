import 'package:flutter/material.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static BuildContext get currentContext => key.currentContext!;
  static String? currentRoute;
  static String? get getCurrentRoute {
    try {
      key.currentState?.popUntil((route) {
        currentRoute = route.settings.name;
        return true;
      });
      return currentRoute;
    } catch (e) {
      return null;
    }
  }

  static void pop<T extends Object?>([T? result]) {
    key.currentState?.pop<T>(result);
  }

  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  /// Tracks the live navigation stack so destination navigation can reuse an
  /// existing page instead of pushing the same destination twice.
  static final List<Route<dynamic>> _stack = <Route<dynamic>>[];

  static final NavigatorObserver stackObserver = _StackObserver();

  static String? get currentRouteName =>
      _stack.isEmpty ? null : _stack.last.settings.name;

  static bool hasRouteNamed(String name) =>
      _stack.any((route) => route.settings.name == name);

  static dynamic push(Widget widget, {String? name}) =>
      key.currentState?.push(_route(widget, name: name));

  static dynamic pushReplacement(Widget widget, {String? name}) =>
      key.currentState?.pushReplacement(_route(widget, name: name));

  static dynamic pushAndRemovePreviousRoutes(Widget widget, {String? name}) =>
      key.currentState?.pushAndRemoveUntil(
        _route(widget, name: name),
        (_) => false,
      );

  /// Matches the SJJL navigation pattern: landscape navigation is immediate,
  /// so the previous page is never visible behind the next destination.
  static Route<dynamic> _route(Widget widget, {String? name}) {
    final mediaQuery = key.currentContext == null
        ? null
        : MediaQuery.maybeOf(key.currentContext!);
    final settings = RouteSettings(name: name ?? widget.runtimeType.toString());
    final isLandscapeDesktop =
        mediaQuery != null &&
        mediaQuery.orientation == Orientation.landscape &&
        mediaQuery.size.width >= 800;

    if (!isLandscapeDesktop) {
      return MaterialPageRoute(builder: (_) => widget, settings: settings);
    }

    return PageRouteBuilder(
      settings: settings,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => widget,
      transitionsBuilder: (_, _, _, child) => child,
    );
  }

  static void popUntil(Widget widget) {
    key.currentState?.popUntil(
      (route) => route.settings.name == widget.runtimeType.toString(),
    );
  }

  // Nav to pages
  static late VoidCallback goToLogin;
  static late VoidCallback goToAuthGate;
}

class _StackObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    AppRoutes._stack.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    AppRoutes._stack.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    AppRoutes._stack.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) AppRoutes._stack.remove(oldRoute);
    if (newRoute != null) AppRoutes._stack.add(newRoute);
  }
}

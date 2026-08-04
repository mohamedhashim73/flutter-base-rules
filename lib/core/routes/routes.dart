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

  static dynamic push(Widget widget) => key.currentState?.push(
    MaterialPageRoute(
      builder: (_) => widget,
      settings: RouteSettings(name: widget.runtimeType.toString()),
    ),
  );

  static dynamic pushReplacement(Widget widget) =>
      key.currentState?.pushReplacement(
        MaterialPageRoute(
          builder: (_) => widget,
          settings: RouteSettings(name: widget.runtimeType.toString()),
        ),
      );

  static dynamic pushAndRemovePreviousRoutes(Widget widget) =>
      key.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => widget,
          settings: RouteSettings(name: widget.runtimeType.toString()),
        ),
        (_) => false,
      );

  static void popUntil(Widget widget) {
    key.currentState?.popUntil(
      (route) => route.settings.name == widget.runtimeType.toString(),
    );
  }

  // Nav to pages
  static VoidCallback goToLogin = () => pushReplacement(const SizedBox());
}

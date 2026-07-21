import 'package:flutter/material.dart';

class AppRestart extends StatefulWidget {
  final Widget child;

  const AppRestart({super.key, required this.child});

  static void restartApp(BuildContext context) {
    final state = context.findAncestorStateOfType<AppRestartState>();
    state?.restart();
  }

  @override
  State<AppRestart> createState() => AppRestartState();
}

class AppRestartState extends State<AppRestart> {
  Key _key = UniqueKey();

  Key get appKey => _key;

  void restart() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

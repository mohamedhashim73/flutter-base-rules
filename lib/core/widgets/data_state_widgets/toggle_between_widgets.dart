import 'package:flutter/material.dart';

class WidgetSwitcher extends StatelessWidget {
  final bool isFirst;
  final Widget first;
  final Widget second;
  const WidgetSwitcher({
    super.key,
    required this.isFirst,
    required this.first,
    required this.second,
  });

  @override
  Widget build(BuildContext context) {
    return isFirst ? first : second;
  }
}

class ConditionalPadding extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ConditionalPadding({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (padding == null) {
      return child;
    }

    return Padding(
      padding: padding!,
      child: child,
    );
  }
}

class ConditionalFlexWidget extends StatelessWidget {
  final bool flexibleNotExpande;
  final Widget child;
  const ConditionalFlexWidget({
    super.key,
    required this.flexibleNotExpande,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return flexibleNotExpande ? Flexible(child: child) : Expanded(child: child);
  }
}

class ConditionalRefreshIndicator extends StatelessWidget {
  final Widget child;
  final RefreshCallback? onRefresh;

  const ConditionalRefreshIndicator({
    super.key,
    required this.child,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (onRefresh == null) {
      return child;
    }

    return RefreshIndicator(
      onRefresh: onRefresh!,
      child: child,
    );
  }
}

class StackWidget extends StatelessWidget {
  final Widget child;
  final Alignment alignment;
  final Widget sub;
  const StackWidget({
    super.key,
    required this.child,
    required this.sub,
    this.alignment = Alignment.bottomCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: alignment,
      children: [
        child,
        IntrinsicHeight(child: sub),
      ],
    );
  }
}

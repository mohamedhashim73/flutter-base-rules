import 'package:flutter/material.dart';

/// Common Widgets
extension LazyBuilderFunction on Widget Function() {
  /// Will Be Use With DataStateBuilderWidget To Make It Lazy As On Widget Build Event Condition Yet Achieved
  Widget get lazy => Builder(builder: (_) => this());
}

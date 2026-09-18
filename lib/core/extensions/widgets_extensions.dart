part of 'extensions.dart';
/// Common Widgets
extension LazyBuilderFunction on Widget Function() {
  /// Will Be Use With DataStateBuilderWidget To Make It Lazy As On Widget Build Event Condition Yet Achieved
  Widget get lazy => Builder(builder: (_) => this());
}

extension WidgetMarginX on Widget {
  Widget marginAll(double value) =>
      Container(margin: EdgeInsets.all(value.r), child: this);

  Widget marginHorizontal(double value) => Container(
    margin: EdgeInsets.symmetric(horizontal: value.r),
    child: this,
  );

  Widget marginVertical(double value) => Container(
    margin: EdgeInsets.symmetric(vertical: value.r),
    child: this,
  );

  Widget marginSymmetric({double horizontal = 0, double vertical = 0}) =>
      Container(
        margin: EdgeInsets.symmetric(
          horizontal: horizontal.r,
          vertical: vertical.r,
        ),
        child: this,
      );

  Widget marginOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) => Container(
    margin: EdgeInsets.only(
      left: left.r,
      top: top.r,
      right: right.r,
      bottom: bottom.r,
    ),
    child: this,
  );

  Widget marginDirectionalOnly({
    double start = 0,
    double top = 0,
    double end = 0,
    double bottom = 0,
  }) => Container(
    margin: EdgeInsetsDirectional.only(
      start: start.r,
      top: top.r,
      end: end.r,
      bottom: bottom.r,
    ),
    child: this,
  );

  Widget get marginZero => Container(margin: EdgeInsets.zero, child: this);
}

extension WidgetPaddingX on Widget {
  Widget paddingAll(double value) =>
      Padding(padding: EdgeInsets.all(value.r), child: this);

  Widget paddingHorizontal(double value) => Padding(
    padding: EdgeInsets.symmetric(horizontal: value.r),
    child: this,
  );

  Widget paddingVertical(double value) => Padding(
    padding: EdgeInsets.symmetric(vertical: value.r),
    child: this,
  );

  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) =>
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal.r,
          vertical: vertical.r,
        ),
        child: this,
      );

  Widget paddingOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) => Padding(
    padding: EdgeInsets.only(
      left: left.r,
      top: top.r,
      right: right.r,
      bottom: bottom.r,
    ),
    child: this,
  );

  Widget pDirectionalOnly({
    double start = 0.0,
    double top = 0.0,
    double end = 0.0,
    double bottom = 0.0,
  }) => Padding(
    padding: EdgeInsetsDirectional.only(
      top: top,
      start: start,
      end: end,
      bottom: bottom,
    ),
    child: this,
  );

  Widget get paddingZero => Padding(padding: EdgeInsets.zero, child: this);
}

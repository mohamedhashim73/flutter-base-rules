part of '../widgets.dart';

class DataStateBuilderWidget extends StatelessWidget {
  final DataState dataState;
  final Widget widget;
  final Function()? onFailure;
  final Function()? onRefresh;
  final Widget? shimmerWidget;
  final double? emptyOrErrorTxtSize;
  final double? errorOrEmptyImageSize;
  final double? errorTxtSize;
  final EmptyType? emptyType;
  final EdgeInsets? marginOfEmptyOrError;
  final EdgeInsets? padding;
  final bool shimmerListIsOn;
  final bool emptyErrorIsShorten;

  const DataStateBuilderWidget({
    super.key,
    required this.widget,
    this.padding,
    this.shimmerWidget,
    this.emptyErrorIsShorten = false,
    this.shimmerListIsOn = false,
    this.emptyOrErrorTxtSize,
    this.onFailure,
    this.marginOfEmptyOrError,
    this.errorOrEmptyImageSize,
    this.errorTxtSize,
    this.emptyType,
    required this.dataState,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Builder(
      builder: (context) {
        if (dataState.isError) {
          return Container(
            margin: marginOfEmptyOrError,
            child: ErrorViewWidget(
              retryFunction: onFailure,
              txtSize: emptyOrErrorTxtSize,
              message: dataState.error,
              isShorten: emptyErrorIsShorten,
              size: errorOrEmptyImageSize,
            ),
          );
        } else if (dataState.isSuccess) {
          if (!dataState.isEmpty) {
            return widget;
          } else {
            return Container(
              margin: marginOfEmptyOrError,
              child: EmptyViewWidget(
                type: emptyType,
                isShorten: emptyErrorIsShorten,
              ),
            );
          }
        } else {
          if (shimmerListIsOn && shimmerWidget != null) {
            return ShimmerListViewWidget(
              itemBuilder: (index) => shimmerWidget!,
            );
          }
          return shimmerWidget ?? const LoadingViewWidget();
        }
      },
    );
    return WidgetSwitcher(
      first: RefreshIndicator(
        onRefresh: () async => onRefresh?.call(),
        child: content,
      ),
      isFirst: onRefresh != null,
      second: content,
    );
  }
}

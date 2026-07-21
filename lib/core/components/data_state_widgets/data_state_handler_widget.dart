import 'package:base/core/components/custom_listview_widgets/custom_listview_widget.dart';
import 'package:base/core/components/data_state_widgets/toggle_between_widgets.dart';
import 'package:base/core/services/base/data_state_helper.dart';
import 'package:flutter/material.dart';
import 'package:base/core/components/data_state_widgets/empty_view_widget.dart';
import 'package:base/core/components/data_state_widgets/error_view_widget.dart';
import 'package:base/core/components/data_state_widgets/loading_view_widget.dart';
import 'package:base/core/constants/enums/empty_enum.dart';

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

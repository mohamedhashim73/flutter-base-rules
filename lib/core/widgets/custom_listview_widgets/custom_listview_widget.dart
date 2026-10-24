part of '../widgets.dart';

class _LazyHorizontalListView extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double spacing;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;

  const _LazyHorizontalListView({
    required this.itemCount,
    required this.itemBuilder,
    required this.spacing,
    required this.padding,
    this.physics,
    this.controller,
  });

  @override
  State<_LazyHorizontalListView> createState() =>
      _LazyHorizontalListViewState();
}

class _LazyHorizontalListViewState extends State<_LazyHorizontalListView> {
  final Map<int, double> _itemHeights = <int, double>{};
  double? _height;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _itemHeights.clear();
    _height = null;
  }

  void _updateHeight(int index, Size size) {
    if (!mounted || size.height <= 0) return;
    _itemHeights[index] = size.height;
    final height = _itemHeights.values.fold<double>(
      0,
      (maxHeight, itemHeight) =>
          itemHeight > maxHeight ? itemHeight : maxHeight,
    );
    if (_height == height) return;
    setState(() => _height = height);
  }

  Widget _measure(int index, Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      widthFactor: 1,
      heightFactor: 1,
      child: _MeasureSize(
        onChange: (size) => _updateHeight(index, size),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) return const SizedBox.shrink();

    if (_height == null) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: widget.padding,
        child: Row(children: [_measure(0, widget.itemBuilder(context, 0))]),
      );
    }

    return SizedBox(
      height: _height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: widget.physics,
        controller: widget.controller,
        padding: widget.padding,
        itemCount: widget.itemCount,
        separatorBuilder: (context, index) => SizedBox(width: widget.spacing),
        itemBuilder: (context, index) =>
            _measure(index, widget.itemBuilder(context, index)),
      ),
    );
  }
}

class _MeasureSize extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onChange;

  const _MeasureSize({required this.onChange, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChange);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _MeasureSizeRenderObject renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  _MeasureSizeRenderObject(this.onChange);

  ValueChanged<Size> onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    if (_oldSize == size) return;
    _oldSize = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(size));
  }
}

class PaginatedListviewWidget extends StatelessWidget {
  final int? length;
  final bool shimmerItemIsEnabled;
  final bool shrinkWrap;
  final bool? shimmerListIsEnabled;
  final int? count;
  final ScrollPhysics? physics;
  final ScrollController? scrollController;
  final Widget Function(int index) itemBuilder;
  final Widget? shimmerWidget;
  final Widget? separatorWidget;
  final EdgeInsets? padding;
  const PaginatedListviewWidget({
    super.key,
    this.shimmerItemIsEnabled = true,
    this.shrinkWrap = false,
    this.count = 0,
    this.length = 0,
    this.scrollController,
    required this.itemBuilder,
    this.shimmerWidget,
    this.physics,
    this.separatorWidget,
    this.shimmerListIsEnabled,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final Widget shimmerItem =
        shimmerWidget ?? LoadingViewWidget();
    if (shimmerListIsEnabled == true && shimmerWidget != null) {
      return ShimmerListViewWidget(itemBuilder: (index) => shimmerItem);
    } else {
      return ListView.separated(
        itemCount: (length ?? 0) + 1,
        separatorBuilder: (context, index) => separatorWidget ?? 14.vrSpace,
        shrinkWrap: shrinkWrap,
        physics: physics ?? const AlwaysScrollableScrollPhysics(),
        controller: scrollController,
        padding: padding ?? context.listViewPadding,
        itemBuilder: (context, index) {
          if (index != length) {
            return itemBuilder(index);
          } else {
            if (!shimmerItemIsEnabled || length == count) {
              return const SizedBox();
            } else {
              return shimmerItem;
            }
          }
        },
      );
    }
  }
}

class PaginatedHorizontalListviewWidget extends StatelessWidget {
  final int? length;
  final bool shimmerItemIsEnabled;
  final bool? shimmerListIsEnabled;
  final int? count;
  final ScrollPhysics? physics;
  final ScrollController? scrollController;
  final Widget Function(int index) itemBuilder;
  final Widget? shimmerWidget;
  final double? space;
  final EdgeInsets? padding;
  const PaginatedHorizontalListviewWidget({
    super.key,
    this.shimmerItemIsEnabled = true,
    this.count = 0,
    this.length = 0,
    this.scrollController,
    required this.itemBuilder,
    this.shimmerWidget,
    this.physics,
    this.space,
    this.shimmerListIsEnabled,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final Widget shimmerItem =
        shimmerWidget ?? LoadingViewWidget();
    if (shimmerListIsEnabled == true && shimmerWidget != null) {
      return _LazyHorizontalListView(
        itemCount: (length ?? 0) + 1,
        spacing: 0,
        padding: padding ?? EdgeInsets.zero,
        physics: physics,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(right: space ?? 10),
          child: shimmerItem,
        ),
      );
    } else {
      return _LazyHorizontalListView(
        itemCount: (length ?? 0) + 1,
        spacing: space ?? 10,
        padding: padding ?? EdgeInsets.zero,
        physics: physics,
        controller: scrollController,
        itemBuilder: (context, index) {
          if (index != length) {
            return itemBuilder(index);
          }
          if (!shimmerItemIsEnabled || length == count) {
            return const SizedBox();
          }
          return shimmerItem;
        },
      );
    }
  }
}

class PaginatedHorizontalSingleChildScrollWidget extends StatelessWidget {
  final int? length;
  final bool? shimmerItemIsEnabled;
  final bool? shimmerListIsEnabled;
  final ScrollPhysics? physics;
  final ScrollController? scrollController;
  final Widget Function(int index) itemBuilder;
  final Widget shimmerWidget;
  final double? space;
  final EdgeInsets? padding;
  const PaginatedHorizontalSingleChildScrollWidget({
    super.key,
    this.shimmerItemIsEnabled,
    this.length = 0,
    this.scrollController,
    required this.itemBuilder,
    required this.shimmerWidget,
    this.physics,
    this.space,
    this.shimmerListIsEnabled,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (shimmerListIsEnabled == true) {
      return _LazyHorizontalListView(
        itemCount: 16,
        spacing: space ?? 10,
        padding: padding ?? EdgeInsets.zero,
        physics: physics,
        itemBuilder: (context, index) => shimmerWidget,
      );
    }
    return _LazyHorizontalListView(
      itemCount: (length ?? 0) + 1,
      spacing: space ?? 10,
      padding: padding ?? EdgeInsets.zero,
      physics: physics,
      controller: scrollController,
      itemBuilder: (context, index) {
        if (index != length) {
          return itemBuilder(index);
        }
        if (shimmerItemIsEnabled == false) {
          return const SizedBox();
        }
        return shimmerWidget;
      },
    );
  }
}

class CustomListviewWidget extends StatelessWidget {
  final int? length;
  final int shimmerCount;
  final Axis? scrollDirection;
  final bool shimmerShownCondition;
  final bool isEmpty;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final ScrollController? scrollController;
  final Widget Function(int index) itemBuilder;
  final Widget? shimmerWidget;
  final Widget? separatorWidget;
  final int? shownFirstItemAfterTimeAsMillSeconds;
  final EdgeInsetsGeometry? paddingOnEmpty;
  final bool shrinkWrap;
  final bool emptyErrorIsShorten;

  const CustomListviewWidget({
    this.isEmpty = false,
    super.key,
    this.shimmerShownCondition = false,
    this.shimmerCount = 6,
    this.length = 0,
    this.scrollController,
    required this.itemBuilder,
    this.shimmerWidget,
    this.physics,
    this.scrollDirection,
    this.separatorWidget,
    this.padding,
    this.shownFirstItemAfterTimeAsMillSeconds,
    this.emptyErrorIsShorten = false,
    this.paddingOnEmpty,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return Padding(
        padding: paddingOnEmpty ?? EdgeInsets.zero,
        child: EmptyViewWidget(isShorten: emptyErrorIsShorten),
      );
    }
    return ListView.separated(
      separatorBuilder: (context, index) => separatorWidget ?? 14.vrSpace,
      itemCount: shimmerShownCondition ? shimmerCount : length!,
      shrinkWrap: shrinkWrap,
      scrollDirection: scrollDirection ?? Axis.vertical,
      physics: physics,
      controller: scrollController,
      padding: padding ?? context.paddingZero,
      itemBuilder: (context, index) {
        if (!shimmerShownCondition) {
          return itemBuilder(index);
        } else {
          return shimmerWidget ?? const LoadingViewWidget();
        }
      },
    );
  }
}

class CustomHorizontalSingleChildScrollWidget extends StatelessWidget {
  final int? length;
  final Widget Function(int index) itemBuilder;
  final double space;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  const CustomHorizontalSingleChildScrollWidget({
    super.key,
    required this.length,
    required this.itemBuilder,
    this.space = 10,
    this.padding,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return _LazyHorizontalListView(
      itemCount: length ?? 0,
      spacing: space,
      padding: padding ?? EdgeInsets.zero,
      physics: physics,
      itemBuilder: (context, index) => itemBuilder(index),
    );
  }
}

class CustomAlignedGridWidget extends StatelessWidget {
  final int length;
  final int crossAxisCount;
  final Widget Function(int index) itemBuilder;
  final ScrollPhysics? physics;
  final EdgeInsets? padding;
  final ScrollController? scrollController;
  final bool shrinkWrap;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;

  const CustomAlignedGridWidget({
    super.key,
    required this.length,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.physics,
    this.padding,
    this.scrollController,
    this.shrinkWrap = true,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return AlignedGridView.count(
      itemCount: length,
      shrinkWrap: shrinkWrap,
      physics: physics ?? const NeverScrollableScrollPhysics(),
      controller: scrollController,
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing ?? 8.r,
      crossAxisSpacing: crossAxisSpacing ?? 8.r,
      padding: padding ?? EdgeInsets.zero,
      itemBuilder: (context, index) => itemBuilder(index),
    );
  }
}

class ShimmerListViewWidget extends StatelessWidget {
  final Widget Function(int index) itemBuilder;
  final Widget? separatorWidget;
  final ScrollPhysics? physics;
  final int count;
  final EdgeInsets? padding;
  const ShimmerListViewWidget({
    super.key,
    required this.itemBuilder,
    this.count = 16,
    this.separatorWidget,
    this.physics,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: physics,
      padding: padding ?? context.paddingZero,
      separatorBuilder: (context, index) => separatorWidget ?? 14.vrSpace,
      itemCount: count,
      itemBuilder: (context, index) => itemBuilder(index),
    );
  }
}

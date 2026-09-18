part of '../widgets.dart';

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
        shimmerWidget ?? const LoadingViewWidget(size: 16);
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
      return ShimmerListViewWidget(itemBuilder: (index) => shimmerWidget);
    } else {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: physics,
        controller: scrollController,
        padding: padding ?? EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: space ?? 10,
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate((length ?? 0) + 1, (index) {
            if (index != length) {
              return itemBuilder(index);
            } else {
              if (shimmerItemIsEnabled == false) {
                return const SizedBox();
              } else {
                return shimmerWidget;
              }
            }
          }),
        ),
      );
    }
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
  final EmptyType? emptyType;
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
    this.emptyType,
    this.emptyErrorIsShorten = false,
    this.paddingOnEmpty,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return Padding(
        padding: paddingOnEmpty ?? EdgeInsets.zero,
        child: EmptyViewWidget(type: emptyType, isShorten: emptyErrorIsShorten),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: physics,
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: space,
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(length ?? 0, (index) => itemBuilder(index)),
      ),
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

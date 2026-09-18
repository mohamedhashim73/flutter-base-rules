part of '../widgets.dart';

class CustomImage extends StatelessWidget {
  final double? height;
  final double? width;
  final double? imgHeight;
  final double? imgWidth;
  final double? radius;
  final BorderRadiusGeometry? borderRadius;
  final Border? border;
  final Color? background;
  final bool shimmerIsOn;
  final String? path;
  final BoxFit? fit;
  final Color? color;
  final BoxShape shape;
  final bool isAsset;
  final Alignment? alignment;

  const CustomImage(
    this.path, {
    super.key,
    this.shimmerIsOn = false,
    this.isAsset = true,
    this.radius,
    this.shape = BoxShape.rectangle,
    this.imgHeight,
    this.imgWidth,
    this.fit,
    this.borderRadius,
    this.border,
    this.background,
    this.color,
    this.height,
    this.width,
    this.alignment,
  });

  bool get _isSvg => path?.toLowerCase().contains('svg') == true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height?.r,
      width: width?.r,
      clipBehavior: Clip.hardEdge,
      alignment: alignment,
      decoration: BoxDecoration(
        color: background ?? (shimmerIsOn ? AppColors.kShimmer : null),
        shape: shape,
        border: border,
        borderRadius:
            shape != BoxShape.circle && (radius != null || borderRadius != null)
            ? borderRadius ?? BorderRadius.circular(radius!)
            : null,
      ),
      child: Builder(
        builder: (context) {
          if (path == null || path!.isEmpty) {
            return const SizedBox();
          }

          if (isAsset && path?.isLink != true) {
            return _isSvg ? _buildSvgAsset() : _buildRasterAsset();
          }

          return _buildNetworkImage();
        },
      ),
    );
  }

  Widget _buildSvgAsset() {
    return SvgPicture.asset(
      path!,
      height: imgHeight?.r,
      width: imgWidth?.r,
      fit: fit ?? BoxFit.contain,
      colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      placeholderBuilder: (context) => SizedBox(
        height: imgHeight?.r,
        width: imgWidth?.r,
      ),
    );
  }

  Widget _buildRasterAsset() {
    return Image.asset(
      path!,
      height: imgHeight?.r,
      width: imgWidth?.r,
      fit: fit,
      color: color,
      errorBuilder: (context, error, stackTrace) => SizedBox(
        height: imgHeight?.r,
        width: imgWidth?.r,
      ),
    );
  }

  Widget _buildNetworkImage() {
    if (_isSvg) {
      return SvgPicture.network(
        path!,
        height: imgHeight?.r,
        width: imgWidth?.r,
        fit: fit ?? BoxFit.contain,
        colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
        placeholderBuilder: (context) => SizedBox(
          height: imgHeight?.r,
          width: imgWidth?.r,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: path!,
      fit: fit ?? BoxFit.cover,
      height: imgHeight?.r,
      width: imgWidth?.r,
      color: color,
      placeholder: (context, url) => SizedBox(
        height: imgHeight?.r,
        width: imgWidth?.r,
      ),
      errorWidget: (context, url, error) => SizedBox(
        height: imgHeight?.r,
        width: imgWidth?.r,
      ),
    );
  }
}
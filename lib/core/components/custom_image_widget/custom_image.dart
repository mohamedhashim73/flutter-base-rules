import 'package:playx/playx.dart';
import 'package:base/core/constants/extensions/string_extensions.dart';
import 'package:base/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class MyImage extends StatelessWidget {
  final double? height;
  final double? width;
  final double? imgHeight;
  final double? imgWidth;
  final double? radius;
  final BorderRadius? borderRadius;
  final Color? background;
  final bool shimmerIsOn;
  final String? path;
  final BoxFit? fit;
  final Color? color;
  final BoxShape shape;
  final bool isAsset;
  final Alignment? alignment;
  const MyImage(
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
    this.background,
    this.color,
    this.height,
    this.width,
    this.alignment,
  });

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
        borderRadius:
            shape != BoxShape.circle && (radius != null || borderRadius != null)
            ? borderRadius ?? BorderRadius.circular(radius!)
            : null,
      ),
      child: Builder(
        builder: (context) {
          if (path != null) {
            if (isAsset && !(path?.isLink == true)) {
              if (path?.contains("svg") == true) {
                return ImageViewer.svgAsset(
                  path!,
                  height: imgHeight?.r,
                  width: imgWidth?.r,
                  color: color,
                  fit: fit,
                );
              } else {
                return ImageViewer.asset(
                  path!,
                  height: imgHeight?.r,
                  width: imgWidth?.r,
                  fit: fit,
                  color: color,
                );
              }
            }
          }
          return CachedNetworkImage(
            imageUrl: "$path",
            fit: fit ?? BoxFit.cover,
            height: imgHeight?.r,
            width: imgWidth?.r,
            placeholder: (context, url) => Image.network(
              path ?? "",
              height: imgHeight?.r,
              width: imgWidth?.r,
              fit: fit ?? BoxFit.cover,
              errorBuilder: (context, url, error) => SizedBox(),
            ),
            errorWidget: (context, url, error) => SizedBox(),
          );
        },
      ),
    );
  }
}

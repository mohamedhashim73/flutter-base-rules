import 'package:playx/playx.dart';
import 'package:base/core/constants/extensions/buildContext_extensions.dart';
import 'package:flutter/material.dart';
import '../../services/base/asset_service.dart';
import '../../theme/app_colors.dart';

class SearchTextFieldWidget extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final TextInputType? textInputType;
  final FocusNode? focusNode;
  final VoidCallback? onSubmitted;
  final bool? enabled;
  final Widget? suffixWidget;
  final Color? color;
  final double? bSpace;
  final VoidCallback? emptyTap;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final VoidCallback? onTap;

  const SearchTextFieldWidget({
    super.key,
    this.controller,
    this.onSubmitted,
    this.emptyTap,
    required this.hintText,
    this.textInputType,
    this.enabled,
    this.suffixWidget,
    this.focusNode,
    this.color,
    this.bSpace,
    this.borderRadius,
    this.borderColor,
    this.onTap,
  });

  @override
  State<SearchTextFieldWidget> createState() => _SearchTextFieldWidgetState();
}

class _SearchTextFieldWidgetState extends State<SearchTextFieldWidget> {
  FocusNode? _focusNode;

  @override
  void initState() {
    super.initState();

    if (widget.focusNode == null) {
      _focusNode = FocusNode();
    }

    widget.controller?.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant SearchTextFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onTextChanged);
      widget.controller?.addListener(_onTextChanged);
    }
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    widget.controller?.removeListener(_onTextChanged);
    _focusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: widget.controller,
      focusNode: widget.controller != null
          ? (widget.focusNode ?? _focusNode)
          : null,
      autocorrect: true,
      textInputAction: TextInputAction.search,
      enabled: widget.enabled ?? true,
      readOnly: widget.controller == null,
      textAlignVertical: TextAlignVertical.center,
      keyboardType: widget.textInputType,
      onChanged: widget.controller != null
          ? (_) => widget.onSubmitted?.call()
          : null,
      onTapOutside: (_) => unFocus(),
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
        fontWeight: FontWeight.w400,
        color: AppColors.kMainTxt,
      ),
      decoration: InputDecoration(
        contentPadding: context.cardPadding,
        enabledBorder: widget.borderRadius != null
            ? OutlineInputBorder(
                borderRadius: widget.borderRadius!,
                borderSide: BorderSide(
                  color: widget.borderColor ?? AppColors.kLightGrey,
                  width: 1,
                ),
              )
            : context.enabledInputBorder,
        focusedBorder: widget.borderRadius != null
            ? OutlineInputBorder(
                borderRadius: widget.borderRadius!,
                borderSide: BorderSide(
                  color: widget.borderColor ?? AppColors.kMain,
                  width: 1,
                ),
              )
            : context.focusedInputBorder,
        errorBorder: widget.borderRadius != null
            ? OutlineInputBorder(
                borderRadius: widget.borderRadius!,
                borderSide: BorderSide(
                  color: widget.borderColor ?? AppColors.kRed,
                  width: 1,
                ),
              )
            : context.errorInputBorder,
        filled: true,
        isDense: true,
        fillColor: widget.color ?? AppColors.kSoftWhite,
        prefixIconConstraints: const BoxConstraints(
          maxHeight: 46,
          maxWidth: 46,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(start: 14, end: 8),
          child: SvgPicture.asset(Assets.icSearch, color: AppColors.kSecondary),
        ),
        suffixIconConstraints: const BoxConstraints(
          maxHeight: 46,
          maxWidth: 46,
        ),
        suffixIcon: widget.controller?.text.isEmpty ?? true
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsetsDirectional.only(end: 10),
                child: InkWell(
                  onTap: () {
                    widget.controller?.clear();
                    widget.onSubmitted?.call();
                    widget.emptyTap?.call();
                    unFocus();
                  },
                  child: Icon(
                    Icons.clear,
                    color: AppColors.kSecondary,
                    size: 22,
                  ),
                ),
              ),
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.kSecondary,
        ),
        hintText: widget.hintText,
      ),
    ).marginOnly(bottom: widget.bSpace ?? 14);

    if (widget.onTap != null) {
      return InkWell(
        onTap: widget.onTap,
        child: AbsorbPointer(child: field),
      );
    }

    return field;
  }

  void unFocus() {
    (widget.focusNode ?? _focusNode)?.unfocus();
  }
}

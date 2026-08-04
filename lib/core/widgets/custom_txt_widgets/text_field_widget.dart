import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:playx/playx.dart';
import 'package:base/core/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:base/core/constants/constants.dart';
import 'package:base/core/theme/app_colors.dart';

class TxtFieldWidget extends StatefulWidget {
  final String? label;
  final String hint;
  final bool isOptional;
  final double? verticalSpaceBetweenLabelAndTxtField;
  final TextStyle? labelStyle;
  final String? validatorTxt;
  final TextEditingController? controller;
  final TextInputAction? textInputAction;
  final TextInputType? textInputType;
  final bool? isPassword;
  final String? Function(String?)? validator;
  final bool isOn;
  final bool isNum;
  final bool validationIsOn;
  final FocusNode? focusNode;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final EdgeInsets? padding;
  final Function()? onChanged;
  final double bSpace;
  final int? maxLength;
  final int maxLines;
  final bool readOnly;
  final bool onlyEnabledBorderIsOn;
  final double? height;
  final double? txtSize;
  final bool isDense;
  final Function()? onTap;
  final Function()? onTonTapOutside;
  final Function(String?)? onSaved;
  final BorderRadius? borderRadius;
  final TextDirection? textDirection;
  final bool showLabelInsteadOfHint;

  const TxtFieldWidget({
    super.key,
    this.maxLines = 1,
    this.isNum = false,
    this.isOn = true,
    this.isDense = true,
    this.readOnly = false,
    this.validationIsOn = true,
    this.isOptional = false,
    this.showLabelInsteadOfHint = true,
    this.onlyEnabledBorderIsOn = false,
    this.textInputType,
    this.textInputAction,
    this.label,
    this.height,
    this.onSaved,
    this.controller,
    this.txtSize,
    this.isPassword,
    this.bSpace = 14,
    this.validator,
    this.onTonTapOutside,
    this.validatorTxt,
    this.maxLength,
    required this.hint,
    this.labelStyle,
    this.verticalSpaceBetweenLabelAndTxtField,
    this.focusNode,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.textDirection,
  });

  @override
  State<TxtFieldWidget> createState() => _TxtFieldWidgetState();
}

class _TxtFieldWidgetState extends State<TxtFieldWidget> {
  static const _kBorderColor = Color(0xFFE7EBEF);
  static const _kBorderWidth = AppConstants.kBorderWidth;

  FocusNode? _focusNode;

  BorderRadius get _radius =>
      widget.borderRadius ?? BorderRadius.circular(18.r);

  InputBorder get _enabledBorder => OutlineInputBorder(
    borderRadius: _radius,
    borderSide: const BorderSide(color: _kBorderColor, width: _kBorderWidth),
  );

  InputBorder get _focusedBorder => OutlineInputBorder(
    borderRadius: _radius,
    borderSide: BorderSide(color: AppColors.kMain, width: _kBorderWidth),
  );

  InputBorder get _errorBorder => OutlineInputBorder(
    borderRadius: _radius,
    borderSide: BorderSide(color: AppColors.kRed, width: _kBorderWidth),
  );

  @override
  void initState() {
    if (widget.focusNode == null) {
      _focusNode = FocusNode();
    }
    super.initState();
  }

  @override
  void dispose() {
    widget.focusNode?.dispose();
    _focusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        if (widget.label != null)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: "${widget.label} "),
                TextSpan(
                  text: widget.isOptional ? "" : "*",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            style:
                widget.labelStyle ??
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        SizedBox(
          height: widget.height,
          child: TextFormField(
            controller: widget.controller,
            textDirection: widget.textDirection,
            autocorrect: true,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            inputFormatters: [_ArabicToEnglishDigitsFormatter()],
            validator: widget.validationIsOn
                ? widget.validator ??
                      (input) => input?.validatorTxt(
                        isNum: widget.isNum,
                        isOptional: widget.isOptional,
                      )
                : null,
            onChanged: (input) {
              if (widget.onChanged != null) {
                setState(() {
                  widget.onChanged!();
                });
              }
            },
            onFieldSubmitted: widget.onSaved,
            focusNode: widget.focusNode ?? _focusNode,
            style: TextStyle(
              fontSize: widget.txtSize ?? 14,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            enabled: widget.isOn,
            keyboardType: widget.textInputType ?? TextInputType.text,
            obscureText: widget.isPassword ?? false,
            maxLength: widget.maxLength,
            maxLines: widget.maxLines,
            onTapOutside: (pointerDownEvent) {
              unFocus();
              widget.onTonTapOutside?.call();
            },
            textInputAction: widget.textInputAction ?? TextInputAction.next,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: Color(0xffEFEFEF),
                fontWeight: FontWeight.w400,
                fontSize: widget.txtSize ?? 16,
              ),
              contentPadding:
                  widget.padding ??
                  EdgeInsets.symmetric(horizontal: 12.r, vertical: 14.5.r),
              enabledBorder:
                  Theme.of(context).inputDecorationTheme.enabledBorder ??
                  _enabledBorder,
              focusedBorder: widget.onlyEnabledBorderIsOn
                  ? (Theme.of(context).inputDecorationTheme.enabledBorder ??
                        _enabledBorder)
                  : (Theme.of(context).inputDecorationTheme.focusedBorder ??
                        _focusedBorder),
              disabledBorder:
                  Theme.of(context).inputDecorationTheme.enabledBorder ??
                  _enabledBorder,
              errorBorder: widget.onlyEnabledBorderIsOn
                  ? _enabledBorder
                  : (Theme.of(context).inputDecorationTheme.errorBorder ??
                        _errorBorder),
              counterText: "",
              prefixIcon: widget.prefixIcon != null
                  ? Center(child: widget.prefixIcon!)
                  : null,
              suffixIcon: widget.suffixIcon != null
                  ? Center(child: widget.suffixIcon!)
                  : null,
              prefixIconConstraints: BoxConstraints.fromViewConstraints(
                const ViewConstraints(
                  maxWidth: 38,
                  minWidth: 38,
                  maxHeight: 26,
                ),
              ),
              suffixIconConstraints: BoxConstraints.fromViewConstraints(
                const ViewConstraints(
                  maxWidth: 38,
                  minWidth: 38,
                  maxHeight: 26,
                ),
              ),
              focusedErrorBorder:
                  Theme.of(context).inputDecorationTheme.focusedErrorBorder ??
                  _errorBorder,
              filled: true,
              isDense: widget.isDense,
              fillColor: AppColors.kWhite,
            ),
          ),
        ),
      ],
    ).paddingOnly(bottom: widget.bSpace);
  }

  void unFocus() {
    if (widget.focusNode != null) {
      widget.focusNode?.unfocus();
    } else {
      _focusNode?.unfocus();
    }
  }
}

/// Converts Arabic-Indic (٠١٢٣٤٥٦٧٨٩) digits to
/// Western Arabic digits (0-9) as the user types.
class _ArabicToEnglishDigitsFormatter extends TextInputFormatter {
  static const _arabic = '٠١٢٣٤٥٦٧٨٩';
  static const _english = '0123456789';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final buf = StringBuffer();
    var changed = false;
    for (final ch in newValue.text.runes) {
      final c = String.fromCharCode(ch);
      final idx = _arabic.indexOf(c);
      if (idx >= 0) {
        buf.write(_english[idx]);
        changed = true;
      } else {
        buf.write(c);
      }
    }
    if (!changed) return newValue;
    final converted = buf.toString();
    return newValue.copyWith(
      text: converted,
      selection: TextSelection.collapsed(offset: converted.length),
    );
  }
}

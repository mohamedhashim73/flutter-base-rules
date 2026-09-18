import 'dart:ui';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:playx/playx.dart';
import '../../constants/constants.dart';
import '../../theme/app_colors.dart';

// ignore: must_be_immutable
class DropDownBtnWidget<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final Function(T val) onChanged;
  final String? label;
  final BorderRadius? borderRadius;
  final Widget? trailing;
  final Widget? prefix;
  final bool isOptional;
  final bool isDense;
  final TextStyle? labelStyle;
  final double bSpace;
  final double? txtSize;
  final double? iconSize;
  final EdgeInsets? padding;
  final double? height;
  final List<T> items;
  final bool reverseBackgroundIsOn;
  final String Function(T)? getLabel;

  static const _kBorderColor = Color(0xFFE7EBEF);

  DropDownBtnWidget({
    super.key,
    required this.hint,
    this.reverseBackgroundIsOn = false,
    this.isOptional = false,
    this.isDense = true,
    this.value,
    this.borderRadius,
    this.iconSize,
    this.height,
    this.bSpace = 14,
    required this.onChanged,
    required this.items,
    this.label,
    this.getLabel,
    this.trailing,
    this.prefix,
    this.labelStyle,
    this.txtSize,
    this.padding,
  });

  BorderRadius get _radius => borderRadius ?? BorderRadius.circular(18.r);

  InputBorder get _enabledBorder => OutlineInputBorder(
    borderRadius: _radius,
    borderSide: const BorderSide(color: _kBorderColor),
  );

  InputBorder get _focusedBorder => OutlineInputBorder(
    borderRadius: _radius,
    borderSide: BorderSide(color: AppColors.kMain),
  );

  ValueNotifier<T?>? _valueNotifier;

  ValueNotifier<T?> get _valueListenable {
    _valueNotifier ??= ValueNotifier<T?>(value);
    return _valueNotifier!;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        if (label != null)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: "$label "),
                TextSpan(
                  text: isOptional ? "" : "*",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            style:
                labelStyle ??
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        SizedBox(
          height: height,
          child: DropdownButtonFormField2<T>(
            valueListenable: _valueListenable,
            isExpanded: true,
            isDense: isDense,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: const Color(0xffEFEFEF),
                fontWeight: FontWeight.w400,
                fontSize: txtSize ?? 16,
              ),
              contentPadding:
                  padding ??
                  EdgeInsets.symmetric(horizontal: 12.r, vertical: 14.5.r),
              enabledBorder:
                  Theme.of(context).inputDecorationTheme.enabledBorder ??
                  _enabledBorder,
              focusedBorder:
                  Theme.of(context).inputDecorationTheme.focusedBorder ??
                  _focusedBorder,
              disabledBorder:
                  Theme.of(context).inputDecorationTheme.enabledBorder ??
                  _enabledBorder,
              errorBorder:
                  Theme.of(context).inputDecorationTheme.errorBorder ??
                  OutlineInputBorder(
                    borderRadius: _radius,
                    borderSide: BorderSide(color: AppColors.kRed),
                  ),
              focusedErrorBorder:
                  Theme.of(context).inputDecorationTheme.focusedErrorBorder ??
                  OutlineInputBorder(
                    borderRadius: _radius,
                    borderSide: BorderSide(color: AppColors.kRed,),
                  ),
              prefixIcon: prefix != null ? Center(child: prefix!) : null,
              suffixIcon: trailing != null ? Center(child: trailing!) : null,
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
              filled: true,
              isDense: isDense,
              fillColor: AppColors.kWhite,
            ),
            style: TextStyle(
              fontSize: txtSize ?? 14,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            iconStyleData: IconStyleData(
              icon: Icon(Icons.keyboard_arrow_down_rounded, size: iconSize ?? 18),
              iconSize: iconSize ?? 18,
            ),
            dropdownStyleData: DropdownStyleData(
              elevation: 0,
              decoration: BoxDecoration(
                color: AppColors.kWhite,
                borderRadius: _radius,
                border: Border.all(
                  color: _kBorderColor,
                ),
              ),
            ),
            menuItemStyleData: MenuItemStyleData(
              padding: EdgeInsets.symmetric(horizontal: 12.r),
            ),
            items: items.map((item) {
              final labelText = getLabel != null
                  ? getLabel!(item)
                  : item.toString();
              return DropdownItem<T>(
                value: item,
                alignment: AlignmentDirectional.centerStart,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    labelText,
                    style: TextStyle(
                      fontSize: txtSize ?? 14,
                      fontFamily: AppConstants.kMainFont,
                      fontWeight: FontWeight.w400,
                      color: AppColors.kBlack,
                    ),
                  ),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                _valueListenable.value = val;
                onChanged(val);
              }
            },
          ),
        ),
      ],
    ).paddingOnly(bottom: bSpace);
  }
}

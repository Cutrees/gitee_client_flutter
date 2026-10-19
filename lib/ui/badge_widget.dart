import 'package:flutter/material.dart';

class BadgeWidget<T> extends StatelessWidget {
  const BadgeWidget({
    super.key,
    this.future,
    this.centerWidget,
    this.centerIconData,
    this.smallText,
    this.smallTextStyle,
    this.smallTextBgColor,
    this.smallTextPadding,
    this.onPressed,
    this.smallTextMarginLeft,
    this.smallTextMarginTop,
    this.smallTextMarginRight,
    this.smallTextMarginBottom,
  }) : assert(centerWidget != null || centerIconData != null);

  final Future<T>? future;
  final GestureTapCallback? onPressed;
  final Widget? centerWidget;
  final IconData? centerIconData;
  final int? smallText;
  final TextStyle? smallTextStyle;
  final Color? smallTextBgColor;
  final EdgeInsetsGeometry? smallTextPadding;
  final double? smallTextMarginLeft;
  final double? smallTextMarginTop;
  final double? smallTextMarginRight;
  final double? smallTextMarginBottom;

  @override
  Widget build(BuildContext context) {
    final request = future;
    if (request == null) return _buildBadge(smallText?.toString());
    return FutureBuilder<T>(
      future: request,
      builder: (context, snapshot) =>
          _buildBadge(snapshot.hasError ? null : snapshot.data?.toString()),
    );
  }

  Widget _buildBadge(String? value) {
    final count = num.tryParse(value ?? '') ?? 0;
    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child:
              centerWidget ??
              IconButton(icon: Icon(centerIconData), onPressed: onPressed),
        ),
        if (count > 0)
          Positioned(
            left: smallTextMarginLeft,
            top: smallTextMarginTop ?? 0,
            right: smallTextMarginRight ?? 0,
            bottom: smallTextMarginBottom,
            child: IgnorePointer(
              child: Container(
                padding: smallTextPadding ?? const EdgeInsets.all(2.2),
                decoration: BoxDecoration(
                  color: smallTextBgColor ?? Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count > 99 ? '99+' : value ?? '',
                  style:
                      smallTextStyle ??
                      const TextStyle(color: Colors.white, fontSize: 8),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

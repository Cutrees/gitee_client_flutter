import 'package:flutter/material.dart';

class IconText extends StatelessWidget {
  const IconText(
    this.text, {
    super.key,
    this.icon,
    this.iconSize,
    this.direction = Axis.horizontal,
    this.style,
    this.maxLines,
    this.softWrap = true,
    this.padding,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
  });

  final String? text;
  final Icon? icon;
  final double? iconSize;
  final Axis direction;
  final EdgeInsetsGeometry? padding;
  final TextStyle? style;
  final int? maxLines;
  final bool softWrap;
  final TextOverflow overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    final leading = icon;
    return Text.rich(
      TextSpan(
        children: [
          if (leading != null)
            WidgetSpan(
              child: IconTheme(
                data: IconThemeData(
                  size: iconSize ?? (effectiveStyle.fontSize ?? 15) + 1,
                  color: effectiveStyle.color,
                ),
                child: Padding(
                  padding: padding ?? EdgeInsets.zero,
                  child: leading,
                ),
              ),
            ),
          TextSpan(
            text: direction == Axis.vertical && leading != null
                ? '\n${text ?? ''}'
                : text ?? '',
          ),
        ],
      ),
      style: effectiveStyle,
      maxLines: maxLines,
      softWrap: softWrap,
      overflow: overflow,
      textAlign:
          textAlign ??
          (direction == Axis.horizontal ? TextAlign.start : TextAlign.center),
    );
  }
}

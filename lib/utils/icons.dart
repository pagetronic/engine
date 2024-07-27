import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class StampedIcon extends StatelessWidget {
  final IconData icon;
  final IconData? stamp;
  final double? size;
  final String? tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  const StampedIcon(this.icon, {this.stamp, this.onPressed, this.tooltip, this.size, super.key, this.color});

  @override
  Widget build(BuildContext context) {
    double size = this.size == null ? (IconTheme.of(context).size ?? 32) : this.size!;
    Widget stack = Icon(icon, size: size, color: color);
    if (stamp != null) {
      stack = Stack(children: [
        Positioned(bottom: 0, right: 0, child: Opacity(opacity: 0.5, child: Icon(stamp, size: size / 3, color: color))),
        stack,
      ]);
    }
    if (onPressed != null) {
      stack = IconButton(onPressed: onPressed, icon: stack);
    }
    if (tooltip != null) {
      stack = Tooltip(message: tooltip, child: stack);
    }
    return stack;
  }
}

class ShadowIcon extends StatelessWidget {
  final IconData icon;
  final bool showShadow;
  final Color? shadowColor;
  final double? size;
  final Color? color;

  const ShadowIcon(this.icon, {super.key, this.color, this.showShadow = true, this.shadowColor, this.size});

  @override
  Widget build(BuildContext context) {
    double opacity = 0.2;
    double opacity2 = 0.06;
    double opacity3 = 0.01;
    double dimens = 1.0;
    double dimens2 = 2.0;
    double dimens3 = 3.0;
    Color shadowColor = this.shadowColor ?? Theme.of(context).shadowColor;
    List<Widget> list = [];
    if (showShadow) {
      list.addAll([
        Positioned(
          bottom: dimens3,
          right: dimens3,
          child: IconTheme(
              data: IconThemeData(
                opacity: opacity3,
              ),
              child: Icon(icon, color: shadowColor, size: size)),
        ),
        Positioned(
          bottom: dimens3,
          left: dimens3,
          child: IconTheme(
              data: IconThemeData(
                opacity: opacity3,
              ),
              child: Icon(icon, color: shadowColor, size: size)),
        ),
        Positioned(
          top: dimens3,
          left: dimens3,
          child: IconTheme(
              data: IconThemeData(
                opacity: opacity3,
              ),
              child: Icon(icon, color: shadowColor, size: size)),
        ),
        Positioned(
          top: dimens3,
          right: dimens3,
          child: IconTheme(
              data: IconThemeData(
                opacity: opacity3,
              ),
              child: Icon(icon, color: shadowColor, size: size)),
        )
      ]);

      list.addAll([
        Positioned(
          bottom: dimens2,
          right: dimens2,
          child: IconTheme(
              data: IconThemeData(
                opacity: opacity2,
              ),
              child: Icon(icon, color: shadowColor, size: size)),
        ),
        Positioned(
          bottom: dimens2,
          left: dimens2,
          child: IconTheme(
              data: IconThemeData(
                opacity: opacity2,
              ),
              child: Icon(icon, color: shadowColor, size: size)),
        ),
        Positioned(
          top: dimens2,
          left: dimens2,
          child: IconTheme(
              data: IconThemeData(
                opacity: opacity2,
              ),
              child: Icon(icon, color: shadowColor, size: size)),
        ),
        Positioned(
          top: dimens2,
          right: dimens2,
          child: IconTheme(
              data: IconThemeData(
                opacity: opacity2,
              ),
              child: Icon(icon, color: shadowColor, size: size)),
        )
      ]);

      list.addAll([
        Positioned(
          bottom: dimens,
          right: dimens,
          child: IconTheme(
              data: IconThemeData(
                opacity: opacity,
              ),
              child: Icon(icon, color: shadowColor, size: size)),
        ),
        Positioned(
          bottom: dimens,
          left: dimens,
          child: IconTheme(
              data: IconThemeData(
                opacity: opacity,
              ),
              child: Icon(icon, color: shadowColor, size: size)),
        ),
        Positioned(
          top: dimens,
          left: dimens,
          child: IconTheme(
              data: IconThemeData(
                opacity: opacity,
              ),
              child: Icon(icon, color: shadowColor, size: size)),
        ),
        Positioned(
          top: dimens,
          right: dimens,
          child: IconTheme(
              data: IconThemeData(
                opacity: opacity,
              ),
              child: Icon(icon, color: shadowColor, size: size)),
        )
      ]);
    }

    list.add(ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 0.9, sigmaY: 0.9),
        child: IconTheme(
          data: const IconThemeData(opacity: 1.0),
          child: Icon(
            icon,
            color: color,
            size: size,
          ),
        ),
      ),
    ));

    list.add(Icon(icon, color: color, size: size));

    return Stack(
      alignment: Alignment.center,
      children: list,
    );
  }
}

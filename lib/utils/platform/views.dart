import 'package:engine/api/utils/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class BaseView extends StatelessWidget {
  final List<Widget>? children;
  final Widget? child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const BaseView({super.key, this.child, this.children, this.maxWidth = Settings.maxWidth, this.padding});

  @override
  Widget build(BuildContext context) {
    if ((child == null && children == null) || (child != null && children != null)) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      child: Center(
        child: Container(
          padding: padding != null ? const EdgeInsets.only(bottom: 30) : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
            child: Container(
              padding: padding ?? const EdgeInsets.all(10),
              child: child ??
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children!,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

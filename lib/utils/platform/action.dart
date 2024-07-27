import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final dynamic icon;
  final String? label;
  final String? tooltip;
  final void Function() onPressed;

  const ActionButton(this.icon, {super.key, this.label, required this.onPressed, this.tooltip});

  @override
  Widget build(BuildContext context) {
    if (tooltip != null) {
      return IconButton(
        onPressed: onPressed,
        icon: icon is IconData ? Icon(icon as IconData, size: 20.0) : icon,
        tooltip: tooltip,
      );
    }
    if (label == null) {
      return IconButton(
          tooltip: tooltip, onPressed: onPressed, icon: icon is IconData ? Icon(icon as IconData, size: 20.0) : icon);
    }
    return TextButton.icon(
        style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSecondary), // <-- TextButton
        onPressed: onPressed,
        icon: icon is IconData ? Icon(icon as IconData, size: 20.0) : icon,
        label: Text(label!));
  }
}

class ActionMenuItem extends PopupMenuItem<Function> {
  ActionMenuItem({super.key, required String title, IconData? icon, required void Function() onSelect})
      : super(
          value: onSelect,
          child: icon != null
              ? Row(
                  children: [
                    Icon(icon, size: 20, color: Colors.grey),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(title),
                    ),
                  ],
                )
              : Text(title),
        );
}

import 'package:flutter/material.dart';

class ButtonIcon extends StatelessWidget {
  final VoidCallback? onPressed;
  final GestureTapDownCallback? onTapDown;
  final IconData icon;
  final String? text;
  final ValueNotifier<bool> hover = ValueNotifier(false);
  final double? size;
  final double defaultSize = 18;

  ButtonIcon({super.key, this.onPressed, this.onTapDown, required this.icon, this.text, this.size});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      onTapDown: onTapDown,
      onHover: (value) => hover.value = value,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: ValueListenableBuilder(
          valueListenable: hover,
          builder: (context, hover, child) => AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: hover ? 1 : 0.5,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: (size ?? defaultSize)),
                if (text != null) ...[
                  const SizedBox(width: 2),
                  Text(
                    text!,
                    style: TextStyle(fontSize: (size ?? defaultSize) * (11 / 16), fontWeight: FontWeight.bold),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

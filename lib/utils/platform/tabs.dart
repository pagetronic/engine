import 'package:flutter/material.dart';

class BaseTab extends StatelessWidget {
  final String? title;
  final IconData? icon;

  const BaseTab({super.key, this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 3),
            ],
            if (title != null) Text(title!),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class CardHolder extends StatelessWidget {
  final List<CardView> children;
  final double? ratio;

  const CardHolder({required this.children, super.key, this.ratio});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 2000),
          child: LayoutBuilder(builder: (context, constraints) {
            double width = constraints.maxWidth;
            double spacing;
            int wrapIndex = -1;
            double cols;
            if (width > 1200) {
              spacing = 30;
              cols = 4;
              wrapIndex = 6;
            } else if (width > 600) {
              spacing = 20;
              cols = 3;
            } else if (width > 300) {
              spacing = 15;
              cols = 2;
            } else {
              spacing = 10;
              cols = 1;
            }
            double boxWidth = (constraints.maxWidth - (spacing * (cols + 1))) / cols;
            List<Widget> children_ = [];
            for (int index = 0; index < children.length; index++) {
              children_.add(
                Padding(
                  padding: EdgeInsets.only(bottom: spacing),
                  child: SizedBox(
                    width: boxWidth,
                    child: AspectRatio(
                      aspectRatio: ratio ?? 16 / 9,
                      child: children[index],
                    ),
                  ),
                ),
              );
              if (index == wrapIndex) {
                children_.add(SizedBox(height: 0.1, width: width));
              }
            }
            return Padding(
              padding: EdgeInsets.all(spacing),
              child: Wrap(
                alignment: WrapAlignment.spaceEvenly,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 0,
                spacing: spacing,
                children: children_,
              ),
            );
          }),
        ),
      ),
    );
  }
}

class CardView extends StatelessWidget {
  final String asset;
  final String title;
  final void Function() onTap;
  final BoxFit fit;

  const CardView(this.asset, this.title, this.onTap, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
                      child: Image.asset(asset, fit: fit),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Text(title, style: Theme.of(context).textTheme.labelSmall))
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/widgets.dart';

export 'package:flutter/rendering.dart';

class SizerWidget extends StatelessWidget {
  final Function(BuildContext context, double maxSize) builder;
  final List<double> sizes;

  const SizerWidget({super.key, required this.sizes, required this.builder});

  @override
  Widget build(BuildContext context) {
    double maxSize = double.infinity;
    Widget? building;
    return StatefulBuilder(
      builder: (contextState, setState) => LayoutBuilder(
        builder: (context, constraints) {
          double tmpSize = double.infinity;
          double width = constraints.maxWidth;
          for (double size in sizes) {
            if (width <= size) {
              tmpSize = size;
            }
          }
          if (building == null || maxSize != tmpSize) {
            maxSize = tmpSize;
            try {
              if (building != null && contextState.mounted) {
                setState(() {
                  building = builder(context, tmpSize);
                });
              }
            } catch (_) {}
          }
          building ??= builder(context, tmpSize);
          return building!;
        },
      ),
    );
  }
}

class SizeChangeNotifier extends StatelessWidget {
  final Widget? child;
  final Function(BoxConstraints constraints) onChange;

  const SizeChangeNotifier({
    super.key,
    this.child,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              WidgetsBinding.instance.addPostFrameCallback((_) => onChange(constraints));
              return const SizedBox.expand();
            },
          ),
        ),
        Positioned.fill(
          child: child ?? const SizedBox.expand(),
        )
      ],
    );
  }
}

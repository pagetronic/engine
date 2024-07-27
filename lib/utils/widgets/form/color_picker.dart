import 'dart:math';
import 'dart:ui' as ui;

import 'package:engine/lng/language.dart';
import 'package:flutter/material.dart';

class ColorPickerInput extends StatelessWidget {
  final ValueNotifier<Color?> color = ValueNotifier(null);
  final String title;
  final void Function(Color? color) onChange;

  ColorPickerInput(Color? color, this.title, this.onChange, {super.key}) {
    this.color.value = color;
    this.color.addListener(() {
      onChange(this.color.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColorPicker(color: color);
  }

  Color? value() {
    return color.value;
  }
}

class Notifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

class ColorPicker extends StatelessWidget {
  final ValueNotifier<Color?> color;

  const ColorPicker({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    SlidePainter slider = SlidePainter.get(color);
    return LayoutBuilder(
      builder: (context, constraints) {
        slider.setWidth(constraints.maxWidth - 24);
        return Stack(
          children: [
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                    border: Border.all(width: 0.5, color: Colors.black),
                  ),
                  height: 60,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (DragUpdateDetails details) {
                      slider.setColor(details.localPosition.dx.toInt());
                    },
                    onTapDown: (TapDownDetails details) {
                      slider.setColor(details.localPosition.dx.toInt());
                    },
                    child: CustomPaint(size: Size(constraints.maxWidth - 24, constraints.maxHeight), painter: slider),
                  ),
                )),
            Positioned(
              top: 0,
              left: 10,
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(Language.of(context).choose_color, style: Theme.of(context).textTheme.bodySmall),
                ),
              ),
            )
          ],
        );
      },
    );
  }
}

class SlidePainter extends CustomPainter {
  final List<Color> gradient = const [
    Color.fromARGB(255, 255, 0, 0),
    Color.fromARGB(255, 255, 64, 0),
    Color.fromARGB(255, 255, 128, 0),
    Color.fromARGB(255, 255, 192, 0),
    Color.fromARGB(255, 255, 255, 0),
    Color.fromARGB(255, 192, 255, 0),
    Color.fromARGB(255, 128, 255, 0),
    Color.fromARGB(255, 64, 255, 0),
    Color.fromARGB(255, 0, 255, 0),
    Color.fromARGB(255, 0, 255, 64),
    Color.fromARGB(255, 0, 255, 128),
    Color.fromARGB(255, 0, 255, 192),
    Color.fromARGB(255, 0, 255, 255),
    Color.fromARGB(255, 0, 192, 255),
    Color.fromARGB(255, 0, 128, 255),
    Color.fromARGB(255, 0, 64, 255),
    Color.fromARGB(255, 0, 0, 255),
    Color.fromARGB(255, 64, 0, 255),
    Color.fromARGB(255, 128, 0, 255),
    Color.fromARGB(255, 192, 0, 255),
    Color.fromARGB(255, 255, 0, 255),
    Color.fromARGB(255, 255, 0, 192),
    Color.fromARGB(255, 255, 0, 128),
    Color.fromARGB(255, 255, 0, 64),
  ];
  double width = 1;
  final ValueNotifier<Color?> color;
  final Notifier repaint;
  double position = -1;

  final double padding = 20;

  SlidePainter(this.color, this.repaint) : super(repaint: repaint);

  static SlidePainter get(final ValueNotifier<Color?> color) => SlidePainter(color, Notifier());

  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = Offset.zero & size;
    canvas.clipRect(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(Offset(0, 6.5 * (size.height) / 18), Offset(size.width, 11.5 * (size.height) / 18)),
        const Radius.circular(4),
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(padding - 2, 0),
          Offset(size.width - padding - 2, 0),
          [gradient.first, gradient.last],
        ),
    );
    canvas.drawRect(
      Rect.fromPoints(
          Offset(padding, 6.5 * (size.height) / 18), Offset(size.width - padding, 11.5 * (size.height) / 18)),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(padding - 2, 0),
          Offset(size.width - padding - 2, 0),
          gradient,
          [for (int index = 0; index < gradient.length; index++) index / gradient.length],
        ),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromPoints(Offset(0, 6.5 * (size.height) / 18), Offset(size.width, 11.5 * (size.height) / 18)),
          const Radius.circular(4)),
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3 * 0.57735 + 0.5)
        ..color = Colors.grey.withOpacity(0.7)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      Offset(position, size.height / 2),
      14,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1)
        ..isAntiAlias = true
        ..color = Colors.grey
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      Offset(position, size.height / 2),
      14,
      Paint()..color = color.value != null ? color.value! : Colors.grey,
    );
    canvas.drawCircle(
      Offset(position, size.height / 2),
      14,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18 / 2)
        ..color = color.value != null ? color.value! : Colors.grey
        ..shader = ui.Gradient.radial(
          Offset(position + 2, size.height / 2 - 3),
          14,
          [
            color.value != null ? color.value!.withOpacity(0.7) : Colors.grey.withOpacity(0.7),
            Colors.grey.withOpacity(0.5)
          ],
          [0, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(SlidePainter oldDelegate) => this != oldDelegate;

  void setWidth(double width) {
    if (this.width != width) {
      double oldWidth = this.width;
      this.width = width;
      if (position >= 0) {
        position = position * width / oldWidth;
        repaint.notify();
      } else {
        _init();
      }
    }
  }

  void setColor(int dx) async {
    dx = min(width.toInt() - padding.toInt() - 1, max(padding.toInt(), dx));
    if (dx < padding) {
      position = padding;
    } else if (dx >= width - padding - 1) {
      position = width - padding - 1;
    } else {
      int position_ = dx;
      position = position_.toDouble();
    }
    color.value = _pixelColorAt(position.toInt());

    repaint.notify();
  }

  void _init() async {
    Color? color = this.color.value;
    if (color == null) {
      position = width / 2 - padding;
      repaint.notify();
      return;
    }
    for (double position = padding; position < width - padding - 1; position++) {
      if (_pixelColorAt(position.toInt()) == color) {
        this.position = position.toDouble();
        repaint.notify();
        return;
      }
    }

    List<double> diffs = [];
    for (double position = padding; position < width - padding - 1; position++) {
      Color color_ = _pixelColorAt(position.toInt());
      int diffRed = (color.red - color_.red).abs();
      int diffGreen = (color.green - color_.green).abs();
      int diffBlue = (color.blue - color_.blue).abs();
      diffs.add((diffRed + diffGreen + diffBlue) / 3);
    }
    double mini = double.infinity;
    for (double diff in diffs) {
      mini = min(diff, mini);
    }
    if (mini != double.infinity) {
      position = diffs.indexOf(mini).toDouble();
      repaint.notify();
    }
    position = min(max(padding, position), width - padding);
  }

  Color _pixelColorAt(int x_) {
    int x = x_ - padding.toInt();
    int numSegments = gradient.length;
    double segmentLength = (width - padding * 2) / numSegments;
    int segmentIndex = (x / segmentLength).floor();
    double relativePosition = (x % segmentLength) / segmentLength;
    Color startColor = gradient[min(segmentIndex, numSegments - 1)];
    Color endColor = gradient[min(segmentIndex + 1, numSegments - 1)];
    return _interpolateColor(startColor, endColor, relativePosition);
  }

  Color _interpolateColor(Color start, Color end, double ratio) {
    int r = (start.red + (end.red - start.red) * ratio).toInt();
    int g = (start.green + (end.green - start.green) * ratio).toInt();
    int b = (start.blue + (end.blue - start.blue) * ratio).toInt();
    return Color.fromARGB(255, r, g, b);
  }
}

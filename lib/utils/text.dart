import 'package:flutter/material.dart';

class H1 extends Head {
  const H1(super.text, {super.key, super.softWrap, super.textAlign, super.fontWeight, super.color, super.selectable});

  @override
  TextStyle? getTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.headlineLarge;
  }
}

class H2 extends Head {
  const H2(super.text, {super.key, super.softWrap, super.textAlign, super.fontWeight, super.color});

  @override
  TextStyle? getTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium;
  }
}

class H3 extends Head {
  const H3(super.text, {super.key, super.softWrap, super.textAlign, super.fontWeight, super.color});

  @override
  TextStyle? getTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall;
  }
}

class H4 extends Head {
  const H4(super.text, {super.key, super.softWrap, super.textAlign, super.fontWeight, super.color});

  @override
  TextStyle? getTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge;
  }
}

class H5 extends Head {
  const H5(super.text, {super.key, super.softWrap, super.textAlign, super.fontWeight, super.color});

  @override
  TextStyle? getTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium;
  }
}

class H6 extends Head {
  const H6(super.text, {super.key, super.softWrap, super.textAlign, super.fontWeight, super.color});

  @override
  TextStyle? getTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall;
  }
}

class Big extends Head {
  final double fontSize;

  const Big(super.text, {super.key, super.color, this.fontSize = 30});

  @override
  TextStyle? getTextStyle(BuildContext context) {
    return TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold);
  }
}

class HR extends StatelessWidget {
  final double height;

  const HR({super.key, this.height = 1});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 2 * height),
        child: ColoredBox(
            color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black).withOpacity(0.5),
            child: SizedBox(height: height)));
  }
}

class Label extends StatelessWidget {
  final String text;
  final bool softWrap;

  const Label(this.text, {super.key, this.softWrap = true});

  @override
  Widget build(BuildContext context) {
    return Text(text, softWrap: softWrap, style: Theme.of(context).textTheme.labelSmall);
  }
}

class Small extends StatelessWidget {
  final String text;
  final bool softWrap;

  const Small(this.text, {super.key, this.softWrap = true});

  @override
  Widget build(BuildContext context) {
    return Text(text, softWrap: softWrap, style: const TextStyle(fontSize: 8));
  }
}

abstract class Head extends StatelessWidget {
  final TextAlign? textAlign;
  final String text;
  final Color? color;
  final bool selectable;
  final bool softWrap;
  final FontWeight? fontWeight;

  const Head(this.text,
      {super.key, this.textAlign, this.fontWeight, this.color, this.selectable = false, this.softWrap = false});

  @override
  Widget build(BuildContext context) {
    TextStyle? style = getTextStyle(context);
    style ??= Theme.of(context).textTheme.titleMedium;
    if (selectable) {
      return SelectableText(text,
          style: TextStyle(color: color, fontSize: style!.fontSize, fontWeight: fontWeight), textAlign: textAlign);
    }
    return Text(text,
        overflow: !softWrap ? TextOverflow.ellipsis : null,
        softWrap: softWrap,
        style: TextStyle(color: color, fontSize: style!.fontSize, fontWeight: fontWeight),
        textAlign: textAlign);
  }

  TextStyle? getTextStyle(BuildContext context);
}

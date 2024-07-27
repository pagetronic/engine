import 'package:engine/blobs/images.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/utils/fx.dart';
import 'package:engine/utils/sizer.dart';
import 'package:engine/utils/widgets/form/form_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';

class SimpleButton extends TextButton {
  SimpleButton({super.key, AlignmentGeometry? alignment, required super.onPressed, required super.child})
      : super(
          style: ButtonStyle(
            alignment: alignment,
            padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
              const EdgeInsets.all(4),
            ),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0.0),
              ),
            ),
          ),
        );
}

class Input extends StatelessWidget {
  final TextEditingController controller = TextEditingController();
  final String title;
  final bool obscureText;
  final void Function(String value)? onSubmit;
  final Widget? icon;
  final void Function(String value)? onChanged;
  late final FocusNode focusNode;
  final ValueStore<String> valueStore = ValueStore("");
  final List<String>? autofillHints;
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  Input(this.title,
      {super.key,
      this.obscureText = false,
      FocusNode? focusNode,
      this.onSubmit,
      this.icon,
      this.onChanged,
      String? initial,
      this.autofillHints}) {
    if (initial != null) {
      controller.text = initial;
      valueStore.value = initial;
    }
    this.focusNode = focusNode ?? FocusNode();
    this.focusNode.addListener(() {
      if (!this.focusNode.hasFocus && onChanged != null) {
        if (valueStore.value != controller.value.text) {
          valueStore.value == controller.value.text;
          onChanged!(controller.value.text.trim());
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: errorMessage,
      builder: (context, errorMessage, child) {
        return Padding(
            padding: EdgeInsets.only(bottom: errorMessage != null ? 5 : 0),
            child: TextField(
                autofillHints: autofillHints,
                focusNode: focusNode,
                onSubmitted: (value) {
                  if (onSubmit != null) {
                    onSubmit!(value.trim());
                  }
                },
                textCapitalization: TextCapitalization.sentences,
                obscureText: obscureText,
                controller: controller,
                decoration: InputDecoration(
                  errorText: errorMessage,
                  border: const OutlineInputBorder(),
                  suffixIcon: icon,
                  labelText: title,
                )));
      },
    );
  }

  String get value => controller.text;

  set value(String? text) => controller.text = (text ?? "");

  void error(String? message, AppLocalizations locale) {
    message = FormUtils.translate(message, locale);
    errorMessage.value = message;
  }
}

class Area extends StatelessWidget {
  final TextEditingController controller = TextEditingController();
  final String title;
  final void Function(String value)? onChanged;
  final FocusNode focusNode = FocusNode();
  final ValueStore<String> valueStore = ValueStore("");

  Area(this.title, {super.key, this.onChanged, String? initial}) {
    if (initial != null) {
      controller.text = initial;
      valueStore.value = initial;
    }
    focusNode.addListener(() {
      if (!focusNode.hasFocus && onChanged != null) {
        if (valueStore.value != controller.value.text) {
          valueStore.value == controller.value.text;
          onChanged!(controller.value.text.trim());
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
        focusNode: focusNode,
        minLines: 2,
        maxLines: 1000,
        controller: controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: title,
        ));
  }

  String value() {
    return controller.value.text;
  }
}

class DateInput extends StatelessWidget {
  final TextEditingController controller = TextEditingController();
  final String title;

  final DateTime? firstDate;
  final DateTime? lastDate;

  DateInput(this.title, {super.key, this.firstDate, this.lastDate});

  @override
  Widget build(BuildContext context) {
    DateTime firstDate = this.firstDate != null ? this.firstDate! : DateTime.utc(1500);
    DateTime lastDate = this.lastDate != null ? this.lastDate! : DateTime.utc(3000);
    TextField input = TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: title,
        ));
    DateFormat dateFormat = DateFormat.yMd(Language.of(context).localeName);
    return Listener(
      onPointerDown: (event) {
        showDatePicker(
                context: context,
                initialDate: dateFormat.parseUtc(controller.text),
                firstDate: firstDate,
                lastDate: lastDate)
            .then((value) {
          if (value != null) {
            controller.text = dateFormat.format(value);
          }
        });
      },
      child: input,
    );
  }

  String value() {
    return controller.value.text;
  }
}

class Select<T> extends StatelessWidget {
  final ValueNotifier<T?> controller = ValueNotifier(null);
  final Map<T, String> options;
  final dynamic initial;
  final String label;

  Select({super.key, required this.options, required this.label, this.initial});

  @override
  Widget build(BuildContext context) {
    return DropdownMenu(
      key: key,
      label: Text(label),
      expandedInsets: const EdgeInsets.all(0),
      onSelected: (value) {
        controller.value = value;
      },
      dropdownMenuEntries: getDropdownMenuEntries(options),
      initialSelection: initial != null ? options[initial] : null,
    );
  }

  T? value() {
    return controller.value;
  }

  List<DropdownMenuEntry> getDropdownMenuEntries(options) {
    List<DropdownMenuEntry> dropdownMenuEntries = [];
    for (T key in options.keys) {
      dropdownMenuEntries.add(DropdownMenuEntry(value: key, label: options[key]!));
    }
    return dropdownMenuEntries;
  }
}

class Explain extends StatefulWidget {
  final Widget widget;
  final double maxWidth;
  final double horizontalSpacing;
  final double verticalSpacing;

  final String explains;

  const Explain(this.widget, this.explains,
      {super.key, this.maxWidth = double.infinity, this.horizontalSpacing = 15, this.verticalSpacing = 5});

  @override
  State<StatefulWidget> createState() {
    return ExplainState();
  }
}

class ExplainState extends State<Explain> {
  @override
  Widget build(BuildContext context) {
    return SizerWidget(
        sizes: [widget.maxWidth],
        builder: (context, maxSize) {
          if (widget.maxWidth == maxSize) {
            return Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.widget,
                SizedBox(height: widget.verticalSpacing),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                        style: const TextStyle(fontSize: 12), widget.explains, textWidthBasis: TextWidthBasis.parent))
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 60, child: widget.widget),
              SizedBox(width: widget.horizontalSpacing),
              Flexible(
                flex: 40,
                child: Text(
                  widget.explains,
                  textWidthBasis: TextWidthBasis.parent,
                ),
              ),
            ],
          );
        });
  }
}

class AutocompleteItem extends StatelessWidget {
  final String title;
  final int index;
  final IconData? icon;
  final String? image;
  final String? infos;
  final Color? color;
  final void Function() onSelected;

  const AutocompleteItem(
      {super.key,
      required this.index,
      required this.title,
      this.icon,
      this.color,
      required this.onSelected,
      this.image,
      this.infos});

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (BuildContext context) {
      final bool highlight = AutocompleteHighlightedOption.of(context) == index;
      if (highlight) {
        SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
          Scrollable.ensureVisible(context, alignment: 0.5);
        });
      }
      return InkWell(
          onTap: () {
            onSelected();
          },
          child: Container(
            color: highlight ? Colors.grey.withOpacity(0.2) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(width: 1, color: Colors.grey),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (image != null) ImageWidget.src(image!, format: ImageFormat.png32x32),
                  if (icon != null) Icon(icon, color: color, size: 32),
                  if (icon != null || image != null) const SizedBox(width: 5),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (infos != null)
                          Text(
                            infos!,
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ));
    });
  }
}

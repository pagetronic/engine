import 'package:engine/api/utils/json.dart';
import 'package:engine/api/utils/range.dart';
import 'package:engine/data/settings.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/utils/lists/lists_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateListFilter extends StatefulWidget {
  final void Function(DateTimeRangeNullable? newRange) onChange;
  final void Function(bool collapse) onCollapse;
  final ValueNotifier<bool> collapse = ValueNotifier(true);
  final ValueNotifier<DateTimeRangeNullable?> range = ValueNotifier(null);

  DateListFilter(
      {super.key,
      required this.onChange,
      DateTimeRangeNullable? range,
      required this.onCollapse,
      required bool collapse}) {
    this.collapse.value = collapse;
    this.range.value = range;
  }

  @override
  State<StatefulWidget> createState() {
    return DateListFilterState();
  }
}

class DateListFilterState extends State<DateListFilter> {
  @override
  Widget build(BuildContext context) {
    AppLocalizations locale = Language.of(context);
    DateFormat dateFormat = DateFormat.yMd(Language.of(context).localeName);

    DateTime initialDate = DateTime.now();
    if (widget.range.value != null) {
      initialDate = widget.range.value!.start ?? initialDate;
    }

    return Container(
      constraints: const BoxConstraints(minWidth: double.maxFinite),
      decoration: widget.collapse.value
          ? null
          : StyleListView.getOddEvenBoxDecoration(0, color: Theme.of(context).scaffoldBackgroundColor, shadow: [
              BoxShadow(color: Theme.of(context).shadowColor, blurRadius: 3, offset: const Offset(0, -2.8)),
            ]),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Material(
            color: Colors.transparent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (!widget.collapse.value) const SizedBox(width: 3),
                if (!widget.collapse.value)
                  InkWell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      child: Text(
                        widget.range.value?.start == null
                            ? locale.range_today
                            : locale.range_from(dateFormat.format(widget.range.value!.start!)),
                      ),
                    ),
                    onTap: () {
                      showDatePicker(
                        context: context,
                        initialDate: widget.range.value?.end != null
                            ? widget.range.value!.end!.add(const Duration(days: -1))
                            : initialDate,
                        firstDate: initialDate.add(Duration(days: (-500 * 365.25).toInt())),
                        lastDate: widget.range.value?.end != null
                            ? widget.range.value!.end!.add(const Duration(days: -1))
                            : initialDate.add(Duration(days: (500 * 365.25).toInt())),
                      ).then((value) {
                        widget.range.value = DateTimeRangeNullable(start: value, end: widget.range.value?.end);
                        TempDataStore.put(
                            "range", "${widget.range.value?.start?.toJson()}/${widget.range.value?.end?.toJson()}");
                        widget.onChange(widget.range.value);
                      });
                    },
                  ),
                if (!widget.collapse.value) const Icon(Icons.chevron_right, size: 12),
                if (!widget.collapse.value)
                  InkWell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      child: Text(
                        widget.range.value?.end == null
                            ? locale.range_infinite
                            : locale.range_to(dateFormat.format(widget.range.value!.end!)),
                      ),
                    ),
                    onTap: () {
                      showDatePicker(
                        context: context,
                        initialDate: widget.range.value?.start != null
                            ? widget.range.value!.start!.add(const Duration(days: 1))
                            : initialDate,
                        firstDate: widget.range.value?.start != null
                            ? widget.range.value!.start!.add(const Duration(days: 1))
                            : initialDate.add(Duration(days: (-500 * 365.25).toInt())),
                        lastDate: initialDate.add(Duration(days: (500 * 365.25).toInt())),
                      ).then((value) {
                        widget.range.value = DateTimeRangeNullable(start: widget.range.value?.start, end: value);
                        TempDataStore.put(
                            "range", "${widget.range.value?.start?.toJson()}/${widget.range.value?.end?.toJson()}");

                        widget.onChange(widget.range.value);
                      });
                    },
                  ),
                Padding(
                  padding: EdgeInsets.only(top: widget.collapse.value ? 6 : 0, right: widget.collapse.value ? 6 : 0),
                  child: Material(
                    borderRadius: const BorderRadius.all(Radius.circular(3)),
                    elevation: widget.collapse.value ? 6 : 0,
                    color: widget.collapse.value ? Theme.of(context).scaffoldBackgroundColor : Colors.transparent,
                    child: InkWell(
                        onTap: () {
                          setState(() {
                            widget.collapse.value = !widget.collapse.value;
                          });
                          widget.onCollapse(widget.collapse.value);
                          if (widget.collapse.value && widget.range.value != null) {
                            widget.range.value = null;
                            TempDataStore.remove("range");
                            widget.onChange(null);
                          }
                        },
                        child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.calendar_month, size: 16))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    widget.range.addListener(rangeChange);
    widget.collapse.addListener(collapseChange);

    if (widget.range.value == null) {
      String valueRange = TempDataStore.get("range", "");
      if (valueRange != "") {
        List<String> values = valueRange.split("/");
        if (values.first == "null" && values.last == "null") {
          TempDataStore.remove("range");
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              widget.range.value = values.first == "null" && values.last == "null"
                  ? null
                  : DateTimeRangeNullable(
                      start: values.first == "null" ? null : DateTime.parse(values.first),
                      end: values.last == "null" ? null : DateTime.parse(values.last),
                    );
              widget.collapse.value = values.first == "null" && values.last == "null";
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    widget.range.removeListener(rangeChange);
    widget.collapse.addListener(collapseChange);
    super.dispose();
  }

  void rangeChange() {
    widget.onChange(widget.range.value);
  }

  void collapseChange() {
    widget.onCollapse(widget.collapse.value);
  }
}

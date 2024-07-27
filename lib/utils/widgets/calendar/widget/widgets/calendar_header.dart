// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:engine/utils/widgets/calendar/widget/customization/header_style.dart';
import 'package:engine/utils/widgets/calendar/widget/shared/utils.dart' show CalendarFormat, DayBuilder;
import 'package:engine/utils/widgets/calendar/widget/widgets/custom_icon_button.dart';
import 'package:engine/utils/widgets/calendar/widget/widgets/format_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class CalendarHeader extends StatelessWidget {
  final dynamic locale;
  final DateTime focusedMonth;
  final CalendarFormat calendarFormat;
  final HeaderStyle headerStyle;
  final VoidCallback onLeftChevronTap;
  final VoidCallback onRightChevronTap;
  final VoidCallback onHeaderTap;
  final ValueChanged<CalendarFormat> onFormatButtonTap;
  final Map<CalendarFormat, String> availableCalendarFormats;
  final DayBuilder? headerTitleBuilder;

  const CalendarHeader({
    super.key,
    this.locale,
    required this.focusedMonth,
    required this.calendarFormat,
    required this.headerStyle,
    required this.onLeftChevronTap,
    required this.onRightChevronTap,
    required this.onHeaderTap,
    required this.onFormatButtonTap,
    required this.availableCalendarFormats,
    this.headerTitleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final text =
        headerStyle.titleTextFormatter?.call(focusedMonth, locale) ?? DateFormat.yMMMM(locale).format(focusedMonth);

    return Container(
      decoration: headerStyle.decoration,
      margin: headerStyle.headerMargin,
      padding: headerStyle.headerPadding,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          if (headerStyle.leftChevronVisible)
            CustomIconButton(
              icon: headerStyle.leftChevronIcon,
              onTap: onLeftChevronTap,
              margin: headerStyle.leftChevronMargin,
              padding: headerStyle.leftChevronPadding,
            ),
          Expanded(
            child: headerTitleBuilder?.call(context, focusedMonth) ??
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onHeaderTap,
                    child: Text(
                      text,
                      style: headerStyle.titleTextStyle,
                      textAlign: headerStyle.titleCentered ? TextAlign.center : TextAlign.start,
                    ),
                  ),
                ),
          ),
          if (headerStyle.formatButtonVisible && availableCalendarFormats.length > 1)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: FormatButton(
                onTap: onFormatButtonTap,
                availableCalendarFormats: availableCalendarFormats,
                calendarFormat: calendarFormat,
                decoration: headerStyle.formatButtonDecoration,
                padding: headerStyle.formatButtonPadding,
                textStyle: headerStyle.formatButtonTextStyle,
                showsNextFormat: headerStyle.formatButtonShowsNext,
              ),
            ),
          if (headerStyle.rightChevronVisible)
            CustomIconButton(
              icon: headerStyle.rightChevronIcon,
              onTap: onRightChevronTap,
              margin: headerStyle.rightChevronMargin,
              padding: headerStyle.rightChevronPadding,
            ),
        ],
      ),
    );
  }
}

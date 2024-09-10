import 'dart:core';

import 'package:engine/lng/language.dart';
import 'package:engine/utils/defer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class Since extends StatefulWidget {
  final DateTime? date;
  final String? isoString;
  final String Function(String since, String date)? locale;
  final TextStyle? style;

  const Since({super.key, this.isoString, this.date, this.locale, this.style});

  @override
  SinceState createState() => SinceState();

  static String formatSince(BuildContext context, DateTime date, {int level = 2}) {
    const double daysPerYear = 365.24225;
    const double perSecond = 1000;
    const double perMinute = 60 * perSecond;
    const double perHours = 60 * perMinute;
    const double perDay = 24 * perHours;
    const double perWeek = 7 * perDay;
    final double perMonth = ((daysPerYear / 12) * perDay).floorToDouble();
    final double perYear = (daysPerYear * perDay).floorToDouble();

    AppLocalizations locale = Language.of(context);
    int durationInit = DateTime.now().millisecondsSinceEpoch - date.millisecondsSinceEpoch;

    if (durationInit < 60000 && durationInit > -60000) {
      return locale.since_now(durationInit < 0 ? "past" : "future");
    }
    bool past = durationInit < 0;
    double durationMillis = (durationInit).abs().toDouble();

    double yearsD = (durationMillis / perYear).floorToDouble();
    durationMillis = durationMillis - (yearsD * perYear);

    double monthsD = (durationMillis / perMonth).floorToDouble();
    durationMillis = durationMillis - (monthsD * perMonth);

    double weeksD = (durationMillis / perWeek).floorToDouble();
    durationMillis = durationMillis - (weeksD * perWeek);

    double daysD = (durationMillis / perDay).floorToDouble();
    durationMillis = durationMillis - (daysD * perDay);

    double hoursD = (durationMillis / perHours).floorToDouble();
    durationMillis = durationMillis - (hoursD * perHours);

    double minutesD = (durationMillis / perMinute).floorToDouble();
    durationMillis = durationMillis - (minutesD * perMinute);

    int years = yearsD.toInt();
    int months = monthsD.toInt();
    int weeks = weeksD.toInt();
    int days = daysD.toInt();
    int hours = hoursD.toInt();
    int minutes = minutesD.toInt();

    // years + "/" + months + "/" + weeks + "/" + days + "/" + hours + "/" +
    // minutes + "/" + seconds;

    List<String> sinces = [];

    for (int i = 0; i < level; i++) {
      if (years > 0) {
        sinces.add(locale.since_years(years));
        years = 0;
      } else if (months > 0) {
        sinces.add(locale.since_months(months));
        months = 0;
      } else if (weeks > 0) {
        sinces.add(locale.since_weeks(weeks));
        weeks = 0;
      } else if (days > 0) {
        sinces.add(locale.since_days(days));
        days = 0;
      } else if (hours > 0) {
        sinces.add(locale.since_hours(hours));
        hours = 0;
      } else if (minutes > 0) {
        sinces.add(locale.since_minutes(minutes));
        minutes = 0;
      }
    }
    String since = "";
    if (sinces.length > 1) {
      for (int index = 0; index < sinces.length; index++) {
        if (index > 0) {
          since += (index > 0 && index == sinces.length - 1) ? " ${locale.since_and} " : ", ";
        }
        since += sinces[index];
      }
    } else if (sinces.isNotEmpty) {
      since = sinces[0];
    }
    return locale.since(!past ? "future" : "past", since);
  }
}

class SinceState extends State<Since> {
  DateTime? date;

  @override
  Widget build(BuildContext context) {
    if (widget.isoString == null && widget.date == null) {
      return const SizedBox.shrink();
    }
    date = date ?? widget.date ?? DateTime.parse(widget.isoString!);
    if (date == null) {
      return const SizedBox.shrink();
    }
    String text = Since.formatSince(context, date!);
    if (widget.locale != null) {
      text = widget.locale!(text, DateFormat.yMMMMd(Language.of(context).localeName).format(date!));
    }
    return Text(text, style: widget.style, textAlign: TextAlign.left);
  }

  final Deferrer deferrer = Deferrer(1000);

  void refresh() {
    setState(() {
      date = null;
    });
    deferrer.abort();
    deferrer.defer(refresh);
  }

  @override
  void initState() {
    refresh();
    super.initState();
  }

  @override
  void dispose() {
    deferrer.abort();
    super.dispose();
  }
}

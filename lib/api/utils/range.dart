import 'package:engine/api/utils/json.dart';
import 'package:engine/utils/fx.dart';
import 'package:intl/intl.dart';

class DateTimeRangeNullable {
  DateTime? start;
  DateTime? end;

  DateTimeRangeNullable({this.start, this.end});

  get query {
    return Uri.encodeComponent(
        "${start != null ? Fx.dateFormatIso.format(start!) : ''}>${end != null ? Fx.dateFormatIso.format(end!) : ''}");
  }

  filter(Json obj) {
    if (start == null && end == null) {
      return true;
    }
    bool ok = false;
    if (start != null) {
      ok = obj.dateNotNull.isAfter(start!) || obj.dateNotNull.isAtSameMomentAs(start!);
    }
    if (ok && end != null) {
      ok = obj.dateNotNull.isBefore(end!);
    }
    return ok;
  }

  bool between(DateTime? value) {
    if (value == null || start == null || end == null) {
      return false;
    }
    return (value.isAfter(start!) || value.isAtSameMomentAs(start!)) && value.isBefore(end!);
  }

  bool inRange(DateTime date) {
    return (start != null ? date.isAfter(start!) : true) && (end != null ? date.isBefore(end!) : true);
  }
}

import 'package:engine/api/utils/json.dart';
import 'package:intl/intl.dart';

class DateTimeRangeNullable {
  DateTime? start;
  DateTime? end;

  DateTimeRangeNullable({this.start, this.end});

  get query {
    DateFormat format = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS+0000");
    return Uri.encodeComponent(
        "${start != null ? format.format(start!) : ''}>${end != null ? format.format(end!) : ''}");
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

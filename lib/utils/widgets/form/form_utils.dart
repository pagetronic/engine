import 'package:engine/lng/language.dart';

class FormUtils {
  static String? translate(String? message, AppLocalizations locale) {
    if (message == null) {
      return null;
    }
    switch (message) {
      case "EMPTY":
        return locale.field_empty;
      case "INCONSISTENT":
        return locale.field_inconsistent;
      case "EXIST":
        return locale.field_exist;
      case "TOO_SHORT":
        return locale.field_too_short;
      case "TOO_LONG":
        return locale.field_too_long;
      case "DO_NOT_MATCH":
        return locale.field_do_not_match;
    }
    return message;
  }
}

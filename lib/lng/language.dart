import 'package:engine/lng/base_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

export 'package:engine/lng/base_localizations.dart';
export 'package:flutter_localizations/flutter_localizations.dart';

class Language {
  static List<Locale> supportedLocales() {
    return AppLocalizations.supportedLocales;
  }

  static AppLocalizations of(BuildContext context) {
    return AppLocalizations.of(context)!;
  }
}

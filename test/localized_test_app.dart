import 'package:flutter/material.dart';
import 'package:smart_budget/l10n/generated/app_localizations.dart';

Widget localizedTestApp({
  required Widget home,
  Locale locale = const Locale('ko'),
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

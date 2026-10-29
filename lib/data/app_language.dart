import 'package:flutter/widgets.dart';

/// Languages the app can show. Ukrainian is the fallback.
enum AppLanguage {
  uk,
  en;

  static const fallback = AppLanguage.uk;

  String get code => name;

  Locale get locale => Locale(code);

  /// Always in that language, so a parent can find it either way.
  String get nativeName => switch (this) {
    AppLanguage.uk => 'Українська',
    AppLanguage.en => 'English',
  };

  static AppLanguage? tryParse(String? code) {
    switch (code?.toLowerCase()) {
      case 'uk':
        return AppLanguage.uk;
      case 'en':
        return AppLanguage.en;
      default:
        return null;
    }
  }

  /// Device language when it is Ukrainian or English, otherwise Ukrainian.
  static AppLanguage fromDevice(Locale locale) {
    return tryParse(locale.languageCode) ?? fallback;
  }
}

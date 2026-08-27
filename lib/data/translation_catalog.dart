import 'dart:convert';

import 'package:flutter/services.dart';

import 'models.dart';

class TranslationCatalog {
  static const assetPath = 'assets/data/translations.json';

  static Future<List<TranslationPair>> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final list = jsonDecode(raw) as List;
    return [
      for (final item in list)
        TranslationPair.fromJson(item as Map<String, dynamic>),
    ];
  }
}

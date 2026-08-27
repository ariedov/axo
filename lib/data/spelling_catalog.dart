import 'dart:convert';

import 'package:flutter/services.dart';

import 'models.dart';

class SpellingCatalog {
  static const assetPath = 'assets/data/spelling_words.json';

  static Future<List<SpellingWord>> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final list = jsonDecode(raw) as List;
    return [
      for (final item in list)
        SpellingWord.fromJson(item as Map<String, dynamic>),
    ];
  }
}

import '../../../../core/database/database_helper.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../models/ayah_model.dart';

abstract class QuranReaderLocalDataSource {
  Future<List<AyahModel>> getAyahsBySurahId(int surahId);
}

class QuranReaderLocalDataSourceImpl implements QuranReaderLocalDataSource {
  final DatabaseHelper databaseHelper;

  QuranReaderLocalDataSourceImpl({required this.databaseHelper});

  static String stripBasmalaPrefix(String text) {
    final cleanText = text.replaceFirst(RegExp(r'^﻿?\s*'), '');
    final normalized = ArabicNormalizer.normalize(cleanText);
    if (normalized.startsWith('بسم الله الرحمن الرحيم')) {
      final basmalaRegex = RegExp(
        r'^(?:بِ?سْ?مِ?\s*ٱ?للَّ?هِ?\s*ٱ?لرَّ?حْ?مَ?ـٰ?نِ?\s*ٱ?لرَّ?حِ?ي?مِ?\s*)',
      );
      final match = basmalaRegex.firstMatch(cleanText);
      if (match != null && match.end > 0) {
        return cleanText.substring(match.end).trim();
      }
    }
    return cleanText.trim();
  }

  @override
  Future<List<AyahModel>> getAyahsBySurahId(int surahId) async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ayahs',
      where: 'surah_id = ?',
      whereArgs: [surahId],
      orderBy: 'verse_number ASC',
    );
    final list = maps.map((map) => AyahModel.fromMap(map)).toList();
    if (surahId != 1 && surahId != 9 && list.isNotEmpty && list.first.verseNumber == 1) {
      final first = list.first;
      final strippedText = stripBasmalaPrefix(first.textUthmani);
      list[0] = AyahModel(
        id: first.id,
        surahId: first.surahId,
        verseNumber: first.verseNumber,
        textUthmani: strippedText,
        pageNumber: first.pageNumber,
        juz: first.juz,
      );
    }
    return list;
  }
}

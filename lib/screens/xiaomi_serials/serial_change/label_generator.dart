import 'dart:math';
import 'package:intl/intl.dart';

/// Generates new serial labels based on operator format.
class LabelGenerator {
  static const _vodafoneMonth = {
    1:'E',2:'F',3:'M',4:'A',5:'Y',6:'J',
    7:'L',8:'G',9:'S',10:'O',11:'N',12:'D',
  };

  static List<String> generate({
    required String operatorName,
    required DateTime date,
    required int totalUnits,
    required String? article,
    required String? sapClient,
    required String? codeLetter,
    required int startSequence,
  }) {
    if (totalUnits <= 0) return const [];
    final op = operatorName.trim().toLowerCase();
    final sap = (sapClient ?? '').trim();

    if (op.contains('orange')) {
      return _build(DateFormat('yyyyMMdd').format(date), _desc(article, sapClient, codeLetter, 'OR'), totalUnits, startSequence);
    }
    if (op.contains('vodafone') || sap.isNotEmpty) {
      final y = date.year % 10;
      final m = _vodafoneMonth[date.month] ?? 'X';
      final d = date.day.toString().padLeft(2, '0');
      return _build('$sap$y$m$d', '', totalUnits, startSequence);
    }
    return _build(DateFormat('yyyyMMdd').format(date), _desc(article, sapClient, codeLetter, 'TIPO'), totalUnits, startSequence);
  }

  static List<String> _build(String prefix, String desc, int total, int start) {
    final pad = max(5, (start + total - 1).toString().length);
    return List.generate(total, (i) => '$prefix$desc${(start + i).toString().padLeft(pad, '0')}');
  }

  static String _desc(String? a, String? s, String? c, String fallback) {
    for (final v in [c, a, s]) {
      final t = (v ?? '').replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
      if (t.isNotEmpty) return t;
    }
    return fallback;
  }
}

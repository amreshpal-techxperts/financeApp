// ══════════════════════════════════════════════════════════════════════
// import_parser.dart  — REPLACE existing file with this
// ══════════════════════════════════════════════════════════════════════
//
// DESIGN PHILOSOPHY (new):
//   • System is PURELY keyword-driven
//   • Description se account kabhi create/guess nahi hota
//   • Keyword match → account assign
//   • No match      → blank (user manually assign karega)
//   • Global keywords → tag assign (independent)
// ══════════════════════════════════════════════════════════════════════

import 'package:csv/csv.dart';
import 'import_models.dart';
import 'dart:convert';

// ── Column Synonyms ────────────────────────────────────────────────────
const kDateSynonyms = [
  'date', 'txn date', 'transaction date', 'value date', 'posting date',
  'tran date', 'entry date', 'book date', 'trade date', 'settlement date',
  'process date', 'trans date', 'chq date',
];
const kCreditSynonyms = [
  'credit', 'deposit', 'credit amount', 'deposit amount', 'received',
  'credit(cr)', 'deposit amt', 'credit amt', 'cr amount', 'inward',
  'amt in', 'amount in', 'credit(inr)',
];
const kDebitSynonyms = [
  'debit', 'withdrawal', 'debit amount', 'withdraw', 'payment',
  'debit(dr)', 'withdrawal amt', 'debit amt', 'dr amount', 'amt out',
  'amount out', 'debit(inr)',
];
const kDescSynonyms = [
  'description', 'narration', 'particulars', 'details', 'remarks',
  'transaction details', 'txn description', 'transaction narration',
  'reference', 'chq no / ref no', 'transaction remark',
];

// ── Column Detection ───────────────────────────────────────────────────
class _ColIdx {
  final int date, desc, debit, credit;
  const _ColIdx({
    required this.date,
    required this.desc,
    required this.debit,
    required this.credit,
  });
}

_ColIdx? _detectColumns(List<dynamic> header) {
  int? dateIdx, descIdx, debitIdx, creditIdx;
  for (int i = 0; i < header.length; i++) {
    final h = header[i].toString().toLowerCase().trim();
    if (dateIdx == null && kDateSynonyms.any((s) => h == s || h.contains(s))) {
      dateIdx = i;
      continue;
    }
    if (descIdx == null && kDescSynonyms.any((s) => h == s || h.contains(s))) {
      descIdx = i;
      continue;
    }
    if (debitIdx == null && kDebitSynonyms.any((s) => h == s || h.contains(s))) {
      debitIdx = i;
      continue;
    }
    if (creditIdx == null && kCreditSynonyms.any((s) => h == s || h.contains(s))) {
      creditIdx = i;
    }
  }
  if (dateIdx == null || descIdx == null || debitIdx == null || creditIdx == null) {
    return null;
  }
  return _ColIdx(date: dateIdx, desc: descIdx, debit: debitIdx, credit: creditIdx);
}

int? _findHeaderRowIndex(List<List<dynamic>> rows) {
  for (int i = 0; i < rows.length && i < 15; i++) {
    if (_detectColumns(rows[i]) != null) return i;
  }
  return null;
}

// ══════════════════════════════════════════════════════════════════════
// MAIN PARSER
// ══════════════════════════════════════════════════════════════════════
ParseResult doParse(ParseParams p) {
  // ── CSV Parse ────────────────────────────────────────────────────────
  List<List<dynamic>> rows;
  try {
    final content = p.csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    rows = const CsvToListConverter().convert(content, eol: '\n');
  } catch (_) {
    return const ParseResult(
      rows: [], dupCount: 0, invalidCount: 0,
      warnings: ['CSV parse failed.'],
    );
  }

  final cleanRows = rows
      .where((r) => r.isNotEmpty && r.join('').trim().isNotEmpty)
      .toList();

  if (cleanRows.isEmpty) {
    return const ParseResult(
      rows: [], dupCount: 0, invalidCount: 0, warnings: ['CSV is empty.'],
    );
  }

  final headerIdx = _findHeaderRowIndex(cleanRows);
  if (headerIdx == null) {
    return ParseResult(
      rows: [], dupCount: 0, invalidCount: 0,
      warnings: ['Could not detect columns. First row: "${cleanRows[0].join(' | ')}"'],
    );
  }

  final cols = _detectColumns(cleanRows[headerIdx])!;

  // ── Pre-build keyword lookup structures ──────────────────────────────
  //
  //  accountById   : id → account map
  //  accountKwMap  : accountId → keywords  (non-person/vendor types)
  //  partyKwMap    : accountId → keywords  (person/vendor types)
  //  globalKwMap   : tagId     → keywords  (from global_keywords table)
  //  tagIdToName   : tagId     → tag name
  //
  const partyTypes = {'person', 'vendor'};

  final accountById = <int, Map<String, dynamic>>{
    for (final a in p.accounts)
      if (a['id'] != null) a['id'] as int: a,
  };

  final accountKwMap = <int, List<String>>{};
  final partyKwMap   = <int, List<String>>{};

  for (final entry in p.keywordsMap.entries) {
    final acc = accountById[entry.key];
    if (acc == null) continue;
    final type = acc['type'] as String? ?? '';
    if (partyTypes.contains(type)) {
      partyKwMap[entry.key] = entry.value;
    } else {
      accountKwMap[entry.key] = entry.value;
    }
  }

  // ── Process rows ─────────────────────────────────────────────────────
  final result     = <PRowData>[];
  int dupCount     = 0;
  int invalidCount = 0;
  final warnings   = <String>[];

  for (int i = headerIdx + 1; i < cleanRows.length; i++) {
    final row = cleanRows[i];
    if (row.length <= cols.credit) { invalidCount++; continue; }

    final dateStr = row[cols.date].toString().trim();
    final desc    = row[cols.desc].toString().trim();
    final debit   = double.tryParse(
      row[cols.debit].toString().replaceAll(RegExp(r'[, ]'), '')) ?? 0;
    final credit  = double.tryParse(
      row[cols.credit].toString().replaceAll(RegExp(r'[, ]'), '')) ?? 0;

    if (dateStr.isEmpty)           { invalidCount++; continue; }
    if (debit == 0 && credit == 0) { invalidCount++; continue; }

    final amount  = debit > 0 ? debit : credit;
    final txHash  = generateTxHash(dateStr, desc, amount);
    final isDup   = p.existingTxKeys.contains(txHash);
    if (isDup) dupCount++;

    // ── KEYWORD MATCHING ───────────────────────────────────────────────
    final result3 = _matchKeywords(
      description   : desc,
      accountKwMap  : accountKwMap,
      partyKwMap    : partyKwMap,
      globalKwMap   : p.globalKeywordsMap,
      tagIdToName   : p.tagIdToName,
      accountById   : accountById,
      fallbackTags  : p.tags,
    );

    result.add(PRowData(
      date        : dateStr,
      txHash      : txHash,
      description : desc,
      cleanedName : result3.matchedName ?? '',   // only if keyword matched
      debit       : debit,
      credit      : credit,
      accountId   : result3.accountId,
      accountName : result3.matchedName,          // null = unassigned
      accountType : result3.accountType ?? 'expense',
      tag         : result3.tagName,
      isNewAccount: false,                        // NEVER auto-create
      isDuplicate : isDup,
      skip        : isDup,
    ));
  }

  return ParseResult(
    rows         : result,
    dupCount     : dupCount,
    invalidCount : invalidCount,
    warnings     : warnings,
  );
}

// ══════════════════════════════════════════════════════════════════════
// KEYWORD MATCH ENGINE
// ══════════════════════════════════════════════════════════════════════

class _MatchResult {
  final int?    accountId;
  final String? matchedName;
  final String? accountType;
  final String? tagName;

  const _MatchResult({
    this.accountId,
    this.matchedName,
    this.accountType,
    this.tagName,
  });
}

_MatchResult _matchKeywords({
  required String description,
  required Map<int, List<String>> accountKwMap,
  required Map<int, List<String>> partyKwMap,
  required Map<int, List<String>> globalKwMap,
  required Map<int, String>       tagIdToName,
  required Map<int, Map<String, dynamic>> accountById,
  required List<String>           fallbackTags,
}) {
  final desc = _normalize(description);

  int?    accountId;
  String? matchedName;
  String? accountType;
  String? tagName;
  int     longestAccountKw = 0;
  int     longestPartyKw   = 0;
  int     longestGlobalKw  = 0;

  // ── P1: Account Keywords (expense / income / bank / cash / wallet) ──
  for (final entry in accountKwMap.entries) {
    for (final kw in entry.value) {
      final kwL = kw.toLowerCase().trim();
      if (kwL.length < 2)            continue;
      if (!desc.contains(kwL))       continue;
      if (kwL.length <= longestAccountKw) continue;

      longestAccountKw = kwL.length;
      final acc = accountById[entry.key]!;
      accountId   = entry.key;
      matchedName = acc['name'] as String;
      accountType = acc['type'] as String;
    }
  }

  // ── P2: Party Keywords (person / vendor) ────────────────────────────
  //    Only if P1 had no match
  if (accountId == null) {
    for (final entry in partyKwMap.entries) {
      for (final kw in entry.value) {
        final kwL = kw.toLowerCase().trim();
        if (kwL.length < 2)           continue;
        if (!desc.contains(kwL))      continue;
        if (kwL.length <= longestPartyKw) continue;

        longestPartyKw = kwL.length;
        final acc = accountById[entry.key]!;
        accountId   = entry.key;
        matchedName = acc['name'] as String;
        accountType = acc['type'] as String;
      }
    }
  }

  // ── P3: Global Keywords → Tag (works independently) ─────────────────
  for (final entry in globalKwMap.entries) {
    for (final kw in entry.value) {
      final kwL = kw.toLowerCase().trim();
      if (kwL.length < 2)           continue;
      if (!desc.contains(kwL))      continue;
      if (kwL.length <= longestGlobalKw) continue;

      longestGlobalKw = kwL.length;
      tagName = tagIdToName[entry.key];
    }
  }

  // If no global match, try guessTag as fallback (optional)
  tagName ??= guessTag(description.toUpperCase(), fallbackTags);

  return _MatchResult(
    accountId   : accountId,
    matchedName : matchedName,
    accountType : accountType,
    tagName     : tagName,
  );
}

String _normalize(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^\w\s]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

// ── Tag Guesser (fallback only) ────────────────────────────────────────
String? guessTag(String d, List<String> tags) {
  const keywordToTag = {
    'ZOMATO': 'Food', 'SWIGGY': 'Food', 'RESTAURANT': 'Food',
    'IRCTC': 'Travel', 'MAKEMYTRIP': 'Travel', 'UBER': 'Travel', 'OLA': 'Travel',
    'AMAZON': 'Shopping', 'FLIPKART': 'Shopping', 'MYNTRA': 'Shopping',
    'ELECTRICITY': 'Bills & Utilities', 'AIRTEL': 'Bills & Utilities',
    'JIO': 'Bills & Utilities', 'VODAFONE': 'Bills & Utilities',
    'HOSPITAL': 'Medical', 'PHARMACY': 'Medical', 'APOLLO': 'Medical',
    'NEFT': 'Transfer', 'IMPS': 'Transfer', 'RTGS': 'Transfer',
    'TRANSFER': 'Transfer', 'UPI': 'Transfer',
    'ATM': 'Others', 'CASH': 'Others',
  };

  for (final entry in keywordToTag.entries) {
    if (d.contains(entry.key)) {
      final dbTag = tags.firstWhere(
        (t) => t.toLowerCase() == entry.value.toLowerCase(),
        orElse: () => '',
      );
      if (dbTag.isNotEmpty) return dbTag;
    }
  }
  return tags.firstWhere(
    (t) => t.toLowerCase() == 'others',
    orElse: () => tags.isNotEmpty ? tags.first : null ?? '',
  );
}

// ── Date & Hash Helpers ────────────────────────────────────────────────
String normalizeDate(String s) {
  s = s.trim();
  if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) return s.substring(0, 10);
  final m = RegExp(r'^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})').firstMatch(s);
  if (m != null) {
    return '${m.group(3)}-${m.group(2)!.padLeft(2, '0')}-${m.group(1)!.padLeft(2, '0')}';
  }
  return s.toLowerCase();
}

String generateTxHash(String date, String desc, double amount) {
  final normalized =
      '${normalizeDate(date)}|${desc.toLowerCase().trim()}|${amount.toStringAsFixed(2)}';
  final bytes = utf8.encode(normalized);
  int hash = 0;
  for (final b in bytes) {
    hash = (hash * 31 + b) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
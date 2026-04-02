import 'package:csv/csv.dart';
import 'import_models.dart';

import 'dart:convert';

// ── Column Synonyms ────────────────────────────────────
const kDateSynonyms = [
  'date',
  'txn date',
  'transaction date',
  'value date',
  'posting date',
  'tran date',
  'entry date',
  'book date',
  'trade date',
  'settlement date',
  'process date',
  'trans date',
  'chq date',
];

const kCreditSynonyms = [
  'credit',
  'deposit',
  'credit amount',
  'deposit amount',
  'received',
  'credit(cr)',
  'deposit amt',
  'credit amt',
  'cr amount',
  'inward',
  'amt in',
  'amount in',
  'credit(inr)',
];

const kDebitSynonyms = [
  'debit',
  'withdrawal',
  'debit amount',
  'withdraw',
  'payment',
  'debit(dr)',
  'withdrawal amt',
  'debit amt',
  'dr amount',
  'amt out',
  'amount out',
  'debit(inr)',
];

const kDescSynonyms = [
  'description',
  'narration',
  'particulars',
  'details',
  'remarks',
  'transaction details',
  'txn description',
  'transaction narration',
  'reference',
  'chq no / ref no',
  'transaction remark',
];

// ── Column Index Finder ────────────────────────────────
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
    if (debitIdx == null &&
        kDebitSynonyms.any((s) => h == s || h.contains(s))) {
      debitIdx = i;
      continue;
    }
    if (creditIdx == null &&
        kCreditSynonyms.any((s) => h == s || h.contains(s))) {
      creditIdx = i;
    }
  }

  if (dateIdx == null ||
      descIdx == null ||
      debitIdx == null ||
      creditIdx == null) {
    return null;
  }

  return _ColIdx(
    date: dateIdx,
    desc: descIdx,
    debit: debitIdx,
    credit: creditIdx,
  );
}

int? _findHeaderRowIndex(List<List<dynamic>> rows) {
  for (int i = 0; i < rows.length && i < 15; i++) {
    print('Row $i headers: ${rows[i].map((e) => '"$e"').join(' | ')}');
    if (_detectColumns(rows[i]) != null) return i;
  }
  return null;
}

ParseResult doParse(ParseParams p) {
  List<List<dynamic>> rows;
  try {
    final content = p.csvContent
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    rows = const CsvToListConverter().convert(content, eol: '\n');

    print("row = $rows");
  } catch (_) {
    return const ParseResult(
      rows: [],
      dupCount: 0,
      invalidCount: 0,
      warnings: ['CSV parse failed.'],
    );
  }
  if (rows.isEmpty) {
    return const ParseResult(
      rows: [],
      dupCount: 0,
      invalidCount: 0,
      warnings: ['CSV is empty.'],
    );
  }
  final cleanRows = rows.where((r) {
    if (r.isEmpty) return false;
    final joined = r.join('').trim();
    return joined.isNotEmpty;
  }).toList();

  if (cleanRows.isEmpty) {
    return const ParseResult(
      rows: [],
      dupCount: 0,
      invalidCount: 0,
      warnings: ['CSV is empty.'],
    );
  }

  final headerIdx = _findHeaderRowIndex(cleanRows);
  if (headerIdx == null) {
    return ParseResult(
      rows: [],
      dupCount: 0,
      invalidCount: 0,
      warnings: [
        'Could not detect columns.\n'
            'First row found: "${cleanRows[0].join(' | ')}"',
      ],
    );
  }

  final cols = _detectColumns(cleanRows[headerIdx]);
  if (cols == null) {
    return const ParseResult(
      rows: [],
      dupCount: 0,
      invalidCount: 0,
      warnings: [
        'Could not detect columns. Expected: Date, Description, Debit, Credit headers.',
      ],
    );
  }

  final result = <PRowData>[];
  int dupCount = 0, invalid = 0;
  final warnings = <String>[];
  final batchNew = <String, Map<String, String>>{};

  for (int i = headerIdx + 1; i < cleanRows.length; i++) {
    final row = cleanRows[i];

    if (row.length <= cols.credit) {
      invalid++;
      continue;
    }

    final dateStr = row[cols.date].toString().trim();
    final desc = row[cols.desc].toString().trim();
    final debit =
        double.tryParse(
          row[cols.debit].toString().replaceAll(RegExp(r'[, ]'), ''),
        ) ??
        0;
    final credit =
        double.tryParse(
          row[cols.credit].toString().replaceAll(RegExp(r'[, ]'), ''),
        ) ??
        0;

    if (dateStr.isEmpty) {
      invalid++;
      continue;
    }
    if (debit == 0 && credit == 0) {
      invalid++;
      continue;
    }

    final amount = debit > 0 ? debit : credit;
    // final normalizedDate = normalizeDate(dateStr);
    // final amountStr = amount.toStringAsFixed(2); // "500.00" ← consistent

    final txHash = generateTxHash(dateStr, desc, amount);
    final isDup = p.existingTxKeys.contains(txHash);
    if (isDup) dupCount++;

    final cleaned = cleanName(desc);
    final normCleaned = norm(cleaned);
    final descU = desc.toUpperCase();
    final sugType = guessType(descU, debit > 0);
    final autoTag = guessTag(descU, p.tags);

    if (cleaned.isEmpty) {
      result.add(
        PRowData(
          date: dateStr,
          txHash: txHash,
          description: desc,
          cleanedName: '',
          debit: debit,
          credit: credit,
          accountType: sugType,
          tag: autoTag,
          isDuplicate: isDup,
          skip: isDup,
        ),
      );
      continue;
    }

    int? matchId;
    String? matchName, matchType;

    for (final e in p.vendorMap.entries) {
      if (descU.contains(e.key)) {
        final acc = exactFind(e.value, p.accounts);
        if (acc != null) {
          matchId = acc['id'] as int?;
          matchName = acc['name'] as String;
          matchType = acc['type'] as String;
        }
        break;
      }
    }
    if (matchId == null) {
      for (final e in p.tagMap.entries) {
        if (descU.contains(e.key)) {
          final acc = containsFind(e.value, p.accounts);
          if (acc != null) {
            matchId = acc['id'] as int?;
            matchName = acc['name'] as String;
            matchType = acc['type'] as String;
          }
          break;
        }
      }
    }

    bool isNew = false;
    if (matchId == null) {
      final existingAcc = fuzzyFind(cleaned, p.accounts);
      if (existingAcc != null) {
        matchId = existingAcc['id'] as int?;
        matchName = existingAcc['name'] as String;
        matchType = existingAcc['type'] as String;
        isNew = false;
      } else if (batchNew.containsKey(normCleaned)) {
        matchName = batchNew[normCleaned]!['name']!;
        matchType = batchNew[normCleaned]!['type']!;
        isNew = true;
      } else {
        matchName = cleaned;
        matchType = sugType;
        batchNew[normCleaned] = {'name': cleaned, 'type': sugType};
        isNew = true;
      }
    }

    result.add(
      PRowData(
        date: dateStr,
        txHash: txHash,
        description: desc,
        cleanedName: cleaned,
        debit: debit,
        credit: credit,
        accountId: matchId,
        accountName: matchName,
        accountType: matchType ?? sugType,
        tag: autoTag,
        isNewAccount: isNew,
        isDuplicate: isDup,
        skip: isDup,
      ),
    );
  }

  if (batchNew.length > 20) {
    warnings.add(
      '${batchNew.length} new accounts will be created. Tap "Review" to check types.',
    );
  }
  return ParseResult(
    rows: result,
    dupCount: dupCount,
    invalidCount: invalid,
    warnings: warnings,
  );
}

String? guessTag(String d, List<String> tags) {
  const keywordToTag = {
    'ZOMATO': 'Food',
    'SWIGGY': 'Food',
    'RESTAURANT': 'Food',
    'HOTEL': 'Food',
    'CAFE': 'Food',
    'DOMINOS': 'Food',
    'PIZZA': 'Food',
    'BURGER': 'Food',
    'DUNZO': 'Food',
    'BLINKIT': 'Food',
    'ZEPTO': 'Food',
    'BIGBASKET': 'Food',
    'IRCTC': 'Travel',
    'MAKEMYTRIP': 'Travel',
    'GOIBIBO': 'Travel',
    'REDBUS': 'Travel',
    'AIRLINE': 'Travel',
    'FLIGHT': 'Travel',
    'INDIGO': 'Travel',
    'AIRINDIA': 'Travel',
    'SPICEJET': 'Travel',
    'UBER': 'Travel',
    'OLA': 'Travel',
    'RAPIDO': 'Travel',
    'AMAZON': 'Shopping',
    'FLIPKART': 'Shopping',
    'MYNTRA': 'Shopping',
    'MEESHO': 'Shopping',
    'NYKAA': 'Shopping',
    'AJIO': 'Shopping',
    'SNAPDEAL': 'Shopping',
    'ELECTRICITY': 'Bills',
    'BESCOM': 'Bills',
    'MSEB': 'Bills',
    'TATAPOWER': 'Bills',
    'RECHARGE': 'Bills',
    'AIRTEL': 'Bills',
    'VODAFONE': 'Bills',
    'JIO': 'Bills',
    'BSNL': 'Bills',
    'GAS': 'Bills',
    'PIPED': 'Bills',
    'WATER': 'Bills',
    'SALARY': 'Salary',
    'PAYROLL': 'Salary',
    'STIPEND': 'Salary',
    'RENT': 'Rent',
    'RENTAL': 'Rent',
    'MEDICAL': 'Medical',
    'HOSPITAL': 'Medical',
    'PHARMACY': 'Medical',
    'APOLLO': 'Medical',
    'MEDPLUS': 'Medical',
    'NETMEDS': 'Medical',
    '1MG': 'Medical',
    'PRACTO': 'Medical',
    'CLINIC': 'Medical',
    'PETROL': 'Fuel',
    'DIESEL': 'Fuel',
    'FUEL': 'Fuel',
    'HPCL': 'Fuel',
    'BPCL': 'Fuel',
    'IOCL': 'Fuel',
    'INDIANOIL': 'Fuel',
    'RELIANCE PETRO': 'Fuel',
    'EMI': 'EMI',
    'LOAN': 'EMI',
    'BAJAJ': 'EMI',
    'MUTUAL': 'Investment',
    'SIP': 'Investment',
    'GROWW': 'Investment',
    'ZERODHA': 'Investment',
    'UPSTOX': 'Investment',
    'INVEST': 'Investment',
    'DIVIDEND': 'Investment',
    'REFUND': 'Refund',
    'CASHBACK': 'Refund',
    'REVERSAL': 'Refund',
    'NEFT': 'Transfer',
    'IMPS': 'Transfer',
    'RTGS': 'Transfer',
    'P2P': 'Transfer',
    'TRANSFER': 'Transfer',
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
  // 👇 fallback
  final others = tags.firstWhere(
    (t) => t.toLowerCase() == 'others',
    orElse: () => 'Others',
  );
  return others;
}

String cleanName(String raw) {
  var s = raw.toUpperCase();

  // 1. Remove transaction prefixes
  s = s.replaceAll(
    RegExp(
      r'^(UPI[-/]|NEFT[-/]?|IMPS[-/]?|RTGS[-/]?|ACH[-/]?|ECS[-/]?|MMT/|P2M/|P2P/|CMS/)',
      caseSensitive: false,
    ),
    '',
  );

  // 2. Handle UPI (smart)
  if (s.contains('@')) {
    final beforeAt = s.split('@').first;
    if (!isKnownBrand(beforeAt)) {
      s = beforeAt;
    }
  }

  // 3. Remove long numbers (txn ids etc)
  s = s.replaceAll(RegExp(r'\b\d{6,}\b'), '');

  // 4. Remove common banking words
  s = s.replaceAll(
    RegExp(
      r'\b(PAYMENT|TRANSFER|TRF|FROM|TO|BY|VIA|REF|BANK|LIMITED|LTD|PVT|PRIVATE|CORP|CO|PURCHASE|ORDER|BOOKING|DEBIT|CREDIT)\b',
      caseSensitive: false,
    ),
    '',
  );

  // 5. Replace separators with space
  s = s.replaceAll(RegExp(r'[_\-/|\\]+'), ' ');

  // 6. Clean multiple spaces
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

  // 7. Smart word selection
  final words = s
      .split(' ')
      .where((w) => w.length > 1 && !RegExp(r'^\d+$').hasMatch(w))
      .take(4)
      .toList();

  s = words.join(' ').trim();

  // 8. Capitalize properly
  return s
      .split(' ')
      .map(
        (w) => w.isEmpty
            ? ''
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

Map<String, dynamic>? exactFind(String name, List<Map<String, dynamic>> accs) {
  final n = norm(name);
  for (final a in accs) {
    if (norm(a['name'] as String) == n) return a;
  }
  return null;
}

Map<String, dynamic>? containsFind(
  String name,
  List<Map<String, dynamic>> accs,
) {
  final n = norm(name);
  for (final a in accs) {
    final an = norm(a['name'] as String);
    if (an.contains(n) || n.contains(an)) return a;
  }
  return null;
}

Map<String, dynamic>? fuzzyFind(String name, List<Map<String, dynamic>> accs) {
  if (name.length < 3) return null;
  final exact = exactFind(name, accs);
  if (exact != null) return exact;
  final contains = containsFind(name, accs);
  if (contains != null) return contains;
  final nWords = name.split(' ').where((w) => w.length > 2).toSet();
  if (nWords.length >= 2) {
    for (final a in accs) {
      final aWords = norm(
        a['name'] as String,
      ).split(' ').where((w) => w.length > 2).toSet();
      if (nWords.intersection(aWords).length >= 2) return a;
    }
  }
  return null;
}

String guessType(String d, bool isDebit) {
  if (d.contains('SALARY') ||
      d.contains('PAYROLL') ||
      d.contains('DIVIDEND') ||
      d.contains('INTEREST CREDIT') ||
      d.contains('CASHBACK')) {
    return 'income';
  }

  if (d.contains('REFUND')) return isDebit ? 'expense' : 'income';

  if (isKnownBrand(d)) return 'vendor';

  if (d.contains('P2P')) return 'person';
  final upiPersonal = RegExp(
    r'@(OKICICI|OKHDFCBANK|OKSBI|OKAXIS|YBL|IBL|AXISB|UCOBANK|BARODAMPAY|KOTAK|PTYES|PAYTM|WAICICI|WAHDFCBANK)',
    caseSensitive: false,
  );
  if (upiPersonal.hasMatch(d)) return 'person';

  if (RegExp(r'\b[6-9]\d{9}\b').hasMatch(d)) return 'person';

  if (d.contains('IMPS') || d.contains('NEFT') || d.contains('RTGS')) {
    return 'person';
  }
  if (d.contains('MMT/')) return 'person';
  final words = d
      .replaceAll(RegExp(r'[^A-Z\s]'), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 2)
      .toList();
  if (words.length >= 2 &&
      words.length <= 4 &&
      words.every((w) => RegExp(r'^[A-Z]+$').hasMatch(w)) &&
      !isKnownBrand(d)) {
    return 'person';
  }

  if (d.contains('RENT') && !isDebit) return 'income';

  return isDebit ? 'expense' : 'income';
}

bool isKnownBrand(String d) {
  const brands = [
    'ZOMATO',
    'SWIGGY',
    'AMAZON',
    'FLIPKART',
    'MYNTRA',
    'MEESHO',
    'BIGBASKET',
    'BLINKIT',
    'DUNZO',
    'ZEPTO',
    'IRCTC',
    'MAKEMYTRIP',
    'GOIBIBO',
    'REDBUS',
    'NETFLIX',
    'HOTSTAR',
    'SPOTIFY',
    'YOUTUBE',
    'AIRTEL',
    'VODAFONE',
    'JIOMART',
    'JIO',
    'BSNL',
    'APOLLO',
    'MEDPLUS',
    'NETMEDS',
    '1MG',
    'UBER',
    'OLA',
    'RAPIDO',
    'ELECTRICITY',
    'BESCOM',
    'MSEB',
    'TATA POWER',
    'LIC',
    'HDFC LIFE',
    'SBI LIFE',
    'ICICI PRU',
    'BAJAJ',
    'GROWW',
    'ZERODHA',
    'UPSTOX',
  ];
  return brands.any((b) => d.contains(b));
}

//  Yeh helper add karo file ke bottom mein
String normalizeDate(String s) {
  s = s.trim();
  // Already yyyy-MM-dd format
  if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) return s.substring(0, 10);
  // dd/MM/yyyy or dd-MM-yyyy
  final m = RegExp(r'^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})').firstMatch(s);
  if (m != null) {
    final d = m.group(1)!.padLeft(2, '0');
    final mo = m.group(2)!.padLeft(2, '0');
    final y = m.group(3)!;
    return '$y-$mo-$d';
  }
  return s.toLowerCase();
}

String generateTxHash(String date, String desc, double amount) {
  final normalized =
      '${normalizeDate(date)}|${desc.toLowerCase().trim()}|${amount.toStringAsFixed(2)}';
  // Simple hash — no external package needed
  final bytes = utf8.encode(normalized);
  int hash = 0;
  for (final b in bytes) {
    hash = (hash * 31 + b) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

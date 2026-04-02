// ignore_for_file: deprecated_member_use

class ParseParams {
  final String csvContent;
  final List<Map<String, dynamic>> accounts;
  final Set<String> existingTxKeys;
  final Map<String, String> vendorMap;
  final Map<String, String> tagMap;
  final List<String> tags;
  const ParseParams({
    required this.csvContent,
    required this.accounts,
    required this.existingTxKeys,
    required this.vendorMap,
    required this.tagMap,
    required this.tags,
  });
}

class ParseResult {
  final List<PRowData> rows;
  final int dupCount, invalidCount;
  final List<String> warnings;
  const ParseResult({
    required this.rows,
    required this.dupCount,
    required this.invalidCount,
    required this.warnings,
  });
}

class PRowData {
  final String date, description, cleanedName;
  final double debit, credit;
  int? accountId;
    final String txHash;
  String? accountName;
  String accountType;
  String? tag;
  bool isNewAccount, isDuplicate, skip;

  PRowData({
    required this.date,
    required this.description,
    required this.cleanedName,
    required this.debit,
    required this.credit,
    required this.txHash,
    this.accountId,
    this.accountName,
    required this.accountType,
    this.tag,
    this.isNewAccount = false,
    this.isDuplicate = false,
    this.skip = false,
  });
}

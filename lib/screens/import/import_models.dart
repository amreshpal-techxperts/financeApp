// ══════════════════════════════════════════════════════════════════════
// import_models.dart — REPLACE existing ParseParams class
// ══════════════════════════════════════════════════════════════════════

// ── ParseParams ────────────────────────────────────────────────────────
class ParseParams {
  final String csvContent;
  final List<Map<String, dynamic>> accounts; // all accounts
  final Set<String> existingTxKeys; // duplicate check
  final Map<String, String> vendorMap; // (keep for compatibility)
  final Map<String, String> tagMap; // (keep for compatibility)
  final List<String> tags; // tag names list

  // ── Keyword maps ──────────────────────────────────────────────────
  /// accountId → keywords list  (from accounts.keywords column)
  /// Includes both account-type AND party-type accounts.
  /// Parser internally splits them by account type.
  final Map<int, List<String>> keywordsMap;

  /// tagId → keywords list  (from global_keywords table)
  final Map<int, List<String>> globalKeywordsMap;

  /// tagId → tag name  (for resolving globalKeywordsMap hits)
  final Map<int, String> tagIdToName;

  const ParseParams({
    required this.csvContent,
    required this.accounts,
    required this.existingTxKeys,
    required this.vendorMap,
    required this.tagMap,
    required this.tags,
    required this.keywordsMap,
    required this.globalKeywordsMap,
    required this.tagIdToName,
  });
}

// ── PRowData ───────────────────────────────────────────────────────────
// (existing class — only note: isNewAccount is always false now)
class PRowData {
  final String date;
  final String txHash;
  final String description;
  final String cleanedName; // matched account name (empty if no match)
  final double debit;
  final double credit;
  int? accountId;
  String? accountName; // null = unassigned (user must pick)
  String accountType;
  String? tag;
  bool isNewAccount; // always false — no auto-creation
  bool isDuplicate;
  bool skip;

  PRowData({
    required this.date,
    required this.txHash,
    required this.description,
    required this.cleanedName,
    required this.debit,
    required this.credit,
    this.accountId,
    this.accountName,
    required this.accountType,
    this.tag,
    this.isNewAccount = false,
    this.isDuplicate = false,
    this.skip = false,
  });
}

// ── ParseResult ────────────────────────────────────────────────────────
class ParseResult {
  final List<PRowData> rows;
  final int dupCount;
  final int invalidCount;
  final List<String> warnings;

  const ParseResult({
    required this.rows,
    required this.dupCount,
    required this.invalidCount,
    required this.warnings,
  });
}

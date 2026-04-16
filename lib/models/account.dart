class Account {
  int? id;
  String name;
  String type; // bank|cash|wallet|expense|income|person|vendor
  double openingBalance;
  String? phone;
  String? accountNumber; // ✅ NEW — sirf bank type ke liye
  DateTime createdAt;
  final int? masterAccountId;
  final List<String> keywords;

  Account({
    this.id,
    required this.name,
    required this.type,
    this.openingBalance = 0.0,
    this.phone,
    this.accountNumber,
    DateTime? createdAt,
    this.masterAccountId,
    List<String>? keywords,
  }) : createdAt = createdAt ?? DateTime.now(),
       keywords = keywords ?? [];

  bool get isAsset => type == 'bank' || type == 'cash' || type == 'wallet';
  bool get isPerson => type == 'person' || type == 'vendor';
  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  /// Last 4 digits of account number (display ke liye)
  String? get maskedAccountNumber {
    if (accountNumber == null || accountNumber!.length < 4)
      return accountNumber;
    return '••••${accountNumber!.substring(accountNumber!.length - 4)}';
  }

  bool matchesDescription(String description) {
    if (keywords.isEmpty) return false;
    final d = description.toLowerCase();
    return keywords.any((kw) => kw.isNotEmpty && d.contains(kw.toLowerCase()));
  }

  /// Check karo ki given account number is account se match karta hai
  bool matchesAccountNumber(String? detected) {
    if (accountNumber == null || detected == null) return false;
    final a = accountNumber!.replaceAll(RegExp(r'\D'), '');
    final b = detected.replaceAll(RegExp(r'\D'), '');
    if (a.isEmpty || b.isEmpty) return false;
    // Last 6 digits match karo (partial match ke liye)
    final aLast = a.length >= 6 ? a.substring(a.length - 6) : a;
    final bLast = b.length >= 6 ? b.substring(b.length - 6) : b;
    return aLast == bLast || a == b;
  }

  Account withKeyword(String newKeyword) {
    final kw = newKeyword.toLowerCase().trim();
    if (kw.length < 3) return this;
    if (keywords.any((k) => k.toLowerCase() == kw)) return this;
    final updated = [...keywords, kw];
    if (updated.length > 30) updated.removeAt(0);
    return copyWith(keywords: updated);
  }

  Account copyWith({
    int? id,
    String? name,
    String? type,
    double? openingBalance,
    int? masterAccountId,
    String? phone,
    String? accountNumber,
    List<String>? keywords,
  }) => Account(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    openingBalance: openingBalance ?? this.openingBalance,
    masterAccountId: masterAccountId ?? this.masterAccountId,
    phone: phone ?? this.phone,
    accountNumber: accountNumber ?? this.accountNumber,
    createdAt: createdAt,
    keywords: keywords ?? List.from(this.keywords),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'openingBalance': openingBalance,
    'masterAccountId': masterAccountId,
    'phone': phone,
    'accountNumber': accountNumber,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Account.fromMap(Map<String, dynamic> m) => Account(
    id: m['id'],
    name: m['name'],
    type: m['type'],
    openingBalance: (m['openingBalance'] ?? 0.0).toDouble(),
    phone: m['phone'],
    accountNumber: m['accountNumber'],
    masterAccountId: m['masterAccountId'],
    createdAt: DateTime.parse(m['createdAt']),
    keywords: [],
  );
}

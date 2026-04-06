class Account {
  int? id;
  String name;
  String type; // bank|cash|wallet|expense|income|person|vendor
  double openingBalance;
  String? phone;
  DateTime createdAt;
  final int? masterAccountId;
  final List<String> keywords;

  Account({
    this.id,
    required this.name,
    required this.type,
    this.openingBalance = 0.0,
    this.phone,
    DateTime? createdAt,
    this.masterAccountId,
    List<String>? keywords,
  }) : createdAt = createdAt ?? DateTime.now(),
       keywords = keywords ?? [];

  bool get isAsset => type == 'bank' || type == 'cash' || type == 'wallet';
  bool get isPerson => type == 'person' || type == 'vendor';
  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  bool matchesDescription(String description) {
    if (keywords.isEmpty) return false;
    final d = description.toLowerCase();
    return keywords.any((kw) => kw.isNotEmpty && d.contains(kw.toLowerCase()));
  }

  Account withKeyword(String newKeyword) {
    final kw = newKeyword.toLowerCase().trim();
    if (kw.length < 3) return this;
    if (keywords.any((k) => k.toLowerCase() == kw)) {
      return this; // already exists
    }
    final updated = [...keywords, kw];
    if (updated.length > 30) updated.removeAt(0); // rolling window
    return copyWith(keywords: updated);
  }

  Account copyWith({
    int? id,
    String? name,
    String? type,
    double? openingBalance,
    int? masterAccountId,
    String? phone,
    List<String>? keywords,
  }) => Account(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    openingBalance: openingBalance ?? this.openingBalance,
    masterAccountId: masterAccountId ?? this.masterAccountId,
    phone: phone ?? this.phone,
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
    'createdAt': createdAt.toIso8601String(),
    'keywords': keywords.join(','),
  };

  factory Account.fromMap(Map<String, dynamic> m) => Account(
    id: m['id'],
    name: m['name'],
    type: m['type'],
    openingBalance: (m['openingBalance'] ?? 0.0).toDouble(),
    phone: m['phone'],
    masterAccountId: m['masterAccountId'],
    createdAt: DateTime.parse(m['createdAt']),
    keywords: _parseKeywords(m['keywords']),
  );

  static List<String> _parseKeywords(dynamic raw) {
    if (raw == null || raw.toString().isEmpty) return [];
    return raw
        .toString()
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();
  }
}

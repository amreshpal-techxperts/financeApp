class Account {
  int? id;
  String name;
  String type; // bank|cash|wallet|expense|income|person|vendor
  double openingBalance;
  String? phone;
  DateTime createdAt;
  final int? masterAccountId;

  Account({
    this.id,
    required this.name,
    required this.type,
    this.openingBalance = 0.0,
    this.phone,
    DateTime? createdAt,
    this.masterAccountId,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isAsset => type == 'bank' || type == 'cash' || type == 'wallet';
  bool get isPerson => type == 'person' || type == 'vendor';
  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'openingBalance': openingBalance,
    'masterAccountId': masterAccountId,
    'phone': phone,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Account.fromMap(Map<String, dynamic> m) => Account(
    id: m['id'],
    name: m['name'],
    type: m['type'],
    openingBalance: (m['openingBalance'] ?? 0.0).toDouble(),
    phone: m['phone'],
    masterAccountId: m['masterAccountId'],
    createdAt: DateTime.parse(m['createdAt']),
  );
}

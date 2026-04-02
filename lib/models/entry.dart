class Entry {
  int? id;
  int transactionId;
  int accountId;
  String type; // debit|credit
  double amount;

  String? description;
  DateTime createdAt;

  Entry({
    this.id,
    required this.transactionId,
    required this.accountId,
    required this.type,
    required this.amount,

    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isDebit => type == 'debit';
  bool get isCredit => type == 'credit';

  Map<String, dynamic> toMap() => {
    'id': id,
    'transactionId': transactionId,
    'accountId': accountId,
    'type': type,
    'amount': amount,

    'description': description,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Entry.fromMap(Map<String, dynamic> m) => Entry(
    id: m['id'],
    transactionId: m['transactionId'],
    accountId: m['accountId'],
    type: m['type'],
    amount: (m['amount'] ?? 0.0).toDouble(),

    description: m['description'],
    createdAt: DateTime.parse(m['createdAt']),
  );
}

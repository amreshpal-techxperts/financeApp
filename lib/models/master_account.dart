class MasterAccount {
  int? id;
  String name;
  String? accountNumber;
  String? bankName;
  bool isDefault;
  DateTime createdAt;

  MasterAccount({
    this.id,
    required this.name,
    this.accountNumber,
    this.bankName,
    this.isDefault = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'accountNumber': accountNumber,
    'bankName': bankName,
    'isDefault': isDefault ? 1 : 0,
    'createdAt': createdAt.toIso8601String(),
  };

  factory MasterAccount.fromMap(Map<String, dynamic> m) => MasterAccount(
    id: m['id'],
    name: m['name'],
    accountNumber: m['accountNumber'],
    bankName: m['bankName'],
    isDefault: (m['isDefault'] ?? 0) == 1,
    createdAt: DateTime.parse(m['createdAt']),
  );
}

class MasterAccount {
  int? id;
  String name;
  String? accountNumber;
  String? bankName;
 
  DateTime createdAt;

  MasterAccount({
    this.id,
    required this.name,
    this.accountNumber,
    this.bankName,
   
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'accountNumber': accountNumber,
    'bankName': bankName,
   
    'createdAt': createdAt.toIso8601String(),
  };

  factory MasterAccount.fromMap(Map<String, dynamic> m) => MasterAccount(
    id: m['id'],
    name: m['name'],
    accountNumber: m['accountNumber'],
    bankName: m['bankName'],
  
    createdAt: DateTime.parse(m['createdAt']),
  );
}

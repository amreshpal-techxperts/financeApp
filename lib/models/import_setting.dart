class ImportSetting {
  int? id;
  String accountNumber;
  String detectedName;
  String setupType; // master_account|party
  int? masterAccountId;
  String customName;
  DateTime createdAt;

  ImportSetting({
    this.id,
    required this.accountNumber,
    required this.detectedName,
    required this.setupType,
    this.masterAccountId,
    required this.customName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'accountNumber': accountNumber,
    'detectedName': detectedName,
    'setupType': setupType,
    'masterAccountId': masterAccountId,
    'customName': customName,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ImportSetting.fromMap(Map<String, dynamic> m) => ImportSetting(
    id: m['id'],
    accountNumber: m['accountNumber'],
    detectedName: m['detectedName'],
    setupType: m['setupType'],
    masterAccountId: m['masterAccountId'],
    customName: m['customName'],
    createdAt: DateTime.parse(m['createdAt']),
  );
}

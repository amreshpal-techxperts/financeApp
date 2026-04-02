class TxVoucher {
  int? id;
  DateTime date;
  String note;
  String source;
  int? masterAccountId;
  int? tagId;
  DateTime createdAt;
  final String? importHash;

  TxVoucher({
    this.id,
    required this.date,
    this.note = '',
    this.source = 'manual',
    this.masterAccountId,
    this.tagId, // ← add
    DateTime? createdAt,
    this.importHash,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'note': note,
    'source': source,
    'masterAccountId': masterAccountId,
    'tagId': tagId,
    'createdAt': createdAt.toIso8601String(),
    'importHash': importHash,
  };

  factory TxVoucher.fromMap(Map<String, dynamic> m) => TxVoucher(
    id: m['id'],
    date: DateTime.parse(m['date']),
    note: m['note'] ?? '',
    source: m['source'] ?? 'manual',
    masterAccountId: m['masterAccountId'],
    tagId: m['tagId'],
    createdAt: DateTime.parse(m['createdAt']),
    importHash: m['importHash'],
  );
}

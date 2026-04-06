class GlobalKeyword {
  final int? id;
  final String keyword; // e.g. "upi", "atm", "neft"
  final int tagId; // → Tag
  final String createdAt;

  const GlobalKeyword({
    this.id,
    required this.keyword,
    required this.tagId,
    required this.createdAt,
  });

  factory GlobalKeyword.fromMap(Map<String, dynamic> m) => GlobalKeyword(
        id: m['id'] as int?,
        keyword: m['keyword'] as String,
        tagId: m['tagId'] as int,
        createdAt: m['createdAt'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'keyword': keyword,
        'tagId': tagId,
        'createdAt': createdAt,
      };
}
class Tag {
  int? id;
  String name;
  String color;
  DateTime createdAt;

  Tag({this.id, required this.name, required this.color, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'color': color,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Tag.fromMap(Map<String, dynamic> m) => Tag(
    id: m['id'],
    name: m['name'],
    color: m['color'],
    createdAt: DateTime.parse(m['createdAt']),
  );
}

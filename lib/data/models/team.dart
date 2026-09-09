class Team {
  final String id;
  final String name;
  final String shortName;
  final int colorValue;
  final String? captainId;
  final String? keeperId;
  final int createdAt;

  const Team({
    required this.id,
    required this.name,
    required this.shortName,
    this.colorValue = 0xFF0F9D58,
    this.captainId,
    this.keeperId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'shortName': shortName,
      'colorValue': colorValue,
      'captainId': captainId,
      'keeperId': keeperId,
      'createdAt': createdAt,
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] as String,
      name: map['name'] as String,
      shortName: map['shortName'] as String,
      colorValue: map['colorValue'] != null ? (map['colorValue'] as int) : 0xFF0F9D58,
      captainId: map['captainId'] as String?,
      keeperId: map['keeperId'] as String?,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as int) : 0,
    );
  }

  Team copyWith({
    String? id,
    String? name,
    String? shortName,
    int? colorValue,
    String? captainId,
    String? keeperId,
    int? createdAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      colorValue: colorValue ?? this.colorValue,
      captainId: captainId ?? this.captainId,
      keeperId: keeperId ?? this.keeperId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Player {
  final String id;
  final String teamId;
  final String name;
  final int jerseyNumber;
  final String role; // 'Batter', 'Bowler', 'All Rounder', 'Wicketkeeper'
  final String battingStyle; // 'Right-hand bat', 'Left-hand bat'
  final String bowlingStyle; // 'Right-arm fast', 'Right-arm medium', 'Right-arm spin', 'Left-arm fast', 'Left-arm spin', 'None'
  final bool isCaptain;
  final bool isWicketKeeper;
  final int createdAt;

  const Player({
    required this.id,
    required this.teamId,
    required this.name,
    this.jerseyNumber = 0,
    required this.role,
    this.battingStyle = 'Right-hand bat',
    this.bowlingStyle = 'None',
    this.isCaptain = false,
    this.isWicketKeeper = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamId': teamId,
      'name': name,
      'jerseyNumber': jerseyNumber,
      'role': role,
      'battingStyle': battingStyle,
      'bowlingStyle': bowlingStyle,
      'isCaptain': isCaptain ? 1 : 0,
      'isWicketKeeper': isWicketKeeper ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as String,
      teamId: map['teamId'] as String,
      name: map['name'] as String,
      jerseyNumber: map['jerseyNumber'] != null ? (map['jerseyNumber'] as int) : 0,
      role: map['role'] as String? ?? 'Batter',
      battingStyle: map['battingStyle'] as String? ?? 'Right-hand bat',
      bowlingStyle: map['bowlingStyle'] as String? ?? 'None',
      isCaptain: map['isCaptain'] == 1 || map['isCaptain'] == true,
      isWicketKeeper: map['isWicketKeeper'] == 1 || map['isWicketKeeper'] == true,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as int) : 0,
    );
  }

  Player copyWith({
    String? id,
    String? teamId,
    String? name,
    int? jerseyNumber,
    String? role,
    String? battingStyle,
    String? bowlingStyle,
    bool? isCaptain,
    bool? isWicketKeeper,
    int? createdAt,
  }) {
    return Player(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      role: role ?? this.role,
      battingStyle: battingStyle ?? this.battingStyle,
      bowlingStyle: bowlingStyle ?? this.bowlingStyle,
      isCaptain: isCaptain ?? this.isCaptain,
      isWicketKeeper: isWicketKeeper ?? this.isWicketKeeper,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum AuthProvider { guest, email, google, apple }

class Player {
  const Player({
    required this.id,
    required this.name,
    required this.tag,
    required this.provider,
    this.email,
    required this.joinedIso,
  });

  final String id;
  final String name;

  /// Short arena tag shown next to the name, e.g. "#4821".
  final String tag;
  final AuthProvider provider;
  final String? email;
  final String joinedIso;

  String get initial =>
      name.trim().isEmpty ? 'P' : name.trim()[0].toUpperCase();

  /// Local demo accounts get ids like `p1720000000000123` from the offline
  /// sign-in path; real Firebase accounts have opaque UIDs that never match.
  bool get isDemo => RegExp(r'^p\d+$').hasMatch(id);

  Player copyWith({String? name}) => Player(
        id: id,
        name: name ?? this.name,
        tag: tag,
        provider: provider,
        email: email,
        joinedIso: joinedIso,
      );

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        name: json['name'] as String,
        tag: json['tag'] as String? ?? '',
        provider: AuthProvider.values.firstWhere(
          (p) => p.name == (json['provider'] as String? ?? 'guest'),
          orElse: () => AuthProvider.guest,
        ),
        email: json['email'] as String?,
        joinedIso: json['joinedIso'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tag': tag,
        'provider': provider.name,
        'email': email,
        'joinedIso': joinedIso,
      };
}

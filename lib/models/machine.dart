class Machine {
  final String id;
  String name;
  List<String> ipAddresses;
  String? group;

  Machine({
    required this.id,
    required this.name,
    required this.ipAddresses,
    this.group,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ipAddresses': ipAddresses,
      'group': group,
    };
  }

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: json['id'] as String,
      name: json['name'] as String,
      ipAddresses: List<String>.from(json['ipAddresses'] as List),
      group: json['group'] as String?,
    );
  }

  Machine copyWith({
    String? id,
    String? name,
    List<String>? ipAddresses,
    String? group,
  }) {
    return Machine(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddresses: ipAddresses ?? this.ipAddresses,
      group: group ?? this.group,
    );
  }

  String get displayGroup => group ?? 'UNGROUPED';
}

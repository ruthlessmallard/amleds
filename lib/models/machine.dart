class Machine {
  final String id;
  String name;
  List<String> ipAddresses;

  Machine({
    required this.id,
    required this.name,
    required this.ipAddresses,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ipAddresses': ipAddresses,
    };
  }

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: json['id'] as String,
      name: json['name'] as String,
      ipAddresses: List<String>.from(json['ipAddresses'] as List),
    );
  }

  Machine copyWith({
    String? id,
    String? name,
    List<String>? ipAddresses,
  }) {
    return Machine(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddresses: ipAddresses ?? this.ipAddresses,
    );
  }
}

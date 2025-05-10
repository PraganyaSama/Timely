class MasterSubject {
  int? id;
  String name;
  String code;
  String description;

  MasterSubject({
    this.id,
    required this.name,
    required this.code,
    required this.description,
  });

  // Convert a MasterSubject into a Map. The keys must correspond to the column names in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
    };
  }

  // Convert a Map into a MasterSubject object
  factory MasterSubject.fromMap(Map<String, dynamic> map) {
    return MasterSubject(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      description: map['description'],
    );
  }
}

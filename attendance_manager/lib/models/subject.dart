class Subject {
  int? id;
  String name;
  String day;
  String time;
  String status;
  String date;
  
  Subject({
    this.id,
    required this.name,
    required this.day,
    required this.time,
    required this.status,
    required this.date,
  });

  // Convert a Subject into a Map. The keys must correspond to the column names in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'day': day,
      'time': time,
      'status': status,
      'date': date,
    };
  }

  // Convert a Map into a Subject object
  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'],
      name: map['name'],
      day: map['day'],
      time: map['time'],
      status: map['status'],
      date: map['date'],
    );
  }
}

class HolidayModel {
  final String id;
  final String name;
  final DateTime date;
  final String type;
  final bool isHalfDay;
  final String description;

  HolidayModel({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
    required this.isHalfDay,
    required this.description,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      id: json['id'],
      name: json['name'],
      date: DateTime.parse(json['date']),
      type: json['type'],
      isHalfDay: json['isHalfDay'],
      description: json['description'],
    );
  }
}

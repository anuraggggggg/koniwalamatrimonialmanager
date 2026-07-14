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
    final dateText = json['date']?.toString();
    return HolidayModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Holiday',
      date: DateTime.tryParse(dateText ?? '') ?? DateTime.now(),
      type: json['type']?.toString() ?? 'HOLIDAY',
      isHalfDay: json['isHalfDay'] == true,
      description: json['description']?.toString() ?? '',
    );
  }
}

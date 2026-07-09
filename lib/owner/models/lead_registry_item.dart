class LeadRegistryItem {
  const LeadRegistryItem({
    required this.id,
    required this.shortlistCandidateId,
    required this.name,
    required this.phone,
    required this.email,
    required this.stage,
    required this.city,
    required this.assignedToId,
    required this.assignedTo,
    required this.source,
    required this.leadFor,
    required this.createdOn,
    this.image = '',
  });

  final String id;
  final String shortlistCandidateId;
  final String name;
  final String phone;
  final String email;
  final String stage;
  final String city;
  final String assignedToId;
  final String assignedTo;
  final String source;
  final String leadFor;
  final String createdOn;
  final String image;

  factory LeadRegistryItem.fromJson(Map<String, dynamic> json) {
    final assignedTo = json['assignedTo'];
    final isShortlistCandidate = _looksLikeShortlistCandidate(json);

    return LeadRegistryItem(
      id: _readText(json['id']),
      shortlistCandidateId: _firstText([
        json['shortlistCandidateId'],
        json['candidateId'],
        if (isShortlistCandidate) json['id'],
      ]),
      name: _readText(json['name'], fallback: 'Unnamed Lead'),
      phone: _readText(json['phone'], fallback: '-'),
      email: _readText(json['email'], fallback: '-'),
      stage: _formatEnumLabel(_readText(json['stage'], fallback: 'New')),
      city: _readText(json['city'], fallback: '-'),
      assignedToId: assignedTo is Map<String, dynamic>
          ? _readText(assignedTo['id'])
          : _readText(json['assignedToId']),
      assignedTo: assignedTo is Map<String, dynamic>
          ? _readText(assignedTo['name'], fallback: '-')
          : '-',
      source: _formatEnumLabel(_readText(json['source'], fallback: '-')),
      leadFor: _formatEnumLabel(_readText(json['leadFor'], fallback: '-')),
      createdOn: _formatCreatedOn(_readText(json['createdAt'])),
      image: _readText(json['image']),
    );
  }

  bool get canDeleteShortlistCandidate => shortlistCandidateId.isNotEmpty;

  LeadRegistryItem copyWith({
    String? name,
    String? phone,
    String? email,
    String? stage,
    String? city,
    String? assignedToId,
    String? assignedTo,
    String? source,
    String? leadFor,
    String? image,
  }) {
    return LeadRegistryItem(
      id: id,
      shortlistCandidateId: shortlistCandidateId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      stage: stage ?? this.stage,
      city: city ?? this.city,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedTo: assignedTo ?? this.assignedTo,
      source: source ?? this.source,
      leadFor: leadFor ?? this.leadFor,
      createdOn: createdOn,
      image: image ?? this.image,
    );
  }

  String get initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  static bool _looksLikeShortlistCandidate(Map<String, dynamic> json) {
    return json.containsKey('shortlistedProfileId') ||
        json.containsKey('ownerProfileId') ||
        json.containsKey('clientJourneyId') ||
        json.containsKey('shortlistCandidateId');
  }

  static String _firstText(List<dynamic> values, {String fallback = ''}) {
    for (final value in values) {
      final text = _readText(value);
      if (text.isNotEmpty) {
        return text;
      }
    }

    return fallback;
  }

  static String _readText(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String _formatEnumLabel(String value) {
    if (value == '-') {
      return value;
    }

    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) {
          final lower = part.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  static String _formatCreatedOn(String value) {
    if (value.isEmpty) {
      return '-';
    }

    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) {
      return value;
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

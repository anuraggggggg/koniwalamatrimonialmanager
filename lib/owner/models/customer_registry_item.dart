class CustomerRegistryItem {
  const CustomerRegistryItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.packageType,
    required this.createdOn,
    required this.createdAt,
    required this.assignedRmName,
    required this.profiles,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String packageType;
  final String createdOn;
  final DateTime? createdAt;
  final String assignedRmName;
  final List<CustomerProfileSummary> profiles;

  factory CustomerRegistryItem.fromJson(Map<String, dynamic> json) {
    final assignedExecutives = json['assignedExecutives'];
    final profiles = json['profiles'];
    final createdAtText = _readText(json['createdAt']);
    final createdDate = DateTime.tryParse(createdAtText)?.toLocal();

    return CustomerRegistryItem(
      id: _readText(json['id']),
      name: _readText(json['name'], fallback: 'Unnamed Client'),
      phone: _readText(json['phone'], fallback: '-'),
      email: _readText(json['email'], fallback: '-'),
      packageType: _readText(json['packageType'], fallback: 'STANDARD'),
      createdOn: _formatCreatedOn(createdDate),
      createdAt: createdDate,
      assignedRmName: _readAssignedRmName(assignedExecutives),
      profiles: profiles is List
          ? profiles
                .whereType<Map<String, dynamic>>()
                .map(CustomerProfileSummary.fromJson)
                .toList()
          : const [],
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

  String get packageLabel {
    return '${_formatEnumLabel(packageType)} Registry';
  }

  bool get isPremium {
    return packageType.toUpperCase() == 'PREMIUM';
  }

  int get activeProfilesCount {
    return profiles.where((profile) => profile.status == 'ACTIVE').length;
  }

  int get profilesCount {
    return profiles.length;
  }

  static String _readAssignedRmName(dynamic assignedExecutives) {
    if (assignedExecutives is! List || assignedExecutives.isEmpty) {
      return '-';
    }

    final firstAssignment = assignedExecutives.first;
    if (firstAssignment is! Map<String, dynamic>) {
      return '-';
    }

    final user = firstAssignment['user'];
    if (user is Map<String, dynamic>) {
      return _readText(user['name'], fallback: '-');
    }

    return '-';
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

  static String _formatCreatedOn(DateTime? value) {
    if (value == null) {
      return '-';
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

    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }
}

class CustomerProfileSummary {
  const CustomerProfileSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.category,
  });

  final String id;
  final String name;
  final String status;
  final String category;

  factory CustomerProfileSummary.fromJson(Map<String, dynamic> json) {
    return CustomerProfileSummary(
      id: CustomerRegistryItem._readText(json['id']),
      name: CustomerRegistryItem._readText(json['name']),
      status: CustomerRegistryItem._readText(json['status']).toUpperCase(),
      category: CustomerRegistryItem._readText(json['category']).toUpperCase(),
    );
  }
}

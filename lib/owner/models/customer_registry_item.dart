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
    final customer = _readMap(json['customer']);
    final lead = _readMap(json['lead']) ?? _readMap(customer?['lead']);
    final profiles = json['profiles'];
    final createdAtText = _firstText([
      customer?['createdAt'],
      json['createdAt'],
    ], fallback: '');
    final createdDate = DateTime.tryParse(createdAtText)?.toLocal();
    final profileSummaries = profiles is List
        ? profiles
              .whereType<Map<String, dynamic>>()
              .map(CustomerProfileSummary.fromJson)
              .toList()
        : customer == null
        ? const <CustomerProfileSummary>[]
        : [CustomerProfileSummary.fromJson(json)];

    return CustomerRegistryItem(
      id: _firstText([customer?['id'], json['customerId'], json['id']]),
      name: _firstText([
        customer?['name'],
        json['customerName'],
        json['name'],
      ], fallback: 'Unnamed Client'),
      phone: _firstText([
        customer?['phone'],
        json['phone'],
        json['mobile'],
        json['contactNumber'],
      ], fallback: '-'),
      email: _firstText([customer?['email'], json['email']], fallback: '-'),
      packageType: _firstText([
        customer?['packageType'],
        json['packageType'],
      ], fallback: 'STANDARD'),
      createdOn: _formatCreatedOn(createdDate),
      createdAt: createdDate,
      assignedRmName: _readAssignedRmName(json, customer: customer, lead: lead),
      profiles: profileSummaries,
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

  static String _readAssignedRmName(
    Map<String, dynamic> json, {
    Map<String, dynamic>? customer,
    Map<String, dynamic>? lead,
  }) {
    final assignedTo = _firstMap([
      json['assignedRm'],
      json['assignedRM'],
      json['relationshipManager'],
      json['assignedTo'],
      customer?['assignedRm'],
      customer?['assignedRM'],
      customer?['relationshipManager'],
      customer?['assignedTo'],
      lead?['assignedTo'],
      _firstAssignedExecutiveUser(json['assignedExecutives']),
      _firstAssignedExecutiveUser(json['assigned_executives']),
      customer == null
          ? null
          : _firstAssignedExecutiveUser(customer['assignedExecutives']),
      customer == null
          ? null
          : _firstAssignedExecutiveUser(customer['assigned_executives']),
    ]);

    return _firstText([
      json['assignedRmName'],
      json['assignedRMName'],
      json['relationshipManagerName'],
      json['rmName'],
      customer?['assignedRmName'],
      customer?['assignedRMName'],
      customer?['relationshipManagerName'],
      customer?['rmName'],
      customer?['assignedToName'],
      lead?['assignedToName'],
      assignedTo?['name'],
      assignedTo?['fullName'],
      assignedTo?['email'],
    ], fallback: '-');
  }

  static Map<String, dynamic>? _firstMap(List<dynamic> values) {
    for (final value in values) {
      final map = _readMap(value);
      if (map != null) {
        return map;
      }
    }

    return null;
  }

  static Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  static Map<String, dynamic>? _firstAssignedExecutiveUser(
    dynamic assignedExecutives,
  ) {
    if (assignedExecutives is! List || assignedExecutives.isEmpty) {
      return null;
    }

    final firstAssignment = assignedExecutives.first;
    if (firstAssignment is! Map) {
      return null;
    }

    final assignment = Map<String, dynamic>.from(firstAssignment);
    final user = firstAssignment['user'];
    if (user is Map) {
      return Map<String, dynamic>.from(user);
    }

    return assignment;
  }

  static String _firstText(List<dynamic> values, {String fallback = '-'}) {
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

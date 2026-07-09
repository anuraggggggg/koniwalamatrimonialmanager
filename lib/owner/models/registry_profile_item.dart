class RegistryProfileItem {
  const RegistryProfileItem({
    required this.id,
    required this.originalId,
    required this.name,
    required this.age,
    required this.height,
    required this.city,
    required this.work,
    required this.profession,
    required this.community,
    required this.type,
    required this.isPremium,
    required this.image,
    required this.photoUrls,
    required this.dateOfBirth,
    required this.birthTime,
    required this.birthPlace,
    required this.gotra,
    required this.residential,
    required this.aboutMe,
    required this.religion,
    required this.diet,
    required this.manglikLabel,
    required this.country,
    required this.fatherName,
    required this.motherName,
    required this.paternalDetails,
    required this.maternalDetails,
  });

  final String id;
  final String originalId;
  final String name;
  final String age;
  final String height;
  final String city;
  final String work;
  final String profession;
  final String community;
  final String type;
  final bool isPremium;
  final String image;
  final List<String> photoUrls;
  final String dateOfBirth;
  final String birthTime;
  final String birthPlace;
  final String gotra;
  final String residential;
  final String aboutMe;
  final String religion;
  final String diet;
  final String manglikLabel;
  final String country;
  final String fatherName;
  final String motherName;
  final String paternalDetails;
  final String maternalDetails;

  factory RegistryProfileItem.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    final photoUrls = json['photoUrls'];
    final dateOfBirth = DateTime.tryParse(_readText(json['dateOfBirth']));
    final heightCm = json['height'];
    final allPhotoUrls = _readPhotoUrls(json['image'], photoUrls);
    final rawId = _readText(json['id']);

    return RegistryProfileItem(
      id: _shortId(rawId),
      originalId: rawId,
      name: _readText(json['name'], fallback: 'Unnamed Profile'),
      age: _ageFromDate(dateOfBirth),
      height: heightCm is num ? _formatHeight(heightCm.toInt()) : '-',
      city: _firstText([
        json['currentResidential'],
        json['nativePlace'],
        json['state'],
        json['country'],
      ]),
      work: _readText(json['occupation'], fallback: '-'),
      profession: _readText(json['education'], fallback: '-'),
      community: _readText(json['community'], fallback: '-'),
      type: _typeFromGender(json['gender']),
      isPremium:
          customer is Map<String, dynamic> &&
          _readText(customer['packageType']).toUpperCase() == 'PREMIUM',
      image: allPhotoUrls.first,
      photoUrls: allPhotoUrls,
      dateOfBirth: _formatDate(dateOfBirth),
      birthTime: _readText(json['birthTime'], fallback: '-'),
      birthPlace: _firstText([
        json['birthPlace'],
        json['nativePlace'],
        json['currentResidential'],
      ]),
      gotra: _readText(json['gotra'], fallback: '-'),
      residential: _readText(
        json['currentResidential'],
        fallback: _readText(json['nativePlace'], fallback: '-'),
      ),
      aboutMe: _readText(json['aboutMe'], fallback: '-'),
      religion: _readText(json['religion'], fallback: '-'),
      diet: _readText(json['diet'], fallback: '-'),
      manglikLabel: _manglikLabel(json['manglik']),
      country: _readText(json['country'], fallback: '-'),
      fatherName: _readText(json['fatherName'], fallback: '-'),
      motherName: _readText(json['motherName'], fallback: '-'),
      paternalDetails: _readText(json['paternalDetails'], fallback: '-'),
      maternalDetails: _readText(json['maternalDetails'], fallback: '-'),
    );
  }

  static String _readText(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String _firstText(List<dynamic> values) {
    for (final value in values) {
      final text = _readText(value);
      if (text.isNotEmpty) {
        return text;
      }
    }

    return '-';
  }

  static List<String> _readPhotoUrls(dynamic image, dynamic photoUrls) {
    final urls = <String>[];
    final imageText = _readText(image);
    if (imageText.isNotEmpty) {
      urls.add(imageText);
    }

    if (photoUrls is List) {
      for (final photoUrl in photoUrls) {
        final text = _readText(photoUrl);
        if (text.isNotEmpty && !urls.contains(text)) {
          urls.add(text);
        }
      }
    }

    if (urls.isEmpty) {
      urls.add('assets/wedding_hero 1.png');
    }

    return urls;
  }

  static String _manglikLabel(dynamic value) {
    if (value is bool) {
      return value ? 'Manglik' : 'Non-Manglik';
    }

    final text = _readText(value);
    if (text.isEmpty) {
      return '-';
    }

    return text.toUpperCase() == 'TRUE' ? 'Manglik' : 'Non-Manglik';
  }

  static String _shortId(String id) {
    if (id.isEmpty) {
      return '-';
    }

    return id.length <= 8 ? id.toUpperCase() : id.substring(0, 8).toUpperCase();
  }

  static String _ageFromDate(DateTime? dateOfBirth) {
    if (dateOfBirth == null) {
      return '-';
    }

    final today = DateTime.now();
    var age = today.year - dateOfBirth.year;

    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      age--;
    }

    return '$age';
  }

  static String _formatDate(DateTime? value) {
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

    return '${value.day.toString().padLeft(2, '0')} '
        '${months[value.month - 1]} ${value.year}';
  }

  static String _formatHeight(int centimeters) {
    final totalInches = (centimeters / 2.54).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return '$feet\'$inches"';
  }

  static String _typeFromGender(dynamic gender) {
    switch (_readText(gender).toUpperCase()) {
      case 'FEMALE':
        return 'Bride';
      case 'MALE':
        return 'Groom';
      default:
        return 'Profile';
    }
  }
}

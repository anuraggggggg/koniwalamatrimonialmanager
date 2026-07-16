class DataEntryStats {
  final int digitizedToday;
  final int totalContribution;
  final int activeDrafts;
  final int totalPhotos;
  final List<RecentProfile> recentProfiles;
  final List<CommunityStat> communityStats;

  DataEntryStats({
    required this.digitizedToday,
    required this.totalContribution,
    required this.activeDrafts,
    required this.totalPhotos,
    required this.recentProfiles,
    required this.communityStats,
  });

  factory DataEntryStats.fromJson(Map<String, dynamic> json) {
    return DataEntryStats(
      digitizedToday: _readInt(json['digitizedToday']),
      totalContribution: _readInt(
        json['totalContribution'] ?? json['totalProfiles'],
      ),
      activeDrafts: _readInt(json['activeDrafts'] ?? json['drafts']),
      totalPhotos: _readInt(json['totalPhotos'] ?? json['photosDigitized']),
      recentProfiles:
          ((json['recentProfiles'] ?? json['recentlyDigitizedProfiles'])
                  as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(RecentProfile.fromJson)
              .toList() ??
          [],
      communityStats:
          (json['communityStats'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(CommunityStat.fromJson)
              .toList() ??
          [],
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class RecentProfile {
  final String id;
  final String name;
  final String community;
  final String gotra;
  final String gender;
  final String createdAt;

  RecentProfile({
    required this.id,
    required this.name,
    required this.community,
    required this.gotra,
    required this.gender,
    required this.createdAt,
  });

  factory RecentProfile.fromJson(Map<String, dynamic> json) {
    return RecentProfile(
      id: _readText(json['id']),
      name: _readText(json['name'], fallback: 'Unnamed Profile'),
      community: _readText(json['community'], fallback: '-'),
      gotra: _readText(json['gotra'], fallback: '-'),
      gender: _readText(json['gender'], fallback: '-'),
      createdAt: _readText(json['createdAt']),
    );
  }

  static String _readText(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}

class CommunityStat {
  final String community;
  final int count;

  CommunityStat({required this.community, required this.count});

  factory CommunityStat.fromJson(Map<String, dynamic> json) {
    return CommunityStat(
      community: RecentProfile._readText(json['community'], fallback: '-'),
      count: DataEntryStats._readInt(json['count']),
    );
  }
}

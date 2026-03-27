class StatsModel {
  final int totalDonors;
  final int availableDonors;
  final List<BloodTypeCount> byBloodType;
  final int peopleHelped;
  final int fulfilledRequirements;
  final int unitsDelivered;

  StatsModel({
    required this.totalDonors,
    required this.availableDonors,
    required this.byBloodType,
    required this.peopleHelped,
    required this.fulfilledRequirements,
    required this.unitsDelivered,
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) {
    final byBloodTypeList = (json['byBloodType'] as List<dynamic>?)
        ?.map((e) => BloodTypeCount.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];

    return StatsModel(
      totalDonors: (json['totalDonors'] as num?)?.toInt() ?? 0,
      availableDonors: (json['availableDonors'] as num?)?.toInt() ?? 0,
      byBloodType: byBloodTypeList,
      peopleHelped: (json['peopleHelped'] as num?)?.toInt() ?? 0,
      fulfilledRequirements: (json['fulfilledRequirements'] as num?)?.toInt() ?? 0,
      unitsDelivered: (json['unitsDelivered'] as num?)?.toInt() ?? 0,
    );
  }
}

class BloodTypeCount {
  final String type;
  final int count;

  BloodTypeCount({required this.type, required this.count});

  factory BloodTypeCount.fromJson(Map<String, dynamic> json) {
    return BloodTypeCount(
      type: json['_id']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

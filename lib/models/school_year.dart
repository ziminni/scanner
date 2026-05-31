import 'package:cloud_firestore/cloud_firestore.dart';

import 'model_serializers.dart';

class SchoolYear {
  const SchoolYear({
    required this.id,
    required this.name,
    required this.isActive,
    required this.archived,
    required this.termStarts,
    required this.termEnds,
  });

  final String id;
  final String name;
  final bool isActive;
  final bool archived;
  final List<DateTime?> termStarts;
  final List<DateTime?> termEnds;

  bool get hasCompleteTerms =>
      termStarts.length >= 3 &&
      termEnds.length >= 3 &&
      termStarts.every((date) => date != null) &&
      termEnds.every((date) => date != null);

  DateTime? get finalTermEnd => termEnds.length >= 3 ? termEnds[2] : null;

  bool isFinished(DateTime date) {
    final end = finalTermEnd;
    if (end == null) return false;
    return date.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59));
  }

  String activeTermName(DateTime date) {
    for (var index = 0; index < 3; index++) {
      final start = termStarts.length > index ? termStarts[index] : null;
      final end = termEnds.length > index ? termEnds[index] : null;
      if (start != null &&
          end != null &&
          !date.isBefore(start) &&
          !date.isAfter(end)) {
        return '${index + 1}${index == 0
            ? 'st'
            : index == 1
            ? 'nd'
            : 'rd'} Term';
      }
    }
    return 'Outside Term';
  }

  factory SchoolYear.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return SchoolYear.fromMap(doc.id, doc.data() ?? {});
  }

  factory SchoolYear.fromMap(String id, Map<String, dynamic> data) {
    return SchoolYear(
      id: id,
      name: data['name'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? false,
      archived: data['archived'] as bool? ?? false,
      termStarts: [
        toDate(data['term1Start']),
        toDate(data['term2Start']),
        toDate(data['term3Start']),
      ],
      termEnds: [
        toDate(data['term1End']),
        toDate(data['term2End']),
        toDate(data['term3End']),
      ],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'isActive': isActive,
    'archived': archived,
    'term1Start': fromDate(termStarts.elementAtOrNull(0)),
    'term1End': fromDate(termEnds.elementAtOrNull(0)),
    'term2Start': fromDate(termStarts.elementAtOrNull(1)),
    'term2End': fromDate(termEnds.elementAtOrNull(1)),
    'term3Start': fromDate(termStarts.elementAtOrNull(2)),
    'term3End': fromDate(termEnds.elementAtOrNull(2)),
  };
}

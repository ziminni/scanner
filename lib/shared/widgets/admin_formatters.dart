import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

String adminLabel(String key) {
  final spaced = key
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}');
  return spaced[0].toUpperCase() + spaced.substring(1);
}

String adminFormatValue(Object? value) {
  if (value == null) {
    return '-';
  }
  if (value is Timestamp) {
    return DateFormat('MMM d, yyyy').format(value.toDate());
  }
  return value.toString();
}

String adminTableSearchValue(Map<String, dynamic> data, String column) {
  if (column == 'fullName') return adminPersonName(data);
  return adminFormatValue(data[column]);
}

String adminPersonName(Map<String, dynamic> data) {
  final lastName = (data['lastName'] as String? ?? '').trim();
  final firstName = (data['firstName'] as String? ?? '').trim();
  final middleName = (data['middleName'] as String? ?? '').trim();
  final middleInitial = middleName.isEmpty ? '' : ' ${middleName[0]}.';
  if (lastName.isEmpty && firstName.isEmpty) return '-';
  if (lastName.isEmpty) return '$firstName$middleInitial';
  if (firstName.isEmpty) return lastName;
  return '$lastName, $firstName$middleInitial';
}

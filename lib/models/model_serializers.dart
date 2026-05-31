import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? toDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

dynamic fromDate(DateTime? value) =>
    value == null ? null : Timestamp.fromDate(value);

import 'package:cloud_firestore/cloud_firestore.dart';

import 'model_serializers.dart';

class Student {
  const Student({
    required this.id,
    required this.lrn,
    required this.lastName,
    required this.firstName,
    this.middleName = '',
    this.gender = '',
    this.birthdate,
    this.address = '',
    this.guardianName = '',
    this.guardianContact = '',
    this.section = '',
    this.status = 'Active',
    this.archived = false,
  });

  final String id;
  final String lrn;
  final String lastName;
  final String firstName;
  final String middleName;
  final String gender;
  final DateTime? birthdate;
  final String address;
  final String guardianName;
  final String guardianContact;
  final String section;
  final String status;
  final bool archived;

  String get fullName => [
    lastName,
    firstName,
    middleName,
  ].where((p) => p.trim().isNotEmpty).join(', ');

  factory Student.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Student(
      id: doc.id,
      lrn: data['lrn'] as String? ?? doc.id,
      lastName: data['lastName'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      middleName: data['middleName'] as String? ?? '',
      gender: data['gender'] as String? ?? '',
      birthdate: toDate(data['birthdate']),
      address: data['address'] as String? ?? '',
      guardianName: data['guardianName'] as String? ?? '',
      guardianContact: data['guardianContact'] as String? ?? '',
      section: data['section'] as String? ?? '',
      status: data['status'] as String? ?? 'Active',
      archived: data['archived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'lrn': lrn,
    'lastName': lastName,
    'firstName': firstName,
    'middleName': middleName,
    'gender': gender,
    'birthdate': fromDate(birthdate),
    'address': address,
    'guardianName': guardianName,
    'guardianContact': guardianContact,
    'section': section,
    'status': status,
    'archived': archived,
  };
}

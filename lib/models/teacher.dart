import 'package:cloud_firestore/cloud_firestore.dart';

import 'model_serializers.dart';

class Teacher {
  const Teacher({
    required this.id,
    required this.teacherId,
    required this.lastName,
    required this.firstName,
    this.middleName = '',
    this.gender = '',
    this.birthdate,
    this.address = '',
    this.contactNumber = '',
    this.assignedTimeIn = '07:00',
    this.assignedTimeOut = '17:00',
    this.status = 'Active',
    this.archived = false,
  });

  final String id;
  final String teacherId;
  final String lastName;
  final String firstName;
  final String middleName;
  final String gender;
  final DateTime? birthdate;
  final String address;
  final String contactNumber;
  final String assignedTimeIn;
  final String assignedTimeOut;
  final String status;
  final bool archived;

  String get fullName => [
    lastName,
    firstName,
    middleName,
  ].where((p) => p.trim().isNotEmpty).join(', ');

  factory Teacher.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Teacher(
      id: doc.id,
      teacherId: data['teacherId'] as String? ?? doc.id,
      lastName: data['lastName'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      middleName: data['middleName'] as String? ?? '',
      gender: data['gender'] as String? ?? '',
      birthdate: toDate(data['birthdate']),
      address: data['address'] as String? ?? '',
      contactNumber: data['contactNumber'] as String? ?? '',
      assignedTimeIn: data['assignedTimeIn'] as String? ?? '07:00',
      assignedTimeOut: data['assignedTimeOut'] as String? ?? '17:00',
      status: data['status'] as String? ?? 'Active',
      archived: data['archived'] as bool? ?? false,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/services/app_controller.dart';
import 'base_viewmodel.dart';

class StudentsViewModel extends BaseViewModel {
  StudentsViewModel(this._app);

  final AppController _app;
  final controllers = {
    for (final field in studentFields)
      if (field != 'section' && field != 'status')
        field: TextEditingController(),
  };
  String? selectedSection;
  DateTime? birthdate;
  String? message;

  Stream<QuerySnapshot<Map<String, dynamic>>> get sectionsStream async* {
    final schoolYear = await _app.attendance.activeSchoolYear();
    if (schoolYear == null) return;
    yield* _app.firestore
        .collection('school_years')
        .doc(schoolYear.id)
        .collection('sections')
        .where('archived', isEqualTo: false)
        .snapshots();
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void selectSection(String? section) {
    selectedSection = section;
    notifyListeners();
  }

  void setBirthdate(DateTime? date) {
    birthdate = date;
    notifyListeners();
  }

  Future<void> addStudent() async {
    final schoolYear = await _app.attendance.activeSchoolYear();
    if (schoolYear == null) {
      message = 'Create an active school year before adding students.';
      notifyListeners();
      return;
    }
    if (selectedSection == null) return;

    final data = {
      for (final entry in controllers.entries)
        entry.key: entry.value.text.trim(),
      'birthdate': birthdate == null ? null : Timestamp.fromDate(birthdate!),
      'section': selectedSection,
      'status': 'Active',
      'schoolYearId': schoolYear.id,
      'schoolYear': schoolYear.name,
      'archived': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await _app.firestore
        .collection('school_years')
        .doc(schoolYear.id)
        .collection('students')
        .add(data);
    await _app.audit.record(
      action: 'students_created',
      actorId: _app.currentUser!.id,
      actorName: _app.currentUser!.fullName,
      target: controllers['lrn']?.text.trim() ?? '',
      metadata: {'schoolYear': schoolYear.name},
    );
    message = null;
    notifyListeners();
  }
}

const studentFields = [
  'lrn',
  'lastName',
  'firstName',
  'middleName',
  'birthdate',
  'address',
  'guardianName',
  'guardianContact',
  'section',
  'status',
];

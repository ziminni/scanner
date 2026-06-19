import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_controller.dart';
import 'base_viewmodel.dart';

class StudentsViewModel extends BaseViewModel {
  StudentsViewModel(this._app);

  final AppController _app;
  final controllers = {
    for (final field in studentFields)
      if (field != 'gender' && field != 'section' && field != 'status')
        field: TextEditingController(),
  };
  String? selectedSection;
  String? selectedGender;
  DateTime? birthdate;
  String? message;

  Stream<QuerySnapshot<Map<String, dynamic>>> get sectionsStream =>
      _app.repository.activeSectionsStream();

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

  void selectGender(String? gender) {
    selectedGender = gender;
    notifyListeners();
  }

  Future<void> addStudent() async {
    setBusy(true);
    final schoolYear = await _app.attendance.activeSchoolYear();
    if (schoolYear == null) {
      message = 'Create an active school year before adding students.';
      setBusy(false);
      return;
    }
    if (selectedSection == null) {
      setBusy(false);
      return;
    }
    if (selectedGender == null) {
      message = 'Gender is required.';
      setBusy(false);
      return;
    }

    try {
      final data = {
        for (final entry in controllers.entries)
          entry.key: entry.value.text.trim(),
        'birthdate': birthdate == null ? null : Timestamp.fromDate(birthdate!),
        'gender': selectedGender,
        'section': selectedSection,
        'status': 'Active',
        'schoolYearId': schoolYear.id,
        'schoolYear': schoolYear.name,
        'archived': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _app.repository.addSchoolYearRecord(
        schoolYear: schoolYear,
        collection: 'students',
        data: data,
      );
      await _app.audit.record(
        action: 'students_created',
        actorId: _app.currentUser!.id,
        actorName: _app.currentUser!.fullName,
        target: controllers['lrn']?.text.trim() ?? '',
        metadata: {'schoolYear': schoolYear.name},
      );
      message = null;
    } catch (error) {
      message = error.toString();
    } finally {
      setBusy(false);
    }
  }
}

const studentFields = [
  'lrn',
  'lastName',
  'firstName',
  'middleName',
  'gender',
  'birthdate',
  'address',
  'guardianName',
  'guardianContact',
  'section',
  'status',
];

const studentTableFields = [
  'lrn',
  'fullName',
  'gender',
  'birthdate',
  'address',
  'guardianName',
  'guardianContact',
  'section',
];

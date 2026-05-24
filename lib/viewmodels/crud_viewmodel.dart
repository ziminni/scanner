import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/services/app_controller.dart';
import 'base_viewmodel.dart';

class CrudViewModel extends BaseViewModel {
  CrudViewModel({
    required AppController app,
    required this.collection,
    required this.fields,
  }) : _app = app {
    controllers.addAll({
      for (final field in fields)
        if (field != 'status' &&
            !_usesDropdown(field) &&
            !_usesTimePicker(field))
          field: TextEditingController(),
    });
  }

  final AppController _app;
  final String collection;
  final List<String> fields;
  final Map<String, TextEditingController> controllers = {};
  DateTime? birthdate;
  TimeOfDay? assignedTimeIn;
  TimeOfDay? assignedTimeOut;
  TeacherOption? selectedAdviser;

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool usesDropdown(String field) => _usesDropdown(field);

  bool usesTimePicker(String field) => _usesTimePicker(field);

  void setBirthdate(DateTime? date) {
    birthdate = date;
    notifyListeners();
  }

  void setAssignedTimeIn(TimeOfDay time) {
    assignedTimeIn = time;
    notifyListeners();
  }

  void setAssignedTimeOut(TimeOfDay time) {
    assignedTimeOut = time;
    notifyListeners();
  }

  void setAdviser(TeacherOption? teacher) {
    selectedAdviser = teacher;
    notifyListeners();
  }

  Future<void> addRecord() async {
    final schoolYear = await _app.attendance.activeSchoolYear();
    if (schoolYear == null) {
      setError('Create an active school year before adding records.');
      return;
    }

    final data = {
      for (final entry in controllers.entries)
        entry.key: entry.value.text.trim(),
      if (fields.contains('birthdate'))
        'birthdate': birthdate == null ? null : Timestamp.fromDate(birthdate!),
      if (fields.contains('adviser')) ...{
        'adviser': selectedAdviser?.name ?? '',
        'adviserTeacherId': selectedAdviser?.teacherId ?? '',
        'adviserDocId': selectedAdviser?.docId ?? '',
      },
      if (fields.contains('assignedTimeIn'))
        'assignedTimeIn': _timeToStorage(
          assignedTimeIn ?? const TimeOfDay(hour: 7, minute: 0),
        ),
      if (fields.contains('assignedTimeOut'))
        'assignedTimeOut': _timeToStorage(
          assignedTimeOut ?? const TimeOfDay(hour: 17, minute: 0),
        ),
      if (fields.contains('status')) 'status': 'Active',
      'schoolYearId': schoolYear.id,
      'schoolYear': schoolYear.name,
      'archived': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _app.firestore
        .collection('school_years')
        .doc(schoolYear.id)
        .collection(collection)
        .add(data);

    await _app.audit.record(
      action: '${collection}_created',
      actorId: _app.currentUser!.id,
      actorName: _app.currentUser!.fullName,
    );
  }

  bool _usesDropdown(String field) =>
      collection == 'sections' && field == 'adviser';

  bool _usesTimePicker(String field) =>
      collection == 'teachers' &&
      (field == 'assignedTimeIn' || field == 'assignedTimeOut');

  String _timeToStorage(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class TeacherOption {
  const TeacherOption({
    required this.docId,
    required this.teacherId,
    required this.name,
  });

  final String docId;
  final String teacherId;
  final String name;
}

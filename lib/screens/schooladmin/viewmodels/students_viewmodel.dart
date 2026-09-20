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
  bool isAral = false;
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

  void setIsAral(bool value) {
    isAral = value;
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
        'isAral': isAral,
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

  Future<List<TransferStudentInfo>> loadTransferStudents(
    List<String> studentIds,
  ) async {
    final schoolYear = await _app.attendance.activeSchoolYear();
    if (schoolYear == null) return [];

    final students = <TransferStudentInfo>[];
    for (var start = 0; start < studentIds.length; start += 30) {
      final ids = studentIds.skip(start).take(30).toList();
      final snapshot = await _app.repository
          .schoolYearCollection(schoolYear.id, 'students')
          .where(FieldPath.documentId, whereIn: ids)
          .get();
      students.addAll(
        snapshot.docs.map((doc) {
          final data = doc.data();
          return TransferStudentInfo(
            id: doc.id,
            name: studentDisplayName(data),
            lrn: data['lrn']?.toString().trim() ?? '',
            section: data['section']?.toString().trim() ?? '',
          );
        }),
      );
    }
    students.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return students;
  }

  Future<void> transferStudentsToSection({
    required List<String> studentIds,
    required String section,
  }) async {
    final schoolYear = await _app.attendance.activeSchoolYear();
    if (schoolYear == null) {
      throw Exception('Create an active school year before transferring.');
    }

    for (var start = 0; start < studentIds.length; start += 450) {
      final batch = _app.firestore.batch();
      for (final studentId in studentIds.skip(start).take(450)) {
        batch.set(
          _app.repository
              .schoolYearCollection(schoolYear.id, 'students')
              .doc(studentId),
          {'section': section, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    }
    await _app.audit.record(
      action: 'students_transferred_section',
      actorId: _app.currentUser!.id,
      actorName: _app.currentUser!.fullName,
      target: '${studentIds.length} students',
      metadata: {
        'schoolYear': schoolYear.name,
        'studentIds': studentIds,
        'section': section,
      },
    );
  }

  Future<void> transferStudentsAralStatus({
    required List<String> studentIds,
    required bool isAral,
    required String auditAction,
  }) async {
    final schoolYear = await _app.attendance.activeSchoolYear();
    if (schoolYear == null) {
      throw Exception('Create an active school year before transferring.');
    }

    for (var start = 0; start < studentIds.length; start += 450) {
      final batch = _app.firestore.batch();
      for (final studentId in studentIds.skip(start).take(450)) {
        batch.set(
          _app.repository
              .schoolYearCollection(schoolYear.id, 'students')
              .doc(studentId),
          {'isAral': isAral, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    }
    await _app.audit.record(
      action: auditAction,
      actorId: _app.currentUser!.id,
      actorName: _app.currentUser!.fullName,
      target: '${studentIds.length} students',
      metadata: {'schoolYear': schoolYear.name, 'studentIds': studentIds},
    );
  }
}

class TransferStudentInfo {
  const TransferStudentInfo({
    required this.id,
    required this.name,
    required this.lrn,
    required this.section,
  });

  final String id;
  final String name;
  final String lrn;
  final String section;
}

String studentDisplayName(Map<String, dynamic> data) {
  final fullName = data['fullName']?.toString().trim() ?? '';
  if (fullName.isNotEmpty) return fullName;

  final lastName = data['lastName']?.toString().trim() ?? '';
  final firstName = data['firstName']?.toString().trim() ?? '';
  final middleName = data['middleName']?.toString().trim() ?? '';
  final middleInitial = middleName.isEmpty ? '' : ' ${middleName[0]}.';
  final derivedName = '$lastName, $firstName$middleInitial'.trim();
  return derivedName == ',' ? 'Unnamed student' : derivedName;
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

const studentDetailFields = [...studentTableFields, 'isAral'];

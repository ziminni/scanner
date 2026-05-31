import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/models.dart';
import '../services/audit_service.dart';

class FirebaseRepository {
  const FirebaseRepository(this._firestore, this._audit);

  final FirebaseFirestore _firestore;
  final AuditService _audit;

  CollectionReference<Map<String, dynamic>> rootCollection(String collection) {
    return _firestore.collection(collection);
  }

  Query<Map<String, dynamic>> collectionGroup(String collection) {
    return _firestore.collectionGroup(collection);
  }

  Query<Map<String, dynamic>> usersQuery() {
    return _firestore.collection('users');
  }

  Query<Map<String, dynamic>> activeStaffScannerUsersQuery() {
    return usersQuery()
        .where('role', isEqualTo: 'staff_scanner')
        .where('status', isEqualTo: 'active');
  }

  Query<Map<String, dynamic>> activeCollectionGroupQuery(String collection) {
    return collectionGroup(collection).where('archived', isEqualTo: false);
  }

  Query<Map<String, dynamic>> attendanceStatusCollectionGroupQuery(
    String status,
  ) {
    return collectionGroup(
      'attendance_logs',
    ).where('attendanceStatus', isEqualTo: status);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> usersStream() {
    return usersQuery().orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> auditLogsStream(int limit) {
    return rootCollection(
      'audit_logs',
    ).orderBy('createdAt', descending: true).limit(limit).snapshots();
  }

  CollectionReference<Map<String, dynamic>> schoolYearCollection(
    String schoolYearId,
    String collection,
  ) {
    return _firestore
        .collection('school_years')
        .doc(schoolYearId)
        .collection(collection);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> activeSectionsStream() {
    return _firestore
        .collection('sections')
        .where('archived', isEqualTo: false)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> activeTeachersStream(
    String schoolYearId,
  ) {
    return schoolYearCollection(
      schoolYearId,
      'teachers',
    ).where('archived', isEqualTo: false).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> studentsBySectionStream({
    required String schoolYearId,
    required String sectionName,
  }) {
    return schoolYearCollection(schoolYearId, 'students')
        .where('section', isEqualTo: sectionName)
        .where('archived', isEqualTo: false)
        .snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> activeStudents(
    String schoolYearId,
  ) {
    return schoolYearCollection(
      schoolYearId,
      'students',
    ).where('archived', isEqualTo: false).get();
  }

  Future<Set<String>> schoolYearFieldValues({
    required String schoolYearId,
    required String collection,
    required String field,
  }) async {
    final snapshot = await schoolYearCollection(schoolYearId, collection).get();
    return snapshot.docs
        .map((doc) => doc.data()[field]?.toString().trim().toLowerCase() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> activeTeachers(
    String schoolYearId,
  ) {
    return schoolYearCollection(
      schoolYearId,
      'teachers',
    ).where('archived', isEqualTo: false).get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> attendanceLogsForDate({
    required String schoolYearId,
    required String dateKey,
  }) {
    return schoolYearCollection(
      schoolYearId,
      'attendance_logs',
    ).where('dateKey', isEqualTo: dateKey).get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> attendanceLogsForRange({
    required String schoolYearId,
    required DateTime start,
    required DateTime end,
  }) {
    return schoolYearCollection(schoolYearId, 'attendance_logs')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> attendanceLogsLimit({
    required String schoolYearId,
    required int limit,
  }) {
    return schoolYearCollection(
      schoolYearId,
      'attendance_logs',
    ).limit(limit).get();
  }

  Future<void> addGlobalRecord({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    await rootCollection(collection).add(data);
  }

  Future<void> addSchoolYearRecord({
    required SchoolYear schoolYear,
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    await schoolYearCollection(schoolYear.id, collection).add(data);
  }

  Future<void> addSchoolYearRecords({
    required SchoolYear schoolYear,
    required String collection,
    required List<Map<String, dynamic>> records,
  }) async {
    if (records.isEmpty) return;
    var batch = _firestore.batch();
    var writes = 0;

    for (final data in records) {
      final doc = schoolYearCollection(schoolYear.id, collection).doc();
      batch.set(doc, data);
      writes++;
      if (writes == 450) {
        await batch.commit();
        batch = _firestore.batch();
        writes = 0;
      }
    }

    if (writes > 0) await batch.commit();
  }

  Future<void> archiveGlobalRecord({
    required String collection,
    required String docId,
    required String actorId,
    required String actorName,
    String? target,
  }) async {
    await rootCollection(collection).doc(docId).set({
      'archived': true,
      'archivedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _audit.record(
      action: '${collection}_archived',
      actorId: actorId,
      actorName: actorName,
      target: target ?? '',
    );
  }

  Future<DocumentReference<Map<String, dynamic>>> createSchoolYear(
    Map<String, dynamic> data,
  ) {
    return _firestore.collection('school_years').add(data);
  }
}

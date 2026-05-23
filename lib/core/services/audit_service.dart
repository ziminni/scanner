import 'package:cloud_firestore/cloud_firestore.dart';

class AuditService {
  AuditService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> record({
    required String action,
    required String actorId,
    required String actorName,
    String target = '',
    Map<String, dynamic> metadata = const {},
  }) async {
    await _firestore.collection('audit_logs').add({
      'action': action,
      'actorId': actorId,
      'actorName': actorName,
      'target': target,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> recent({int limit = 100}) {
    return _firestore
        .collection('audit_logs')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }
}

class ActivitySummary {
  const ActivitySummary({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  static ActivitySummary fromAuditDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ActivitySummary(
      title: data['action'] as String? ?? 'Activity',
      subtitle:
          '${data['actorName'] as String? ?? 'System'} ${data['target'] as String? ?? ''}',
    );
  }
}

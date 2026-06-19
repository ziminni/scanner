import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/enums.dart';
import 'model_serializers.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.status,
    this.schoolId = 'default',
    this.createdAt,
    this.lastLoginAt,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final AccountStatus status;
  final String schoolId;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  bool get isActive => status == AccountStatus.active;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser.fromMap(doc.id, data);
  }

  factory AppUser.fromMap(String id, Map<String, dynamic> data) => AppUser(
    id: id,
    email: data['email'] as String? ?? '',
    fullName: data['fullName'] as String? ?? data['name'] as String? ?? '',
    role: UserRole.fromKey(data['role'] as String?),
    status: AccountStatus.fromKey(data['status'] as String?),
    schoolId: data['schoolId'] as String? ?? 'default',
    createdAt: toDate(data['createdAt']),
    lastLoginAt: toDate(data['lastLoginAt']),
  );

  Map<String, dynamic> toMap() => {
    'email': email,
    'fullName': fullName,
    'role': role.key,
    'status': status.name,
    'schoolId': schoolId,
    'createdAt': fromDate(createdAt),
    'lastLoginAt': fromDate(lastLoginAt),
  };
}

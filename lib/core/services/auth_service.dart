import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/enums.dart';
import '../../models/models.dart';
import 'audit_service.dart';

class AuthService {
  AuthService(this._auth, this._firestore, this._auditService);

  static const _bootstrapSystemAdminUid = 'FKg721Q77UdegDvMf8boGYcEYd53';
  static const _bootstrapSystemAdminEmail = 'systemadmin@user.com';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final AuditService _auditService;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get firebaseUser => _auth.currentUser;

  Future<AppUser?> loadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      final bootstrapped = await _bootstrapSystemAdminProfile(user);
      if (bootstrapped == null) {
        await logout(reason: 'missing_user_profile');
        return null;
      }
      return bootstrapped;
    }
    final appUser = AppUser.fromDoc(doc);
    if (!appUser.isActive) {
      await _auditService.record(
        action: 'blocked_login_disabled_account',
        actorId: appUser.id,
        actorName: appUser.fullName,
      );
      await logout(reason: 'disabled_account');
      return null;
    }
    return appUser;
  }

  Future<AppUser> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      final bootstrapped = await _bootstrapSystemAdminProfile(credential.user!);
      if (bootstrapped != null) {
        await _auditService.record(
          action: 'bootstrap_system_admin_login',
          actorId: uid,
          actorName: bootstrapped.fullName,
        );
        return bootstrapped;
      }
      await _auditService.record(
        action: 'failed_login_no_profile',
        actorId: uid,
        actorName: email,
      );
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'profile-missing',
        message: 'No role profile is assigned to this account.',
      );
    }

    final appUser = AppUser.fromDoc(doc);
    if (!appUser.isActive) {
      await _auditService.record(
        action: 'failed_login_disabled',
        actorId: uid,
        actorName: appUser.fullName,
      );
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'account-disabled',
        message: 'This account is disabled.',
      );
    }

    await _firestore.collection('users').doc(uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
    await _auditService.record(
      action: 'login',
      actorId: uid,
      actorName: appUser.fullName,
    );
    return appUser;
  }

  Future<void> logout({String reason = 'user_logout'}) async {
    final current = _auth.currentUser;
    if (current != null) {
      final doc = await _firestore.collection('users').doc(current.uid).get();
      final appUser = doc.exists ? AppUser.fromDoc(doc) : null;
      await _auditService.record(
        action: 'logout',
        actorId: current.uid,
        actorName: appUser?.fullName ?? current.email ?? 'Unknown',
        metadata: {'reason': reason},
      );
    }
    await _auth.signOut();
  }

  Future<AppUser?> _bootstrapSystemAdminProfile(User user) async {
    final email = user.email?.toLowerCase();
    if (user.uid != _bootstrapSystemAdminUid ||
        email != _bootstrapSystemAdminEmail) {
      return null;
    }

    final appUser = AppUser(
      id: user.uid,
      email: _bootstrapSystemAdminEmail,
      fullName: 'System Administrator',
      role: UserRole.systemAdministrator,
      status: AccountStatus.active,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set({
      ...appUser.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'bootstrap': true,
    });
    return appUser;
  }

  bool canAccess(AppUser user, String pageId) {
    final allowed = switch (user.role) {
      UserRole.systemAdministrator => _systemAdminPages,
      UserRole.schoolAdministrator => _schoolAdminPages,
      UserRole.staffScanner => _scannerPages,
    };
    return allowed.contains(pageId);
  }

  static const _systemAdminPages = {
    'dashboard',
    'users',
    'audit',
    'settings',
    'database',
    'archives',
    'scanner',
    'logs',
  };

  static const _schoolAdminPages = {
    'dashboard',
    'scannerUsers',
    'schoolYears',
    'students',
    'sections',
    'teachers',
    'logs',
    'attendanceStatus',
    'earlyStudents',
    'reports',
    'archives',
  };

  static const _scannerPages = {'scanner', 'logs'};
}

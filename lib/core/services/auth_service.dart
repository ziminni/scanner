import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/enums.dart';
import '../../models/models.dart';
import 'audit_service.dart';

class AuthService {
  AuthService(this._auth, this._firestore, this._auditService);

  static const _bootstrapSystemAdminUid = 'FKg721Q77UdegDvMf8boGYcEYd53';
  static const _bootstrapSystemAdminEmail = 'systemadmin@user.com';
  static const _cachedUserProfileKey = 'cached_current_user_profile';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final AuditService _auditService;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get firebaseUser => _auth.currentUser;

  Future<AppUser?> loadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final DocumentSnapshot<Map<String, dynamic>> doc;
    try {
      doc = await _firestore.collection('users').doc(user.uid).get();
    } on FirebaseException {
      return _loadCachedUserProfile(user.uid);
    }
    if (!doc.exists) {
      final bootstrapped = await _bootstrapSystemAdminProfile(user);
      if (bootstrapped == null) {
        await logout(reason: 'missing_user_profile');
        return null;
      }
      return bootstrapped;
    }
    final appUser = await _syncVerifiedEmail(user, AppUser.fromDoc(doc));
    if (_isWebScannerAccount(appUser)) {
      await logout(reason: 'scanner_web_access_blocked');
      return null;
    }
    if (_isMobileAdminAccount(appUser)) {
      await logout(reason: 'admin_mobile_access_blocked');
      return null;
    }
    if (!appUser.isActive) {
      await _clearCachedUserProfile();
      await _auditService.record(
        action: 'blocked_login_disabled_account',
        actorId: appUser.id,
        actorName: appUser.fullName,
      );
      await logout(reason: 'disabled_account');
      return null;
    }
    await _cacheUserProfile(appUser);
    return appUser;
  }

  Future<AppUser> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final UserCredential credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      await _auditService.record(
        action: _failedLoginAction(error.code),
        actorId: normalizedEmail,
        actorName: normalizedEmail.isEmpty ? 'Unknown email' : normalizedEmail,
        target: 'Firebase Authentication',
        metadata: {
          'email': normalizedEmail,
          'code': error.code,
          'message': error.message ?? '',
          'platform': kIsWeb ? 'web' : 'mobile',
        },
      );
      rethrow;
    }
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

    final appUser = await _syncVerifiedEmail(
      credential.user!,
      AppUser.fromDoc(doc),
    );
    if (_isWebScannerAccount(appUser)) {
      await _auditService.record(
        action: 'failed_login_scanner_web_blocked',
        actorId: uid,
        actorName: appUser.fullName,
      );
      await _auth.signOut();
      await _clearCachedUserProfile();
      throw FirebaseAuthException(
        code: 'scanner-web-blocked',
        message: 'Staff Scanner accounts can only sign in on the mobile app.',
      );
    }
    if (_isMobileAdminAccount(appUser)) {
      await _auditService.record(
        action: 'failed_login_admin_mobile_blocked',
        actorId: uid,
        actorName: appUser.fullName,
      );
      await _auth.signOut();
      await _clearCachedUserProfile();
      throw FirebaseAuthException(
        code: 'admin-mobile-blocked',
        message: 'Administrator accounts can only sign in on the web system.',
      );
    }
    if (!appUser.isActive) {
      await _clearCachedUserProfile();
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
    await _cacheUserProfile(appUser);
    return appUser;
  }

  String _failedLoginAction(String code) {
    return switch (code) {
      'wrong-password' ||
      'invalid-credential' ||
      'invalid-login-credentials' => 'failed_login_invalid_credentials',
      'user-not-found' => 'failed_login_unknown_email',
      'too-many-requests' => 'failed_login_rate_limited',
      'user-disabled' => 'failed_login_firebase_disabled',
      _ => 'failed_login_error',
    };
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
    await _clearCachedUserProfile();
  }

  Future<AppUser> updateCurrentUserProfile({
    required String fullName,
    required String email,
    required bool sendPasswordReset,
  }) async {
    final current = _auth.currentUser;
    if (current == null) {
      throw FirebaseAuthException(
        code: 'not-signed-in',
        message: 'Please log in again before updating your profile.',
      );
    }

    final trimmedName = fullName.trim();
    final normalizedEmail = email.trim().toLowerCase();
    if (trimmedName.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-display-name',
        message: 'Name is required.',
      );
    }
    if (!normalizedEmail.contains('@')) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Please enter a valid email address.',
      );
    }

    final docRef = _firestore.collection('users').doc(current.uid);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw FirebaseAuthException(
        code: 'profile-missing',
        message: 'No role profile is assigned to this account.',
      );
    }
    final existing = AppUser.fromDoc(snapshot);

    await current.updateDisplayName(trimmedName);

    var passwordResetSent = false;
    if (sendPasswordReset) {
      await _auth.sendPasswordResetEmail(email: existing.email);
      passwordResetSent = true;
    }

    final emailChanged = normalizedEmail != existing.email.toLowerCase();
    var emailVerificationSent = false;
    if (emailChanged) {
      await current.verifyBeforeUpdateEmail(normalizedEmail);
      emailVerificationSent = true;
    }

    await docRef.set({
      'fullName': trimmedName,
      if (emailChanged) 'pendingEmail': normalizedEmail,
      if (!emailChanged) 'pendingEmail': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _auditService.record(
      action: 'profile_updated',
      actorId: current.uid,
      actorName: trimmedName,
      target: existing.email,
      metadata: {
        'emailChangeRequested': emailChanged,
        'emailVerificationSent': emailVerificationSent,
        'passwordResetSent': passwordResetSent,
      },
    );

    final updatedSnapshot = await docRef.get();
    final updated = AppUser.fromDoc(updatedSnapshot);
    await _cacheUserProfile(updated);
    return updated;
  }

  Future<AppUser> _syncVerifiedEmail(User firebaseUser, AppUser appUser) async {
    final authEmail = firebaseUser.email?.trim().toLowerCase();
    if (authEmail == null ||
        authEmail.isEmpty ||
        authEmail == appUser.email.toLowerCase()) {
      return appUser;
    }
    await _firestore.collection('users').doc(firebaseUser.uid).set({
      'email': authEmail,
      'pendingEmail': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return AppUser(
      id: appUser.id,
      email: authEmail,
      fullName: appUser.fullName,
      role: appUser.role,
      status: appUser.status,
      schoolId: appUser.schoolId,
      createdAt: appUser.createdAt,
      lastLoginAt: appUser.lastLoginAt,
    );
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
    await _cacheUserProfile(appUser);
    return appUser;
  }

  Future<void> _cacheUserProfile(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cachedUserProfileKey,
      jsonEncode({
        'id': user.id,
        'email': user.email,
        'fullName': user.fullName,
        'role': user.role.key,
        'status': user.status.name,
        'schoolId': user.schoolId,
        'createdAt': user.createdAt?.toIso8601String(),
        'lastLoginAt': user.lastLoginAt?.toIso8601String(),
      }),
    );
  }

  Future<AppUser?> _loadCachedUserProfile(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedUserProfileKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    if (decoded['id'] != uid) return null;
    final cached = AppUser.fromMap(uid, decoded);
    if (_isWebScannerAccount(cached)) return null;
    if (_isMobileAdminAccount(cached)) return null;
    return cached.isActive ? cached : null;
  }

  Future<void> _clearCachedUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedUserProfileKey);
  }

  bool _isWebScannerAccount(AppUser user) {
    return kIsWeb && user.role == UserRole.staffScanner;
  }

  bool _isMobileAdminAccount(AppUser user) {
    return !kIsWeb && user.role != UserRole.staffScanner;
  }

  bool canAccess(AppUser user, String pageId) {
    if (_isWebScannerAccount(user) || _isMobileAdminAccount(user)) {
      return false;
    }
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
    'logs',
  };

  static const _schoolAdminPages = {
    'dashboard',
    'schoolYears',
    'students',
    'sections',
    'teachers',
    'logs',
    'attendanceStatus',
    'earlyStudents',
    'reports',
  };

  static const _scannerPages = {
    'scannerHome',
    'scanner',
    'logs',
    'scannerSettings',
  };
}

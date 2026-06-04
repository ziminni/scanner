import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../repositories/firebase_repository.dart';
import 'admin_service.dart';
import 'attendance_service.dart';
import 'audit_service.dart';
import 'auth_service.dart';
import 'offline_queue_service.dart';
import 'sms_notification_service.dart';

class AppController extends ChangeNotifier {
  AppController() {
    audit = AuditService(firestore);
    sms = SmsNotificationService();
    offlineQueue = OfflineQueueService(Connectivity());
    auth = AuthService(firebaseAuth, firestore, audit);
    attendance = AttendanceService(firestore, offlineQueue, audit, sms);
    admin = AdminService(firestore, firebaseAuth, storage, audit);
    repository = FirebaseRepository(firestore, audit);
  }

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  late final AuditService audit;
  late final SmsNotificationService sms;
  late final OfflineQueueService offlineQueue;
  late final AuthService auth;
  late final AttendanceService attendance;
  late final AdminService admin;
  late final FirebaseRepository repository;

  AppUser? currentUser;
  bool loading = true;
  String? authError;

  Future<void> initialize() async {
    await offlineQueue.initialize();
    await offlineQueue.startNetworkWatcher();
    if (kIsWeb) {
      await firebaseAuth.setPersistence(Persistence.LOCAL);
    }
    firebaseAuth.authStateChanges().listen((_) => refreshUser());
    await refreshUser();
  }

  Future<void> refreshUser() async {
    loading = true;
    notifyListeners();
    currentUser = await auth.loadCurrentUser();
    loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    authError = null;
    loading = true;
    notifyListeners();
    try {
      currentUser = await auth.login(email, password);
    } catch (error) {
      authError = error.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await auth.logout();
    currentUser = null;
    notifyListeners();
  }

  Future<AppUser> updateProfile({
    required String fullName,
    required String email,
    required bool sendPasswordReset,
  }) async {
    final updated = await auth.updateCurrentUserProfile(
      fullName: fullName,
      email: email,
      sendPasswordReset: sendPasswordReset,
    );
    currentUser = updated;
    notifyListeners();
    return updated;
  }

  void logoutForUnauthorizedAccess() {
    currentUser = null;
    scheduleMicrotask(notifyListeners);
    unawaited(auth.logout(reason: 'unauthorized_route'));
  }

  void recordUnauthorizedAccess(String pageId, String location) {
    final user = currentUser;
    if (user == null) return;
    unawaited(
      audit.record(
        action: 'unauthorized_access_attempt',
        actorId: user.id,
        actorName: user.fullName,
        target: location,
        metadata: {
          'pageId': pageId,
          'role': user.role.label,
          'email': user.email,
        },
      ),
    );
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.notifier!;
  }
}

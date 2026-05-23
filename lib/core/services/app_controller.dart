import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../models/models.dart';
import 'admin_service.dart';
import 'attendance_service.dart';
import 'audit_service.dart';
import 'auth_service.dart';
import 'offline_queue_service.dart';

class AppController extends ChangeNotifier {
  AppController() {
    audit = AuditService(firestore);
    offlineQueue = OfflineQueueService(Connectivity());
    auth = AuthService(firebaseAuth, firestore, audit);
    attendance = AttendanceService(firestore, offlineQueue, audit);
    admin = AdminService(firestore, firebaseAuth, storage, audit);
  }

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  late final AuditService audit;
  late final OfflineQueueService offlineQueue;
  late final AuthService auth;
  late final AttendanceService attendance;
  late final AdminService admin;

  AppUser? currentUser;
  bool loading = true;
  String currentPage = 'dashboard';
  String? authError;

  Future<void> initialize() async {
    await offlineQueue.startNetworkWatcher();
    firebaseAuth.setPersistence(Persistence.LOCAL);
    firebaseAuth.authStateChanges().listen((_) => refreshUser());
    await refreshUser();
  }

  Future<void> refreshUser() async {
    loading = true;
    notifyListeners();
    currentUser = await auth.loadCurrentUser();
    if (currentUser != null && !auth.canAccess(currentUser!, currentPage)) {
      currentPage = defaultPageFor(currentUser!);
    }
    loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    authError = null;
    loading = true;
    notifyListeners();
    try {
      currentUser = await auth.login(email, password);
      currentPage = defaultPageFor(currentUser!);
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
    currentPage = 'dashboard';
    notifyListeners();
  }

  void go(String pageId) {
    final user = currentUser;
    if (user == null) return;
    if (!auth.canAccess(user, pageId)) {
      logout();
      return;
    }
    currentPage = pageId;
    notifyListeners();
  }

  String defaultPageFor(AppUser user) {
    return switch (user.role.key) {
      'staff_scanner' => 'scanner',
      _ => 'dashboard',
    };
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

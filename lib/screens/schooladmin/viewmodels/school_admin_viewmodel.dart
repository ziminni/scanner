import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/repositories/firebase_repository.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/app_controller.dart';
import '../../../core/services/attendance_service.dart';
import '../../../core/services/audit_service.dart';
import '../../../models/models.dart';
import 'base_viewmodel.dart';

/// The School Admin presentation boundary for page widgets and dialogs.
///
/// Keeping these dependencies here means School Admin views no longer reach
/// into the application scope directly. Existing feature-specific viewmodels
/// receive [app] from this facade as well, preserving their current behavior.
class SchoolAdminViewModel extends BaseViewModel {
  SchoolAdminViewModel(this._app);

  final AppController _app;

  AppController get app => _app;
  AppUser? get currentUser => _app.currentUser;
  FirebaseFirestore get firestore => _app.firestore;
  FirebaseRepository get repository => _app.repository;
  AttendanceService get attendance => _app.attendance;
  AdminService get admin => _app.admin;
  AuditService get audit => _app.audit;
}

class SchoolAdminViewModelScope
    extends InheritedNotifier<SchoolAdminViewModel> {
  const SchoolAdminViewModelScope({
    super.key,
    required SchoolAdminViewModel viewModel,
    required super.child,
  }) : super(notifier: viewModel);

  static SchoolAdminViewModel of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<SchoolAdminViewModelScope>();
    if (scope != null) return scope.notifier!;

    // Dialog routes are mounted above the page-level scope. They still share
    // the app controller, so create the same presentation facade on demand.
    return SchoolAdminViewModel(AppScope.of(context));
  }
}

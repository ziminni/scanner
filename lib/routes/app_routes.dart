import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/services/app_controller.dart';
import '../core/constants/enums.dart';
import '../models/models.dart';
import '../screens/auth/login_screen.dart';
import '../screens/scanner/scanner_screen.dart';
import '../screens/schooladmin/archive_management_page.dart';
import '../screens/schooladmin/attendance_logs_page.dart';
import '../screens/schooladmin/attendance_status_page.dart';
import '../screens/schooladmin/early_students_page.dart';
import '../screens/schooladmin/reports_export_page.dart';
import '../screens/schooladmin/scanner_users_page.dart';
import '../screens/schooladmin/school_admin_dashboard_page.dart';
import '../screens/schooladmin/school_year_page.dart';
import '../screens/schooladmin/sections_page.dart';
import '../screens/schooladmin/students_page.dart';
import '../screens/schooladmin/teachers_page.dart';
import '../screens/systemadmin/archive_management_page.dart';
import '../screens/systemadmin/audit_logs_page.dart';
import '../screens/systemadmin/database_management_page.dart';
import '../screens/systemadmin/system_admin_dashboard_page.dart';
import '../screens/systemadmin/system_settings_page.dart';
import '../screens/systemadmin/user_management_page.dart';
import '../shared/layouts/app_shell.dart';

class AppRoutes {
  const AppRoutes._();

  static const loading = 'loading';
  static const login = 'login';
  static const dashboard = 'dashboard';
  static const users = 'users';
  static const audit = 'audit';
  static const settings = 'settings';
  static const database = 'database';
  static const archives = 'archives';
  static const scannerUsers = 'scannerUsers';
  static const schoolYears = 'schoolYears';
  static const students = 'students';
  static const sections = 'sections';
  static const teachers = 'teachers';
  static const logs = 'logs';
  static const attendanceStatus = 'attendanceStatus';
  static const earlyStudents = 'earlyStudents';
  static const reports = 'reports';
  static const scanner = 'scanner';

  static const loadingPath = '/loading';
  static const loginPath = '/login';
  static const dashboardPath = '/dashboard';
  static const usersPath = '/users';
  static const auditPath = '/audit';
  static const settingsPath = '/settings';
  static const databasePath = '/database';
  static const archivesPath = '/archives';
  static const scannerUsersPath = '/scanner-users';
  static const schoolYearsPath = '/school-years';
  static const studentsPath = '/students';
  static const sectionsPath = '/sections';
  static const teachersPath = '/teachers';
  static const logsPath = '/attendance-logs';
  static const attendanceStatusPath = '/attendance-status';
  static const earlyStudentsPath = '/early-students';
  static const reportsPath = '/reports';
  static const scannerPath = '/scanner';

  static GoRouter router(AppController app) {
    return GoRouter(
      initialLocation: dashboardPath,
      refreshListenable: app,
      redirect: (context, state) {
        final location = state.matchedLocation;
        final isLoading = location == loadingPath;
        final isLogin = location == loginPath;

        if (app.loading) return isLoading ? null : loadingPath;

        final user = app.currentUser;
        if (user == null) return isLogin ? null : loginPath;

        if (isLogin || isLoading) return defaultPathFor(user);

        final pageId = pageIdFromPath(location);
        if (pageId == null) return defaultPathFor(user);
        if (!app.auth.canAccess(user, pageId)) {
          app.logoutForUnauthorizedAccess();
          return loginPath;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          redirect: (context, state) {
            final user = app.currentUser;
            return user == null ? loginPath : defaultPathFor(user);
          },
        ),
        GoRoute(
          path: loadingPath,
          name: loading,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(body: Center(child: CircularProgressIndicator())),
          ),
        ),
        GoRoute(
          path: loginPath,
          name: login,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: LoginScreen()),
        ),
        _shellRoute(
          path: dashboardPath,
          name: dashboard,
          pageId: dashboard,
          builder: (context) {
            final role = AppScope.of(context).currentUser!.role;
            return role == UserRole.systemAdministrator
                ? const SystemAdminDashboardPage()
                : const SchoolAdminDashboardPage();
          },
        ),
        _shellRoute(
          path: usersPath,
          name: users,
          pageId: users,
          builder: (_) => const UserManagementPage(),
        ),
        _shellRoute(
          path: auditPath,
          name: audit,
          pageId: audit,
          builder: (_) => const AuditLogsPage(),
        ),
        _shellRoute(
          path: settingsPath,
          name: settings,
          pageId: settings,
          builder: (_) => const SystemSettingsPage(),
        ),
        _shellRoute(
          path: databasePath,
          name: database,
          pageId: database,
          builder: (_) => const DatabaseManagementPage(),
        ),
        _shellRoute(
          path: archivesPath,
          name: archives,
          pageId: archives,
          builder: (context) {
            final role = AppScope.of(context).currentUser!.role;
            return role == UserRole.systemAdministrator
                ? const SystemArchiveManagementPage()
                : const SchoolArchiveManagementPage();
          },
        ),
        _shellRoute(
          path: scannerUsersPath,
          name: scannerUsers,
          pageId: scannerUsers,
          builder: (_) => const ScannerUsersPage(),
        ),
        _shellRoute(
          path: schoolYearsPath,
          name: schoolYears,
          pageId: schoolYears,
          builder: (_) => const SchoolYearPage(),
        ),
        _shellRoute(
          path: studentsPath,
          name: students,
          pageId: students,
          builder: (_) => const StudentsPage(),
        ),
        _shellRoute(
          path: sectionsPath,
          name: sections,
          pageId: sections,
          builder: (_) => const SectionsPage(),
        ),
        _shellRoute(
          path: teachersPath,
          name: teachers,
          pageId: teachers,
          builder: (_) => const TeachersPage(),
        ),
        _shellRoute(
          path: logsPath,
          name: logs,
          pageId: logs,
          builder: (_) => const AttendanceLogsPage(),
        ),
        _shellRoute(
          path: attendanceStatusPath,
          name: attendanceStatus,
          pageId: attendanceStatus,
          builder: (_) => const AttendanceStatusPage(),
        ),
        _shellRoute(
          path: earlyStudentsPath,
          name: earlyStudents,
          pageId: earlyStudents,
          builder: (_) => const EarlyStudentsPage(),
        ),
        _shellRoute(
          path: reportsPath,
          name: reports,
          pageId: reports,
          builder: (_) => const ReportsExportPage(),
        ),
        _shellRoute(
          path: scannerPath,
          name: scanner,
          pageId: scanner,
          builder: (_) => const ScannerScreen(),
        ),
      ],
    );
  }

  static GoRoute _shellRoute({
    required String path,
    required String name,
    required String pageId,
    required WidgetBuilder builder,
  }) {
    return GoRoute(
      path: path,
      name: name,
      pageBuilder: (context, state) => NoTransitionPage(
        child: AppShell(
          currentPage: pageId,
          child: _requiresActiveSchoolYear(pageId)
              ? ActiveSchoolYearGate(child: builder(context))
              : builder(context),
        ),
      ),
    );
  }

  static String defaultPathFor(AppUser user) {
    return pathForPage(defaultPageFor(user));
  }

  static String defaultPageFor(AppUser user) {
    return switch (user.role.key) {
      'staff_scanner' => scanner,
      _ => dashboard,
    };
  }

  static String pathForPage(String pageId) {
    return switch (pageId) {
      dashboard => dashboardPath,
      users => usersPath,
      audit => auditPath,
      settings => settingsPath,
      database => databasePath,
      archives => archivesPath,
      scannerUsers => scannerUsersPath,
      schoolYears => schoolYearsPath,
      students => studentsPath,
      sections => sectionsPath,
      teachers => teachersPath,
      logs => logsPath,
      attendanceStatus => attendanceStatusPath,
      earlyStudents => earlyStudentsPath,
      reports => reportsPath,
      scanner => scannerPath,
      _ => dashboardPath,
    };
  }

  static String? pageIdFromPath(String path) {
    return switch (path) {
      dashboardPath => dashboard,
      usersPath => users,
      auditPath => audit,
      settingsPath => settings,
      databasePath => database,
      archivesPath => archives,
      scannerUsersPath => scannerUsers,
      schoolYearsPath => schoolYears,
      studentsPath => students,
      sectionsPath => sections,
      teachersPath => teachers,
      logsPath => logs,
      attendanceStatusPath => attendanceStatus,
      earlyStudentsPath => earlyStudents,
      reportsPath => reports,
      scannerPath => scanner,
      _ => null,
    };
  }

  static bool _requiresActiveSchoolYear(String pageId) {
    return const {
      scannerUsers,
      students,
      sections,
      teachers,
      logs,
      attendanceStatus,
      earlyStudents,
      reports,
      scanner,
    }.contains(pageId);
  }
}

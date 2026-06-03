import 'package:flutter/material.dart';

import 'core/constants/enums.dart';
import 'core/constants/strings.dart';
import 'core/services/app_controller.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';

class AttendanceApp extends StatefulWidget {
  const AttendanceApp({super.key});

  @override
  State<AttendanceApp> createState() => _AttendanceAppState();
}

class _AttendanceAppState extends State<AttendanceApp> {
  AppController? _app;
  RouterConfig<Object>? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    if (_app == app) return;
    _app = app;
    _router = AppRoutes.router(app);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final user = app.currentUser;
    ThemeData theme = AppTheme.light();
    if (user != null) {
      if (user.role == UserRole.systemAdministrator ||
          user.role == UserRole.schoolAdministrator) {
        theme = AppTheme.admin(theme);
      }
    }

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: _router!,
    );
  }
}

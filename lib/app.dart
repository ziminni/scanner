import 'package:flutter/material.dart';

import 'core/constants/strings.dart';
import 'core/services/app_controller.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'shared/layouts/app_shell.dart';

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: AnimatedBuilder(
        animation: AppScope.of(context),
        builder: (context, _) {
          final app = AppScope.of(context);
          if (app.loading && app.currentUser == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return app.currentUser == null
              ? const LoginScreen()
              : const AppShell();
        },
      ),
    );
  }
}

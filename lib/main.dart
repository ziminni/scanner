import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/app_controller.dart';
import 'core/services/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final controller = AppController();
  await controller.initialize();
  runApp(AppScope(controller: controller, child: const AttendanceApp()));
}

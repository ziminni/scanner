import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/app_controller.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/admin.dart';

part 'widgets/audit_logs_list.dart';

class AuditLogsPage extends StatelessWidget {
  const AuditLogsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const AdminPage(title: 'Audit Logs', child: AuditLogsList(limit: 500));
}

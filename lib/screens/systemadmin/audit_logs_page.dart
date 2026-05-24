import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/admin_widgets.dart';

class AuditLogsPage extends StatelessWidget {
  const AuditLogsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const AdminPage(title: 'Audit Logs', child: AuditLogsList(limit: 100));
}

class AuditLogsList extends StatelessWidget {
  const AuditLogsList({super.key, required this.limit});

  final int limit;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: app.firestore
          .collection('audit_logs')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const EmptyState(title: 'No audit logs yet');
        return DataSurface(
          child: Column(
            children: [
              for (final doc in docs)
                ListTile(
                  leading: const Icon(Icons.fact_check_outlined),
                  title: Text(doc.data()['action'] as String? ?? 'Activity'),
                  subtitle: Text(
                    '${doc.data()['actorName'] as String? ?? 'Unknown'} ${doc.data()['target'] as String? ?? ''}',
                  ),
                  trailing: TimestampText(doc.data()['createdAt']),
                ),
            ],
          ),
        );
      },
    );
  }
}

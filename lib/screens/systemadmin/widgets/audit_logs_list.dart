part of '../audit_logs_page.dart';

class AuditLogsList extends StatelessWidget {
  const AuditLogsList({super.key, required this.limit});

  final int limit;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: app.repository.auditLogsStream(limit),
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

part of '../audit_logs_page.dart';

class AuditLogsList extends StatefulWidget {
  const AuditLogsList({super.key, required this.limit});

  final int limit;

  @override
  State<AuditLogsList> createState() => _AuditLogsListState();
}

class _AuditLogsListState extends State<AuditLogsList> {
  static const List<int> _itemsPerPageOptions = [10, 25, 50, 100];

  int _currentPage = 0;
  int _itemsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: app.repository.auditLogsStream(widget.limit),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const EmptyState(title: 'No audit logs yet');

        final totalPages = (docs.length / _itemsPerPage).ceil();
        final currentPage = totalPages == 0
            ? 0
            : _currentPage.clamp(0, totalPages - 1).toInt();
        final start = currentPage * _itemsPerPage;
        final end = (start + _itemsPerPage).clamp(0, docs.length).toInt();
        final paginatedDocs = docs.sublist(start, end);

        return DataSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final doc in paginatedDocs)
                ListTile(
                  leading: const Icon(Icons.fact_check_outlined),
                  title: Text(doc.data()['action'] as String? ?? 'Activity'),
                  subtitle: Text(
                    '${doc.data()['actorName'] as String? ?? 'Unknown'} ${doc.data()['target'] as String? ?? ''}',
                  ),
                  trailing: TimestampText(doc.data()['createdAt']),
                ),
              const SizedBox(height: 12),
              AdminTableFooter(
                currentPage: currentPage,
                totalItems: docs.length,
                itemsPerPage: _itemsPerPage,
                itemLabel: 'logs',
                itemsPerPageOptions: _itemsPerPageOptions,
                onItemsPerPageChanged: (value) {
                  setState(() {
                    _itemsPerPage = value;
                    _currentPage = 0;
                  });
                },
              ),
              if (totalPages > 1) ...[
                const SizedBox(height: 8),
                AdminPaginationControls(
                  currentPage: currentPage,
                  totalPages: totalPages,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

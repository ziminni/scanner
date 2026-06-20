import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import 'app_widgets.dart';
import 'archived_records_table.dart';

class ArchivedRecordsDialog extends StatelessWidget {
  const ArchivedRecordsDialog({
    super.key,
    required this.title,
    required this.collection,
    required this.columns,
    this.schoolYearScoped = false,
  });

  final String title;
  final String collection;
  final List<String> columns;
  final bool schoolYearScoped;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AlertDialog(
      title: Text(title),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width.clamp(320.0, 920.0).toDouble(),
        child: schoolYearScoped
            ? FutureBuilder(
                future: app.attendance.activeSchoolYear(),
                builder: (context, snapshot) {
                  final schoolYear = snapshot.data;
                  if (schoolYear == null) {
                    return const SizedBox(
                      height: 180,
                      child: EmptyState(
                        title: 'Create an active school year first',
                      ),
                    );
                  }
                  return ArchivedRecordsTable(
                    stream: app.repository
                        .schoolYearCollection(schoolYear.id, collection)
                        .where('archived', isEqualTo: true)
                        .snapshots(),
                    collection: collection,
                    columns: columns,
                    schoolYearId: schoolYear.id,
                    schoolYearName: schoolYear.name,
                  );
                },
              )
            : ArchivedRecordsTable(
                stream: app.repository
                    .rootCollection(collection)
                    .where('archived', isEqualTo: true)
                    .snapshots(),
                collection: collection,
                columns: columns,
                schoolYearId: null,
                schoolYearName: null,
              ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/app_controller.dart';
import '../../models/models.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(label, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, this.subtitle = ''});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(subtitle, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

class FirestoreCount extends StatelessWidget {
  const FirestoreCount({super.key, required this.query, required this.builder});

  final Query<Map<String, dynamic>> query;
  final Widget Function(String value) builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AggregateQuerySnapshot>(
      future: query.count().get(),
      builder: (context, snapshot) =>
          builder((snapshot.data?.count ?? 0).toString()),
    );
  }
}

class ActiveSchoolYearCount extends StatelessWidget {
  const ActiveSchoolYearCount({
    super.key,
    required this.collection,
    required this.builder,
    this.filters = const {},
  });

  final String collection;
  final Map<String, Object?> filters;
  final Widget Function(String value) builder;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return FutureBuilder<SchoolYear?>(
      future: app.attendance.activeSchoolYear(),
      builder: (context, snapshot) {
        final schoolYear = snapshot.data;
        if (schoolYear == null) return builder('0');
        Query<Map<String, dynamic>> query = app.firestore
            .collectionGroup(collection)
            .where('schoolYearId', isEqualTo: schoolYear.id);
        for (final entry in filters.entries) {
          query = query.where(entry.key, isEqualTo: entry.value);
        }
        return FirestoreCount(query: query, builder: builder);
      },
    );
  }
}

class TimestampText extends StatelessWidget {
  const TimestampText(this.value, {super.key});

  final Object? value;

  @override
  Widget build(BuildContext context) {
    DateTime? date;
    if (value is Timestamp) date = (value as Timestamp).toDate();
    if (value is DateTime) date = value as DateTime;
    if (date == null) return const Text('-');
    return Text(DateFormat('MMM d, yyyy hh:mm a').format(date));
  }
}

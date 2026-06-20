import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/app_controller.dart';
import '../../core/constants/colors.dart';
import '../../models/models.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = color ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: activeColor.withAlpha(28),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: activeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(204),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
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
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                ),
              ),
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
        Query<Map<String, dynamic>> query = app.repository
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

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.type});

  final String label;
  final String? type; // 'active','late','disabled'

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    switch (type) {
      case 'late':
        bg = AppColors.warn.withAlpha(38);
        text = AppColors.warn;
        break;
      case 'disabled':
        bg = Colors.grey.withAlpha(31);
        text = Colors.grey.shade800;
        break;
      default:
        bg = AppColors.success.withAlpha(31);
        text = AppColors.success;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/colors.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.soft = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: soft ? AppColors.adminSurface : AppColors.adminSurface,
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: soft ? AppColors.adminPrimary.withValues(alpha: 0.6) : AppColors.adminPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: soft ? AppColors.adminAccent : AppColors.adminAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: soft ? AppColors.adminText : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: soft
                        ? AppColors.adminText.withValues(alpha: 0.68)
                        : null,
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

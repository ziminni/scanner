part of '../early_students_page.dart';

class _LeaderboardSummary extends StatelessWidget {
  const _LeaderboardSummary({required this.viewModel});

  final EarlyStudentsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return DataSurface(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _Metric(label: 'Period', value: viewModel.periodLabel),
            _Metric(
              label: 'Students ranked',
              value: '${viewModel.entries.length}',
            ),
            _Metric(
              label: 'Top student',
              value: viewModel.entries.isEmpty
                  ? '-'
                  : viewModel.entries.first.fullName,
            ),
          ],
        ),
      ),
    );
  }
}

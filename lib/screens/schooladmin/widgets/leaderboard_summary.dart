part of '../early_students_page.dart';

class _LeaderboardSummary extends StatelessWidget {
  const _LeaderboardSummary({required this.viewModel});

  final EarlyStudentsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final roleLabel = viewModel.selectedRole.label.toLowerCase();
    return DataSurface(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _Metric(label: 'Period', value: viewModel.periodLabel),
            _Metric(
              label: '${viewModel.selectedRole.label}s ranked',
              value: '${viewModel.entries.length}',
            ),
            _Metric(
              label: 'Top $roleLabel',
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

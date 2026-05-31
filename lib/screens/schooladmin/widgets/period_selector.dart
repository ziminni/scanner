part of '../early_students_page.dart';

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});

  final EarlyLeaderboardPeriod selected;
  final ValueChanged<EarlyLeaderboardPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<EarlyLeaderboardPeriod>(
      segments: [
        for (final period in EarlyLeaderboardPeriod.values)
          ButtonSegment(value: period, label: Text(period.label)),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

part of '../early_students_page.dart';

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.selected, required this.onChanged});

  final PersonRole selected;
  final ValueChanged<PersonRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<PersonRole>(
      segments: const [
        ButtonSegment(value: PersonRole.student, label: Text('Students')),
        ButtonSegment(value: PersonRole.teacher, label: Text('Teachers')),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

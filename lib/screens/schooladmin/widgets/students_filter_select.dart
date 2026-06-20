part of '../students_page.dart';

class _FilterSelect extends StatelessWidget {
  const _FilterSelect({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.isEmpty || options.contains(value) ? value : '';
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        initialValue: displayValue,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          const DropdownMenuItem(
            value: '',
            child: Text('All', overflow: TextOverflow.ellipsis),
          ),
          for (final option in options)
            DropdownMenuItem(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (next) => onChanged(next ?? ''),
      ),
    );
  }
}

void _openEditStudentDialog(
  BuildContext context,
  String docId,
  Map<String, dynamic> data,
  String? schoolYearId,
) {
  if (schoolYearId == null) return;
  showDialog<void>(
    context: context,
    builder: (_) => _EditStudentDialog(
      schoolYearId: schoolYearId,
      docId: docId,
      data: data,
    ),
  );
}

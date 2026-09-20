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
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final displayValue = options.containsKey(value)
        ? value
        : options.keys.first;
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        initialValue: displayValue,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final option in options.entries)
            DropdownMenuItem(
              value: option.key,
              child: Text(option.value, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (next) => onChanged(next ?? ''),
      ),
    );
  }
}

class _SectionFilterSelect extends StatelessWidget {
  const _SectionFilterSelect({
    required this.value,
    required this.sections,
    required this.onChanged,
  });

  final String value;
  final List<String> sections;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.isEmpty || sections.contains(value) ? value : '';
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        initialValue: displayValue,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Section'),
        items: [
          const DropdownMenuItem(
            value: '',
            child: Text('All', overflow: TextOverflow.ellipsis),
          ),
          for (final section in sections)
            DropdownMenuItem(
              value: section,
              child: Text(section, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (next) => onChanged(next ?? ''),
      ),
    );
  }
}

extension on int {
  int nonZeroOr(int fallback) => this == 0 ? fallback : this;
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

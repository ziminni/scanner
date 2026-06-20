part of '../students_page.dart';

class _StudentsFilterBar extends StatelessWidget {
  const _StudentsFilterBar({
    required this.search,
    required this.sectionFilter,
    required this.genderFilter,
    required this.sections,
    required this.onSearchChanged,
    required this.onSectionChanged,
    required this.onGenderChanged,
  });

  final TextEditingController search;
  final String sectionFilter;
  final String genderFilter;
  final List<String> sections;
  final VoidCallback onSearchChanged;
  final ValueChanged<String> onSectionChanged;
  final ValueChanged<String> onGenderChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final searchWidth = compact
            ? constraints.maxWidth
            : (constraints.maxWidth - 372).clamp(320.0, 720.0).toDouble();
        return SizedBox(
          width: constraints.maxWidth,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: searchWidth,
                child: TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Search student name, LRN, section',
                  ),
                  onChanged: (_) => onSearchChanged(),
                ),
              ),
              _FilterSelect(
                label: 'Section',
                value: sectionFilter,
                options: sections,
                onChanged: onSectionChanged,
              ),
              SizedBox(
                width: 180,
                child: GenderDropdownField(
                  value: genderFilter,
                  includeAll: true,
                  onChanged: (value) => onGenderChanged(value ?? ''),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

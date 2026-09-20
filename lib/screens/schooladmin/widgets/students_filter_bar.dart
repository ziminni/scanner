part of '../students_page.dart';

class _StudentsFilterBar extends StatelessWidget {
  const _StudentsFilterBar({
    required this.search,
    required this.sortFilter,
    required this.sectionFilter,
    required this.sections,
    required this.onSearchChanged,
    required this.onSortFilterChanged,
    required this.onSectionChanged,
  });

  final TextEditingController search;
  final String sortFilter;
  final String sectionFilter;
  final List<String> sections;
  final VoidCallback onSearchChanged;
  final ValueChanged<String> onSortFilterChanged;
  final ValueChanged<String> onSectionChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final showSectionFilter = sortFilter == 'section';
        final showClearSort = sortFilter != 'lastNameAsc';
        final searchField = TextField(
          controller: search,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Search student name, LRN, section',
          ),
          onChanged: (_) => onSearchChanged(),
        );
        final sortFilterSelect = _FilterSelect(
          label: 'Sort / Filter',
          value: sortFilter,
          options: const {
            'lastNameAsc': 'Last name A-Z',
            'lastNameDesc': 'Last name Z-A',
            'firstNameAsc': 'First name A-Z',
            'birthdateOldest': 'Birthdate oldest',
            'birthdateNewest': 'Birthdate newest',
            'section': 'Section',
            'genderMale': 'Gender: Male',
            'genderFemale': 'Gender: Female',
            'blankFields': 'With blank fields',
          },
          onChanged: onSortFilterChanged,
        );
        final clearSortButton = Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => onSortFilterChanged('lastNameAsc'),
            child: const Text('Clear'),
          ),
        );
        final sectionFilterSelect = _SectionFilterSelect(
          value: sectionFilter,
          sections: sections,
          onChanged: onSectionChanged,
        );

        if (!compact) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  sortFilterSelect,
                  if (showClearSort) clearSortButton,
                ],
              ),
              if (showSectionFilter) ...[
                const SizedBox(width: 12),
                sectionFilterSelect,
              ],
            ],
          );
        }

        return SizedBox(
          width: constraints.maxWidth,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(width: constraints.maxWidth, child: searchField),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  sortFilterSelect,
                  if (showClearSort) clearSortButton,
                ],
              ),
              if (showSectionFilter) sectionFilterSelect,
            ],
          ),
        );
      },
    );
  }
}

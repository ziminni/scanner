part of '../students_page.dart';

class _EditStudentDialog extends StatefulWidget {
  const _EditStudentDialog({
    required this.schoolYearId,
    required this.docId,
    required this.data,
  });

  final String schoolYearId;
  final String docId;
  final Map<String, dynamic> data;

  @override
  State<_EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends State<_EditStudentDialog> {
  late final Map<String, TextEditingController> _controllers;
  DateTime? _birthdate;
  String? _selectedSection;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in studentFields)
        if (field != 'birthdate' && field != 'section' && field != 'status')
          field: TextEditingController(
            text: widget.data[field]?.toString() ?? '',
          ),
    };
    _birthdate = _dateFromValue(widget.data['birthdate']);
    _selectedSection = widget.data['section'] as String?;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AlertDialog(
      title: const Text('Edit student'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: app.repository.activeSectionsStream(),
            builder: (context, snapshot) {
              final sectionNames =
                  (snapshot.data?.docs ?? [])
                      .map((doc) => doc.data()['name'] as String? ?? '')
                      .where((name) => name.trim().isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();

              if (_selectedSection != null &&
                  !sectionNames.contains(_selectedSection)) {
                _selectedSection = null;
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final entry in _controllers.entries)
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: entry.value,
                        decoration: InputDecoration(
                          labelText: adminLabel(entry.key),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 220,
                    child: BirthdateField(
                      value: _birthdate,
                      onChanged: (date) => setState(() => _birthdate = date),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSection,
                      decoration: const InputDecoration(labelText: 'Section'),
                      hint: const Text('Select section'),
                      items: [
                        for (final section in sectionNames)
                          DropdownMenuItem(
                            value: section,
                            child: Text(section),
                          ),
                      ],
                      onChanged: sectionNames.isEmpty || _saving
                          ? null
                          : (section) =>
                                setState(() => _selectedSection = section),
                    ),
                  ),
                  if (_error != null)
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Save'),
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }

  Future<void> _save() async {
    final section = _selectedSection;
    if (section == null) {
      setState(() => _error = 'Section is required.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final app = AppScope.of(context);
    try {
      await app.repository
          .schoolYearCollection(widget.schoolYearId, 'students')
          .doc(widget.docId)
          .set({
            for (final entry in _controllers.entries)
              entry.key: entry.value.text.trim(),
            'birthdate': _birthdate == null
                ? null
                : Timestamp.fromDate(_birthdate!),
            'section': section,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      await app.audit.record(
        action: 'students_updated',
        actorId: app.currentUser!.id,
        actorName: app.currentUser!.fullName,
        target: _controllers['lrn']?.text.trim() ?? widget.docId,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  DateTime? _dateFromValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

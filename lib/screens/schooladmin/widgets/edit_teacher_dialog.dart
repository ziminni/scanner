part of '../teachers_page.dart';

class _EditTeacherDialog extends StatefulWidget {
  const _EditTeacherDialog({
    required this.schoolYearId,
    required this.docId,
    required this.data,
  });

  final String schoolYearId;
  final String docId;
  final Map<String, dynamic> data;

  @override
  State<_EditTeacherDialog> createState() => _EditTeacherDialogState();
}

class _EditTeacherDialogState extends State<_EditTeacherDialog> {
  late final Map<String, TextEditingController> _controllers;
  DateTime? _birthdate;
  TimeOfDay? _assignedTimeIn;
  TimeOfDay? _assignedTimeOut;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in [
        'teacherId',
        'lastName',
        'firstName',
        'middleName',
        'address',
        'contactNumber',
      ])
        field: TextEditingController(text: widget.data[field] as String? ?? ''),
    };
    _birthdate = _dateFromValue(widget.data['birthdate']);
    _assignedTimeIn = _timeFromValue(widget.data['assignedTimeIn']);
    _assignedTimeOut = _timeFromValue(widget.data['assignedTimeOut']);
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
    return AlertDialog(
      title: const Text('Edit teacher'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Wrap(
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
                child: TimePickerField(
                  label: 'Assigned Time In',
                  value: _assignedTimeIn,
                  fallback: const TimeOfDay(hour: 7, minute: 0),
                  onChanged: (time) => setState(() => _assignedTimeIn = time),
                ),
              ),
              SizedBox(
                width: 220,
                child: TimePickerField(
                  label: 'Assigned Time Out',
                  value: _assignedTimeOut,
                  fallback: const TimeOfDay(hour: 17, minute: 0),
                  onChanged: (time) => setState(() => _assignedTimeOut = time),
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
    setState(() {
      _saving = true;
      _error = null;
    });

    final app = AppScope.of(context);
    try {
      await app.repository
          .schoolYearCollection(widget.schoolYearId, 'teachers')
          .doc(widget.docId)
          .set({
            for (final entry in _controllers.entries)
              entry.key: entry.value.text.trim(),
            'birthdate': _birthdate == null
                ? null
                : Timestamp.fromDate(_birthdate!),
            'assignedTimeIn': _timeToStorage(
              _assignedTimeIn ?? const TimeOfDay(hour: 7, minute: 0),
            ),
            'assignedTimeOut': _timeToStorage(
              _assignedTimeOut ?? const TimeOfDay(hour: 17, minute: 0),
            ),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      await app.audit.record(
        action: 'teachers_updated',
        actorId: app.currentUser!.id,
        actorName: app.currentUser!.fullName,
        target: _controllers['teacherId']?.text.trim() ?? widget.docId,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString();
        });
      }
    }
  }

  DateTime? _dateFromValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  TimeOfDay? _timeFromValue(Object? value) {
    if (value is! String || !value.contains(':')) return null;
    final parts = value.split(':');
    final hour = int.tryParse(parts.first);
    final minute = int.tryParse(parts.elementAtOrNull(1) ?? '');
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _timeToStorage(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

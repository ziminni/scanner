part of '../sections_page.dart';

class _EditSectionDialog extends StatefulWidget {
  const _EditSectionDialog({required this.docId, required this.data});

  final String docId;
  final Map<String, dynamic> data;

  @override
  State<_EditSectionDialog> createState() => _EditSectionDialogState();
}

class _EditSectionDialogState extends State<_EditSectionDialog> {
  late final TextEditingController _name;
  late final TextEditingController _gradeLevel;
  TeacherOption? _selectedAdviser;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.data['name'] as String? ?? '');
    _gradeLevel = TextEditingController(
      text: widget.data['gradeLevel'] as String? ?? '',
    );
    final adviserDocId = widget.data['adviserDocId'] as String? ?? '';
    if (adviserDocId.isNotEmpty) {
      _selectedAdviser = TeacherOption(
        docId: adviserDocId,
        teacherId: widget.data['adviserTeacherId'] as String? ?? '',
        name: widget.data['adviser'] as String? ?? '',
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _gradeLevel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit section'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Section Name'),
                ),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _gradeLevel,
                  decoration: const InputDecoration(labelText: 'Grade Level'),
                ),
              ),
              SizedBox(
                width: 220,
                child: _AdviserDropdown(
                  selected: _selectedAdviser,
                  onChanged: (teacher) =>
                      setState(() => _selectedAdviser = teacher),
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
    final app = AppScope.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Section name is required.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await app.repository.rootCollection('sections').doc(widget.docId).set({
        'name': name,
        'gradeLevel': _gradeLevel.text.trim(),
        'adviser': _selectedAdviser?.name ?? '',
        'adviserTeacherId': _selectedAdviser?.teacherId ?? '',
        'adviserDocId': _selectedAdviser?.docId ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await app.audit.record(
        action: 'sections_updated',
        actorId: app.currentUser!.id,
        actorName: app.currentUser!.fullName,
        target: name,
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
}

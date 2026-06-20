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
  bool _deleting = false;
  String? _error;

  bool get _busy => _saving || _deleting;

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
    final theme = Theme.of(context);
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.groups_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Edit section',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Update the section details and adviser assignment.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _name,
                enabled: !_busy,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Section name',
                  prefixIcon: Icon(Icons.class_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _gradeLevel,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Grade level',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
              const SizedBox(height: 14),
              _AdviserDropdown(
                selected: _selectedAdviser,
                onChanged: _busy
                    ? (_) {}
                    : (teacher) => setState(() => _selectedAdviser = teacher),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withAlpha(70),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.error.withAlpha(60),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Deleting a section permanently removes the section record and unassigns active students currently listed under it.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          onPressed: _busy ? null : _confirmDelete,
          icon: _deleting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.error,
                  ),
                )
              : const Icon(Icons.delete_outline),
          label: Text(_deleting ? 'Deleting' : 'Delete'),
        ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
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
          onPressed: _busy ? null : _save,
        ),
      ],
    );
  }

  Future<void> _save() async {
    final app = SchoolAdminViewModelScope.of(context);
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

  Future<void> _confirmDelete() async {
    final name = _name.text.trim().isEmpty
        ? (widget.data['name'] as String? ?? 'this section')
        : _name.text.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete section?'),
        content: Text(
          'This will permanently delete $name and unassign active students currently in this section. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete section'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _deleteSection(name);
  }

  Future<void> _deleteSection(String sectionName) async {
    final app = SchoolAdminViewModelScope.of(context);
    setState(() {
      _deleting = true;
      _error = null;
    });

    try {
      final schoolYear = await app.attendance.activeSchoolYear();
      var unassignedCount = 0;
      if (schoolYear != null && sectionName.trim().isNotEmpty) {
        final students = await app.repository
            .schoolYearCollection(schoolYear.id, 'students')
            .where('section', isEqualTo: sectionName)
            .where('archived', isEqualTo: false)
            .get();

        var batch = app.firestore.batch();
        var writes = 0;
        for (final student in students.docs) {
          batch.set(student.reference, {
            'section': '',
            'previousSection': sectionName,
            'sectionUnassignedAt': FieldValue.serverTimestamp(),
            'sectionUnassignedReason': 'section_deleted',
          }, SetOptions(merge: true));
          writes++;
          unassignedCount++;
          if (writes == 450) {
            await batch.commit();
            batch = app.firestore.batch();
            writes = 0;
          }
        }
        if (writes > 0) await batch.commit();
      }

      await app.repository
          .rootCollection('sections')
          .doc(widget.docId)
          .delete();
      await app.audit.record(
        action: 'sections_deleted',
        actorId: app.currentUser!.id,
        actorName: app.currentUser!.fullName,
        target: sectionName,
        metadata: {'studentsUnassigned': unassignedCount},
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            unassignedCount == 0
                ? '$sectionName deleted.'
                : '$sectionName deleted. $unassignedCount students were unassigned.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _error = error.toString();
      });
    }
  }
}

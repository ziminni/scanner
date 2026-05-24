import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/services/app_controller.dart';
import '../models/models.dart';
import 'base_viewmodel.dart';

class SchoolYearViewModel extends BaseViewModel {
  SchoolYearViewModel(this._app);

  final AppController _app;

  Future<SchoolYear?> activeSchoolYear() => _app.attendance.activeSchoolYear();

  Future<void> archiveActive(SchoolYear schoolYear) async {
    setBusy(true);
    try {
      await _app.attendance.archiveSchoolYear(
        schoolYear,
        actorId: _app.currentUser!.id,
        actorName: _app.currentUser!.fullName,
      );
    } finally {
      setBusy(false);
    }
  }
}

class CreateSchoolYearViewModel extends BaseViewModel {
  CreateSchoolYearViewModel(this._app);

  final AppController _app;
  final yearStart = TextEditingController();
  final yearEnd = TextEditingController();
  final termStarts = List<DateTime?>.filled(3, null);
  final termEnds = List<DateTime?>.filled(3, null);

  @override
  void dispose() {
    yearStart.dispose();
    yearEnd.dispose();
    super.dispose();
  }

  void setTermStart(int index, DateTime date) {
    termStarts[index] = date;
    notifyListeners();
  }

  void setTermEnd(int index, DateTime date) {
    termEnds[index] = date;
    notifyListeners();
  }

  Future<bool> create() async {
    final start = int.tryParse(yearStart.text.trim());
    final end = int.tryParse(yearEnd.text.trim());
    if (start == null || end == null || end != start + 1) {
      setError('Enter a valid school year, for example 2026 - 2027.');
      return false;
    }
    if (termStarts.any((date) => date == null) ||
        termEnds.any((date) => date == null)) {
      setError('All three term start and end dates are required.');
      return false;
    }
    for (var index = 0; index < 3; index++) {
      if (termEnds[index]!.isBefore(termStarts[index]!)) {
        setError('Term ${index + 1} end date cannot be before its start date.');
        return false;
      }
      if (index > 0 && !termStarts[index]!.isAfter(termEnds[index - 1]!)) {
        setError('Term ${index + 1} must start after Term $index ends.');
        return false;
      }
    }

    setBusy(true);
    try {
      final active = await _app.attendance.activeSchoolYear();
      if (active != null) {
        setError('Archive the active school year before creating another one.');
        return false;
      }

      final name = '$start-$end';
      await _app.firestore.collection('school_years').add({
        'name': name,
        'isActive': true,
        'archived': false,
        'term1Start': Timestamp.fromDate(termStarts[0]!),
        'term1End': Timestamp.fromDate(termEnds[0]!),
        'term2Start': Timestamp.fromDate(termStarts[1]!),
        'term2End': Timestamp.fromDate(termEnds[1]!),
        'term3Start': Timestamp.fromDate(termStarts[2]!),
        'term3End': Timestamp.fromDate(termEnds[2]!),
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _app.audit.record(
        action: 'school_year_created',
        actorId: _app.currentUser!.id,
        actorName: _app.currentUser!.fullName,
        target: name,
      );
      _app.attendance.clearActiveSchoolYearCache();
      await _app.attendance.activeSchoolYear(forceRefresh: true);
      setError(null);
      return true;
    } finally {
      setBusy(false);
    }
  }
}

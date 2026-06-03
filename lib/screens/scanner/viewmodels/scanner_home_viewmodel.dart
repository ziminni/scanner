import 'package:intl/intl.dart';

import '../../../core/constants/enums.dart';
import '../../../core/services/app_controller.dart';
import '../../../models/models.dart';
import 'base_viewmodel.dart';

class ScannerHomeLeaderboardEntry {
  const ScannerHomeLeaderboardEntry({
    required this.rank,
    required this.name,
    required this.timeIn,
    required this.points,
  });

  final int rank;
  final String name;
  final String timeIn;
  final int points;
}

class ScannerHomeViewModel extends BaseViewModel {
  ScannerHomeViewModel(this._app);

  final AppController _app;

  List<ScannerHomeLeaderboardEntry> students = [];
  List<ScannerHomeLeaderboardEntry> teachers = [];

  Future<void> load() async {
    setBusy(true);
    setError(null);
    try {
      final schoolYear = await _app.attendance.activeSchoolYear();
      if (schoolYear == null) {
        students = [];
        teachers = [];
        setError('Create an active school year first.');
        return;
      }

      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final snapshot = await _app.repository.attendanceLogsForDate(
        schoolYearId: schoolYear.id,
        dateKey: todayKey,
      );
      final logs = snapshot.docs.map(AttendanceLog.fromDoc).toList();
      students = _buildEntries(logs, PersonRole.student);
      teachers = _buildEntries(logs, PersonRole.teacher);
      notifyListeners();
    } catch (error) {
      setError(error.toString());
    } finally {
      setBusy(false);
    }
  }

  List<ScannerHomeLeaderboardEntry> _buildEntries(
    List<AttendanceLog> logs,
    PersonRole role,
  ) {
    final earliestByPerson = <String, AttendanceLog>{};

    for (final log in logs) {
      if (log.personRole != role) continue;
      if (!log.attendanceType.isTimeIn) continue;
      if (log.attendanceStatus == AttendanceStatus.duplicate) continue;

      final existing = earliestByPerson[log.personId];
      if (existing == null || log.timestamp.isBefore(existing.timestamp)) {
        earliestByPerson[log.personId] = log;
      }
    }

    final ranked = earliestByPerson.values.toList()
      ..sort((a, b) {
        final timeCompare = a.timestamp.compareTo(b.timestamp);
        if (timeCompare != 0) return timeCompare;
        return a.fullName.compareTo(b.fullName);
      });

    return [
      for (var index = 0; index < ranked.length && index < 10; index++)
        ScannerHomeLeaderboardEntry(
          rank: index + 1,
          name: ranked[index].fullName,
          timeIn: DateFormat('hh:mm a').format(ranked[index].timestamp),
          points: _pointsForRank(index + 1),
        ),
    ];
  }

  int _pointsForRank(int rank) {
    if (rank <= 5) return 11 - rank;
    if (rank <= 10) return 5;
    return 0;
  }
}

import 'package:intl/intl.dart';

import '../../../core/services/app_controller.dart';
import '../../../core/constants/enums.dart';
import '../../../models/models.dart';
import 'base_viewmodel.dart';

enum AttendanceStatusFilter {
  all,
  late,
  absent,
  incomplete;

  String get label => switch (this) {
    AttendanceStatusFilter.all => 'All',
    AttendanceStatusFilter.late => 'Late',
    AttendanceStatusFilter.absent => 'Absent',
    AttendanceStatusFilter.incomplete => 'Incomplete',
  };
}

class AttendanceStatusEntry {
  const AttendanceStatusEntry({
    required this.personId,
    required this.fullName,
    required this.role,
    required this.section,
    required this.status,
    required this.detail,
    this.timeIn = '-',
    this.timeOut = '-',
  });

  final String personId;
  final String fullName;
  final PersonRole role;
  final String section;
  final AttendanceStatus status;
  final String detail;
  final String timeIn;
  final String timeOut;
}

class AttendanceStatusViewModel extends BaseViewModel {
  AttendanceStatusViewModel(this._app);

  final AppController _app;

  DateTime selectedDate = _dateOnly(DateTime.now());
  AttendanceStatusFilter filter = AttendanceStatusFilter.all;
  String search = '';
  List<AttendanceStatusEntry> _entries = [];

  int get lateCount =>
      _entries.where((entry) => entry.status == AttendanceStatus.late).length;

  int get absentCount =>
      _entries.where((entry) => entry.status == AttendanceStatus.absent).length;

  int get incompleteCount => _entries
      .where((entry) => entry.status == AttendanceStatus.incomplete)
      .length;

  List<AttendanceStatusEntry> get entries {
    final query = search.trim().toLowerCase();
    return _entries.where((entry) {
      final matchesFilter = switch (filter) {
        AttendanceStatusFilter.all => true,
        AttendanceStatusFilter.late => entry.status == AttendanceStatus.late,
        AttendanceStatusFilter.absent =>
          entry.status == AttendanceStatus.absent,
        AttendanceStatusFilter.incomplete =>
          entry.status == AttendanceStatus.incomplete,
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return '${entry.personId} ${entry.fullName} ${entry.section} ${entry.role.label}'
          .toLowerCase()
          .contains(query);
    }).toList();
  }

  String get selectedDateLabel =>
      DateFormat('MMM d, yyyy').format(selectedDate);

  Future<void> load() async {
    setBusy(true);
    setError(null);
    try {
      final schoolYear = await _app.attendance.activeSchoolYear();
      if (schoolYear == null) {
        _entries = [];
        setError(
          'Create an active school year before viewing attendance status.',
        );
        return;
      }

      final studentsQuery = await _app.repository.activeStudents(schoolYear.id);
      final teachersQuery = await _app.repository.activeTeachers(schoolYear.id);
      final logsQuery = await _app.repository.attendanceLogsForDate(
        schoolYearId: schoolYear.id,
        dateKey: DateFormat('yyyy-MM-dd').format(selectedDate),
      );

      final people = [
        for (final doc in studentsQuery.docs)
          _AttendancePerson.student(Student.fromDoc(doc)),
        for (final doc in teachersQuery.docs)
          _AttendancePerson.teacher(Teacher.fromDoc(doc)),
      ];
      final logs = logsQuery.docs
          .map(AttendanceLog.fromDoc)
          .where((log) => log.attendanceStatus != AttendanceStatus.duplicate)
          .toList();

      _entries = _buildEntries(people, logs);
      notifyListeners();
    } catch (error) {
      setError(error.toString());
    } finally {
      setBusy(false);
    }
  }

  Future<void> setDate(DateTime date) async {
    selectedDate = _dateOnly(date);
    notifyListeners();
    await load();
  }

  void setFilter(AttendanceStatusFilter nextFilter) {
    filter = nextFilter;
    notifyListeners();
  }

  void setSearch(String value) {
    search = value;
    notifyListeners();
  }

  List<AttendanceStatusEntry> _buildEntries(
    List<_AttendancePerson> people,
    List<AttendanceLog> logs,
  ) {
    final logsByPerson = <String, List<AttendanceLog>>{};
    for (final log in logs) {
      logsByPerson.putIfAbsent(log.personId, () => []).add(log);
    }

    final entries = <AttendanceStatusEntry>[];
    for (final person in people) {
      final personLogs = logsByPerson[person.personId] ?? [];
      final timeInLogs =
          personLogs.where((log) => log.attendanceType.isTimeIn).toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final timeOutLogs =
          personLogs.where((log) => log.attendanceType.isTimeOut).toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final firstTimeIn = timeInLogs.firstOrNull;
      final firstTimeOut = timeOutLogs.firstOrNull;

      if (firstTimeIn == null && firstTimeOut == null) {
        entries.add(
          AttendanceStatusEntry(
            personId: person.personId,
            fullName: person.fullName,
            role: person.role,
            section: person.section,
            status: AttendanceStatus.absent,
            detail: 'No Time In recorded',
          ),
        );
        continue;
      }

      if (firstTimeIn == null || firstTimeOut == null) {
        entries.add(
          AttendanceStatusEntry(
            personId: person.personId,
            fullName: person.fullName,
            role: person.role,
            section: person.section,
            status: AttendanceStatus.incomplete,
            detail: firstTimeIn == null
                ? 'Missing Time In'
                : 'Missing Time Out',
            timeIn: firstTimeIn?.timeText ?? '-',
            timeOut: firstTimeOut?.timeText ?? '-',
          ),
        );
      }

      if (firstTimeIn?.attendanceStatus == AttendanceStatus.late) {
        entries.add(
          AttendanceStatusEntry(
            personId: person.personId,
            fullName: person.fullName,
            role: person.role,
            section: person.section,
            status: AttendanceStatus.late,
            detail: 'Time In was recorded late',
            timeIn: firstTimeIn!.timeText,
            timeOut: firstTimeOut?.timeText ?? '-',
          ),
        );
      }
    }

    entries.sort((a, b) {
      final statusCompare = a.status.label.compareTo(b.status.label);
      if (statusCompare != 0) return statusCompare;
      return a.fullName.compareTo(b.fullName);
    });
    return entries;
  }
}

class _AttendancePerson {
  const _AttendancePerson({
    required this.personId,
    required this.fullName,
    required this.role,
    required this.section,
  });

  factory _AttendancePerson.student(Student student) => _AttendancePerson(
    personId: student.lrn,
    fullName: student.fullName,
    role: PersonRole.student,
    section: student.section,
  );

  factory _AttendancePerson.teacher(Teacher teacher) => _AttendancePerson(
    personId: teacher.teacherId,
    fullName: teacher.fullName,
    role: PersonRole.teacher,
    section: '',
  );

  final String personId;
  final String fullName;
  final PersonRole role;
  final String section;
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

import 'package:intl/intl.dart';

import '../../../core/services/app_controller.dart';
import '../../../core/constants/enums.dart';
import '../../../models/models.dart';
import 'base_viewmodel.dart';

enum EarlyLeaderboardPeriod {
  daily,
  weekly,
  monthly;

  String get label => switch (this) {
    EarlyLeaderboardPeriod.daily => 'Daily',
    EarlyLeaderboardPeriod.weekly => 'Weekly',
    EarlyLeaderboardPeriod.monthly => 'Monthly',
  };
}

class EarlyLeaderboardEntry {
  const EarlyLeaderboardEntry({
    required this.rank,
    required this.personId,
    required this.fullName,
    required this.section,
    required this.points,
    required this.bestDailyRank,
    required this.averageTimeInMinutes,
    required this.validDays,
    this.timeInText = '',
  });

  final int rank;
  final String personId;
  final String fullName;
  final String section;
  final int points;
  final int bestDailyRank;
  final double averageTimeInMinutes;
  final int validDays;
  final String timeInText;

  String get averageTimeInText {
    if (averageTimeInMinutes.isInfinite) return '-';
    final totalMinutes = averageTimeInMinutes.round();
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;
    final time = DateTime(2026, 1, 1, hour, minute);
    return DateFormat('hh:mm a').format(time);
  }
}

class EarlyStudentsViewModel extends BaseViewModel {
  EarlyStudentsViewModel(this._app);

  final AppController _app;

  DateTime selectedDate = _dateOnly(DateTime.now());
  EarlyLeaderboardPeriod period = EarlyLeaderboardPeriod.daily;
  SchoolYear? activeSchoolYear;
  String periodLabel = '';
  List<EarlyLeaderboardEntry> entries = [];

  Future<void> load() async {
    setBusy(true);
    setError(null);
    try {
      activeSchoolYear = await _app.attendance.activeSchoolYear();
      if (activeSchoolYear == null) {
        entries = [];
        periodLabel = '';
        setError('Create an active school year before viewing leaderboards.');
        return;
      }

      final range = _rangeFor(period, selectedDate, activeSchoolYear!);
      periodLabel = range.label;
      final logs = await _loadLogs(
        range.start,
        range.end,
        activeSchoolYear!.id,
      );
      final dailyRankings = _dailyRankings(logs);
      entries = period == EarlyLeaderboardPeriod.daily
          ? _dailyEntries(
              dailyRankings[DateFormat('yyyy-MM-dd').format(selectedDate)] ??
                  [],
            )
          : _aggregateEntries(dailyRankings);
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

  Future<void> setPeriod(EarlyLeaderboardPeriod nextPeriod) async {
    period = nextPeriod;
    notifyListeners();
    await load();
  }

  Future<List<AttendanceLog>> _loadLogs(
    DateTime start,
    DateTime end,
    String schoolYearId,
  ) async {
    final query = await _app.repository.attendanceLogsForRange(
      schoolYearId: schoolYearId,
      start: start,
      end: end,
    );
    return query.docs.map(AttendanceLog.fromDoc).toList();
  }

  Map<String, List<_DailyRank>> _dailyRankings(List<AttendanceLog> logs) {
    final earliestByDateAndStudent = <String, Map<String, AttendanceLog>>{};

    for (final log in logs) {
      if (log.personRole != PersonRole.student) continue;
      if (!log.attendanceType.isTimeIn) continue;
      if (log.attendanceStatus == AttendanceStatus.duplicate) continue;

      final dateLogs = earliestByDateAndStudent.putIfAbsent(
        log.dateKey,
        () => {},
      );
      final existing = dateLogs[log.personId];
      if (existing == null || log.timestamp.isBefore(existing.timestamp)) {
        dateLogs[log.personId] = log;
      }
    }

    return {
      for (final entry in earliestByDateAndStudent.entries)
        entry.key: _rankDaily(entry.value.values.toList()),
    };
  }

  List<_DailyRank> _rankDaily(List<AttendanceLog> logs) {
    logs.sort((a, b) {
      final timeCompare = a.timestamp.compareTo(b.timestamp);
      if (timeCompare != 0) return timeCompare;
      return a.fullName.compareTo(b.fullName);
    });

    return [
      for (var index = 0; index < logs.length; index++)
        _DailyRank(
          rank: index + 1,
          points: _pointsForRank(index + 1),
          log: logs[index],
        ),
    ];
  }

  List<EarlyLeaderboardEntry> _dailyEntries(List<_DailyRank> dailyRanks) {
    return [
      for (final rank in dailyRanks)
        EarlyLeaderboardEntry(
          rank: rank.rank,
          personId: rank.log.personId,
          fullName: rank.log.fullName,
          section: rank.log.section,
          points: rank.points,
          bestDailyRank: rank.rank,
          averageTimeInMinutes: _minutesSinceMidnight(rank.log.timestamp),
          validDays: 1,
          timeInText: DateFormat('hh:mm a').format(rank.log.timestamp),
        ),
    ];
  }

  List<EarlyLeaderboardEntry> _aggregateEntries(
    Map<String, List<_DailyRank>> dailyRankings,
  ) {
    final totals = <String, _StudentTotal>{};

    for (final ranks in dailyRankings.values) {
      for (final rank in ranks) {
        final total = totals.putIfAbsent(
          rank.log.personId,
          () => _StudentTotal(rank.log),
        );
        total.points += rank.points;
        total.bestDailyRank = total.bestDailyRank < rank.rank
            ? total.bestDailyRank
            : rank.rank;
        total.validDays += 1;
        total.timeInMinutes += _minutesSinceMidnight(rank.log.timestamp);
      }
    }

    final sorted = totals.values.toList()
      ..sort((a, b) {
        final pointsCompare = b.points.compareTo(a.points);
        if (pointsCompare != 0) return pointsCompare;
        final rankCompare = a.bestDailyRank.compareTo(b.bestDailyRank);
        if (rankCompare != 0) return rankCompare;
        final averageCompare = a.averageTimeInMinutes.compareTo(
          b.averageTimeInMinutes,
        );
        if (averageCompare != 0) return averageCompare;
        return a.fullName.compareTo(b.fullName);
      });

    return [
      for (var index = 0; index < sorted.length; index++)
        EarlyLeaderboardEntry(
          rank: index + 1,
          personId: sorted[index].personId,
          fullName: sorted[index].fullName,
          section: sorted[index].section,
          points: sorted[index].points,
          bestDailyRank: sorted[index].bestDailyRank,
          averageTimeInMinutes: sorted[index].averageTimeInMinutes,
          validDays: sorted[index].validDays,
        ),
    ];
  }

  int _pointsForRank(int rank) {
    if (rank <= 5) return 11 - rank;
    if (rank <= 10) return 5;
    return 0;
  }

  double _minutesSinceMidnight(DateTime date) {
    return (date.hour * 60 + date.minute).toDouble();
  }

  _DateRange _rangeFor(
    EarlyLeaderboardPeriod period,
    DateTime date,
    SchoolYear schoolYear,
  ) {
    final selected = _dateOnly(date);
    return switch (period) {
      EarlyLeaderboardPeriod.daily => _DateRange(
        start: selected,
        end: selected.add(const Duration(days: 1)),
        label: DateFormat('MMM d, yyyy').format(selected),
      ),
      EarlyLeaderboardPeriod.weekly => _weeklyRange(selected),
      EarlyLeaderboardPeriod.monthly => _monthlyRange(selected),
    };
  }

  _DateRange _weeklyRange(DateTime selected) {
    final start = selected.subtract(Duration(days: selected.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return _DateRange(
      start: start,
      end: end,
      label:
          '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, yyyy').format(end.subtract(const Duration(days: 1)))}',
    );
  }

  _DateRange _monthlyRange(DateTime selected) {
    final start = DateTime(selected.year, selected.month);
    final end = DateTime(selected.year, selected.month + 1);
    return _DateRange(
      start: start,
      end: end,
      label: DateFormat('MMMM yyyy').format(selected),
    );
  }
}

class _DailyRank {
  const _DailyRank({
    required this.rank,
    required this.points,
    required this.log,
  });

  final int rank;
  final int points;
  final AttendanceLog log;
}

class _StudentTotal {
  _StudentTotal(AttendanceLog log)
    : personId = log.personId,
      fullName = log.fullName,
      section = log.section;

  final String personId;
  final String fullName;
  final String section;
  int points = 0;
  int bestDailyRank = 999999;
  int validDays = 0;
  double timeInMinutes = 0;

  double get averageTimeInMinutes {
    if (validDays == 0) return double.infinity;
    return timeInMinutes / validDays;
  }
}

class _DateRange {
  const _DateRange({
    required this.start,
    required this.end,
    required this.label,
  });

  final DateTime start;
  final DateTime end;
  final String label;
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

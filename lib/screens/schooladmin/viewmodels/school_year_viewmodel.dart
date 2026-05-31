import '../../../core/services/app_controller.dart';
import '../../../models/models.dart';
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

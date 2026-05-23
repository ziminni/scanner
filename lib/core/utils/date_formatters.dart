import 'package:intl/intl.dart';

class DateFormatters {
  const DateFormatters._();

  static final date = DateFormat('yyyy-MM-dd');
  static final time = DateFormat('hh:mm a');
  static final dateTime = DateFormat('MMM d, yyyy hh:mm a');
}

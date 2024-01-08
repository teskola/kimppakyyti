import 'dart:io';
import 'package:intl/intl.dart';

class DateUtils {
  
  static DateTime lastDate = DateTime.now().add(const Duration(days: 183));
  static String format(DateTime dateTime) {
    return DateFormat.yMEd(Platform.localeName).format(dateTime);
  }
  static String departureTime(DateTime min, DateTime max) {
    if (min.compareTo(max) == 0) {
      return DateFormat.yMEd(Platform.localeName).add_jm().format(min);
    }

    // Checking only day is enough since max day can only be two days greater than min.
    if (min.day == max.day) {
      return "${DateFormat.yMEd(Platform.localeName).add_jm().format(min)} — ${DateFormat.jm(Platform.localeName).format(max)}";
    }
    return "${DateFormat.yMEd(Platform.localeName).add_jm().format(min)} —\n${DateFormat.yMEd(Platform.localeName).add_jm().format(max)}";
  }
}

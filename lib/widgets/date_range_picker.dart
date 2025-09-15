import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRangePicker {
  static Future<Map<String, DateTime>?> open(
      BuildContext context, {
        required DateTime initialDate,
        required Set<String> fullyBookedDates,
        required List<Map<String, DateTime>> bookedRanges,
      }) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: initialDate,
        end: initialDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange, // header background
              onPrimary: Colors.white, // header text
              onSurface: Colors.black, // body text
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      return {
        "from": picked.start,
        "to": picked.end,
      };
    }
    return null;
  }
}

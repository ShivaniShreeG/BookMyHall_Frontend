import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeRangePicker {
  static Future<Map<String, DateTime>?> open(
      BuildContext context, {
        required DateTime initialDate,
        required Set<String> fullyBookedDates,
        required List<Map<String, DateTime>> bookedRanges,
      }) async {
    DateTime tempStartDate = initialDate;
    DateTime tempEndDate = initialDate;
    TimeOfDay? tempStartTime;
    TimeOfDay? tempEndTime;

    // 🔹 Helper: check overlaps
    String? checkOverlap(
        DateTime candidateFrom, DateTime candidateTo, List<Map<String, DateTime>> bookedRanges) {
      for (var slot in bookedRanges) {
        final existingFrom = slot['from']!;
        final existingTo = slot['to']!;

        // Overlap if not completely outside
        final hasOverlap = candidateFrom.isBefore(existingTo) &&
            candidateTo.isAfter(existingFrom);

        if (hasOverlap) {
          final formatter = DateFormat('dd MMM yyyy, hh:mm a');
          return "Conflicts with existing booking:\n"
              "${formatter.format(existingFrom)} → ${formatter.format(existingTo)}";
        }
      }
      return null;
    }

    return await showDialog<Map<String, DateTime>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> _confirm() async {
              if (tempStartTime == null || tempEndTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please select both start and end times."),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final candidateFrom = DateTime(
                tempStartDate.year,
                tempStartDate.month,
                tempStartDate.day,
                tempStartTime!.hour,
                tempStartTime!.minute,
              );
              final candidateTo = DateTime(
                tempEndDate.year,
                tempEndDate.month,
                tempEndDate.day,
                tempEndTime!.hour,
                tempEndTime!.minute,
              );

              if (!candidateTo.isAfter(candidateFrom)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("End must be after start."),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // 🔹 Check overlaps with message
              final overlapMessage = checkOverlap(candidateFrom, candidateTo, bookedRanges);
              if (overlapMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(overlapMessage),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context, {
                "from": candidateFrom,
                "to": candidateTo,
              });
            }

            return AlertDialog(
              title: const Text("Select Booking Range"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(
                      "Start Date: ${DateFormat('dd MMM yyyy').format(tempStartDate)}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.date_range),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempStartDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(DateTime.now().year + 2),
                          selectableDayPredicate: (day) {
                            final key = DateFormat('yyyy-MM-dd').format(day);
                            return !fullyBookedDates.contains(key);
                          },
                        );
                        if (picked != null) {
                          setStateDialog(() => tempStartDate = picked);
                        }
                      },
                    ),
                  ),
                  ListTile(
                    title: Text(
                      "Start Time: ${tempStartTime?.format(context) ?? "--:--"}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 10, minute: 0),
                        );
                        if (picked != null) {
                          setStateDialog(() => tempStartTime = picked);
                        }
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: Text(
                      "End Date: ${DateFormat('dd MMM yyyy').format(tempEndDate)}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.date_range),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempEndDate,
                          firstDate: tempStartDate,
                          lastDate: DateTime(DateTime.now().year + 2),
                          selectableDayPredicate: (day) {
                            final key = DateFormat('yyyy-MM-dd').format(day);
                            return !fullyBookedDates.contains(key);
                          },
                        );
                        if (picked != null) {
                          setStateDialog(() => tempEndDate = picked);
                        }
                      },
                    ),
                  ),
                  ListTile(
                    title: Text(
                      "End Time: ${tempEndTime?.format(context) ?? "--:--"}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 11, minute: 0),
                        );
                        if (picked != null) {
                          setStateDialog(() => tempEndTime = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: _confirm,
                  child: const Text("Confirm"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

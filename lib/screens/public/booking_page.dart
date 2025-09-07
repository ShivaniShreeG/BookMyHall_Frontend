import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../services/booking_service.dart';

class BookingPage extends StatefulWidget {
  final DateTime selectedDate;

  const BookingPage({super.key, required this.selectedDate});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController customerController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController altPhoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController eventController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController advanceController = TextEditingController();

  TimeOfDay fromTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay toTime = const TimeOfDay(hour: 14, minute: 0);

  // store full booking ranges instead of only start times
  List<Map<String, DateTime>> bookedRanges = [];

  @override
  void initState() {
    super.initState();
    _fetchBookedSlots();
  }

  Future<void> _fetchBookedSlots() async {
    final result = await BookingService.getBookings();
    if (result['success']) {
      final data = result['data'] as List;
      final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

      final ranges = data
          .where((b) =>
      DateFormat('yyyy-MM-dd')
          .format(DateTime.parse(b['from_datetime'])) ==
          dateStr)
          .map((b) => {
        "from": DateTime.parse(b['from_datetime']),
        "to": DateTime.parse(b['to_datetime']),
      })
          .toList();

      setState(() => bookedRanges = ranges);
    }
  }

  /// overlap checker
  bool _isOverlapping(DateTime newFrom, DateTime newTo) {
    for (var slot in bookedRanges) {
      final existingFrom = slot["from"]!;
      final existingTo = slot["to"]!;
      // overlap if start < existingEnd and end > existingStart
      if (newFrom.isBefore(existingTo) && newTo.isAfter(existingFrom)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Session expired. Please login again."),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    final fromDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      fromTime.hour,
      fromTime.minute,
    );

    final toDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      toTime.hour,
      toTime.minute,
    );

    if (toDateTime.isBefore(fromDateTime) ||
        toDateTime.isAtSameMomentAs(fromDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("End time must be after start time."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // check overlap with existing bookings
    if (_isOverlapping(fromDateTime, toDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selected time overlaps with an existing booking!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bookingData = {
      "user_id": int.parse(userId),
      "customer_name": customerController.text.trim(),
      "customer_phone": phoneController.text.trim(),
      "alternate_phone": altPhoneController.text.trim(),
      "customer_email": emailController.text.trim(),
      "customer_address": addressController.text.trim(),
      "event_details": eventController.text.trim(),
      "notes": notesController.text.trim(),
      "advance_paid": double.tryParse(advanceController.text.trim()) ?? 0.0,
      "from_datetime": fromDateTime.toIso8601String(),
      "to_datetime": toDateTime.toIso8601String(),
    };

    final response = await BookingService.createBooking(bookingData);

    if (response['success']) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Booking successful!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? "Booking failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
    DateFormat('dd MMMM yyyy').format(widget.selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text("Book Hall - $formattedDate"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (bookedRanges.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Already Booked Slots:\n${bookedRanges.map((s) => "${DateFormat('hh:mm a').format(s['from']!)} - ${DateFormat('hh:mm a').format(s['to']!)}").join(", ")}",
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                TextFormField(
                  controller: customerController,
                  decoration:
                  const InputDecoration(labelText: "Customer Name"),
                  validator: (value) =>
                  value == null || value.isEmpty
                      ? "Enter customer name"
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration:
                  const InputDecoration(labelText: "Phone Number"),
                  validator: (value) =>
                  value == null || value.isEmpty
                      ? "Enter phone number"
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: altPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: "Alternate Phone"),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                  const InputDecoration(labelText: "Email"),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: addressController,
                  decoration:
                  const InputDecoration(labelText: "Address"),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Event Type"),
                  items: [
                    "Wedding",
                    "Reception",
                    "Engagement",
                    "Birthday",
                    "Meeting",
                    "Other"
                  ]
                      .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => eventController.text = value!,
                  validator: (value) =>
                  value == null || value.isEmpty
                      ? "Select event type"
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                      labelText: "Notes (optional)"),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: advanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "Advance Paid (₹)"),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: fromTime,
                          );
                          if (picked != null) {
                            final newFrom = DateTime(
                              widget.selectedDate.year,
                              widget.selectedDate.month,
                              widget.selectedDate.day,
                              picked.hour,
                              picked.minute,
                            );
                            final newTo = DateTime(
                              widget.selectedDate.year,
                              widget.selectedDate.month,
                              widget.selectedDate.day,
                              toTime.hour,
                              toTime.minute,
                            );

                            if (_isOverlapping(newFrom, newTo)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "This start time overlaps with existing booking!"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } else {
                              setState(() => fromTime = picked);
                            }
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "From Time",
                            border: OutlineInputBorder(),
                          ),
                          child: Text(fromTime.format(context)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: toTime,
                          );
                          if (picked != null) {
                            final newFrom = DateTime(
                              widget.selectedDate.year,
                              widget.selectedDate.month,
                              widget.selectedDate.day,
                              fromTime.hour,
                              fromTime.minute,
                            );
                            final newTo = DateTime(
                              widget.selectedDate.year,
                              widget.selectedDate.month,
                              widget.selectedDate.day,
                              picked.hour,
                              picked.minute,
                            );

                            if (_isOverlapping(newFrom, newTo)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "This end time overlaps with existing booking!"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } else {
                              setState(() => toTime = picked);
                            }
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "To Time",
                            border: OutlineInputBorder(),
                          ),
                          child: Text(toTime.format(context)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _createBooking,
                  child: const Text("Confirm Booking"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

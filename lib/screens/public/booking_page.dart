import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../services/booking_service.dart';
import '../../widgets/date_time_range_picker.dart';

class BookingPage extends StatefulWidget {
  final DateTime selectedDate;

  const BookingPage({super.key, required this.selectedDate});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _formKey = GlobalKey<FormState>();
  final customerController = TextEditingController();
  final phoneController = TextEditingController();
  final altPhoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final eventController = TextEditingController();
  final notesController = TextEditingController();
  final advanceController = TextEditingController();

  DateTime? fromDateTime;
  DateTime? toDateTime;

  List<Map<String, DateTime>> bookedRanges = [];
  Set<String> fullyBookedDates = {};

  @override
  void initState() {
    super.initState();
    _fetchFullyBookedDates();
    _fetchBookedSlotsInRange();
  }

  // ✅ Fetch fully booked dates
  Future<void> _fetchFullyBookedDates() async {
    final result = await BookingService.getBookings();
    if (!mounted) return;
    if (result['success']) {
      final data = result['data'] as List;
      final slotCounts = <String, int>{};
      for (var b in data) {
        final from = DateTime.parse(b['from_datetime']);
        final key = DateFormat('yyyy-MM-dd').format(from);
        slotCounts[key] = (slotCounts[key] ?? 0) + 1;
      }
      final fullDates = slotCounts.entries
          .where((e) => e.value >= 3)
          .map((e) => e.key)
          .toSet();
      setState(() => fullyBookedDates = fullDates);
    }
  }

  // ✅ Fetch booked slots
  Future<void> _fetchBookedSlotsInRange() async {
    final result = await BookingService.getBookings();
    if (!mounted) return;
    if (result['success']) {
      final data = result['data'] as List;
      final ranges = data
          .map((b) => {
        "from": DateTime.parse(b['from_datetime']),
        "to": DateTime.parse(b['to_datetime']),
      })
          .toList();
      setState(() => bookedRanges = ranges);
    }
  }

  // ✅ Open combined date+time picker
  Future<void> _openDateTimeRangeDialog() async {
    final result = await DateTimeRangePicker.open(
      context,
      initialDate: widget.selectedDate,
      fullyBookedDates: fullyBookedDates,
      bookedRanges: bookedRanges,
    );

    if (result != null) {
      setState(() {
        fromDateTime = result["from"];
        toDateTime = result["to"];
      });
    }
  }

  // ✅ Create Booking
  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (fromDateTime == null || toDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select booking date & time."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
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
      "from_datetime": fromDateTime!.toIso8601String(),
      "to_datetime": toDateTime!.toIso8601String(),
    };

    final response = await BookingService.createBooking(bookingData);
    if (!mounted) return;

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
    return Scaffold(
      appBar: AppBar(title: const Text("Book Hall")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                TextFormField(
                  controller: customerController,
                  decoration: const InputDecoration(labelText: "Customer Name"),
                  validator: (v) =>
                  v == null || v.isEmpty ? "Enter customer name" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: "Phone Number"),
                  validator: (v) =>
                  v == null || v.isEmpty ? "Enter phone number" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: altPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration:
                  const InputDecoration(labelText: "Alternate Phone"),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: "Address"),
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
                      .map(
                          (e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => eventController.text = v ?? '',
                  validator: (v) =>
                  v == null || v.isEmpty ? "Select event type" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: notesController,
                  decoration:
                  const InputDecoration(labelText: "Notes (optional)"),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: advanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Advance Paid (₹)"),
                ),
                const SizedBox(height: 20),

                const Text("Booking Range",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                InkWell(
                  onTap: _openDateTimeRangeDialog,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Select Date & Time",
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      fromDateTime != null && toDateTime != null
                          ? "${DateFormat('dd MMM, hh:mm a').format(fromDateTime!)} → ${DateFormat('dd MMM, hh:mm a').format(toDateTime!)}"
                          : "Select Booking Date & Time",
                    ),
                  ),
                ),

                const SizedBox(height: 30),
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

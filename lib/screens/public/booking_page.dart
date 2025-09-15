import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
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

  // Controllers
  final customerController = TextEditingController();
  final phoneController = TextEditingController();
  final altPhoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final eventController = TextEditingController();
  final notesController = TextEditingController();
  final advanceController = TextEditingController();
  final rentController = TextEditingController(text: "20000");
  final tamilMonthController = TextEditingController();
  final eventDayController = TextEditingController();
  final eventDateTamilController = TextEditingController();

  DateTime? fromDateTime;
  DateTime? toDateTime;
  DateTime? eventDateFrom;
  DateTime? eventDateTo;

  List<Map<String, DateTime>> bookedRanges = [];
  Set<String> fullyBookedDates = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Default event date = selected date
    eventDateFrom = widget.selectedDate;
    eventDateTo = widget.selectedDate;

    // Default hall usage = previous day 5PM to event day 5PM
    _updateHallUsageDefaults();

    // Fill initial Tamil date & event day
    _updateTamilDateFields();

    _fetchFullyBookedDates();
    _fetchBookedSlotsInRange();
  }

  // Fetch fully booked dates
  Future<void> _fetchFullyBookedDates() async {
    final hallId = await AuthService.getHallId();
    if (hallId == null) return;

    final result = await BookingService.getBookings(hallId);
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

  // Fetch booked slots
  Future<void> _fetchBookedSlotsInRange() async {
    final hallId = await AuthService.getHallId();
    if (hallId == null) return;

    final result = await BookingService.getBookings(hallId);
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

  // Open hall usage picker
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

  Future<void> _pickEventDateRange() async {
    // Pick "from" date
    final from = await showDatePicker(
      context: context,
      initialDate: eventDateFrom ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (from == null) return;

    // Pick "to" date
    final to = await showDatePicker(
      context: context,
      initialDate: from,
      firstDate: from,
      lastDate: DateTime(2100),
    );

    if (to == null) return;

    setState(() {
      eventDateFrom = from;
      eventDateTo = to;

      _updateTamilDateFields();
      _updateHallUsageDefaults();
    });
  }


  // Update Tamil date fields
  void _updateTamilDateFields() {
    if (eventDateFrom == null) return;

    eventDayController.text = DateFormat('EEEE').format(eventDateFrom!);
    final tamilDate = GregorianToTamilCalendar.convert(eventDateFrom!);
    eventDateTamilController.text = tamilDate['tamilDay'].toString();
    tamilMonthController.text = tamilDate['tamilMonth'];
  }

  // Update hall usage defaults
  void _updateHallUsageDefaults() {
    if (eventDateFrom == null) return;

    fromDateTime = DateTime(
      eventDateFrom!.year,
      eventDateFrom!.month,
      eventDateFrom!.day - 1,
      17,
    );
    toDateTime = DateTime(
      eventDateFrom!.year,
      eventDateFrom!.month,
      eventDateFrom!.day,
      17,
    );
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return "Enter phone number";
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 10) return "Phone must be 10 digits";
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return "Enter valid email";
    return null;
  }

  // Create booking
  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final phone = "+91${phoneController.text.trim()}";
    final altNumbers = altPhoneController.text
        .split(",")
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .map((n) => "+91$n")
        .join(",");

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final userId = prefs.getString("userId");
    final hallId = prefs.getInt("hall_id");

    if (userId == null || userId.isEmpty || hallId == null) {
      setState(() => _isSubmitting = false);
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
      "hall_id": hallId,
      "customer_name": customerController.text.trim(),
      "customer_phone": phone,
      "alternate_phone": altNumbers,
      "customer_email": emailController.text.trim(),
      "customer_address": addressController.text.trim(),
      "event_details": eventController.text.trim(),
      "notes": notesController.text.trim(),
      "advance_paid": double.tryParse(advanceController.text.trim()) ?? 0.0,
      "rent": double.tryParse(rentController.text.trim()) ?? 0.0,
      "from_datetime": fromDateTime!.toIso8601String(),
      "to_datetime": toDateTime!.toIso8601String(),
      "event_date_from": DateFormat("yyyy-MM-dd").format(eventDateFrom!),
      "event_date_to": DateFormat("yyyy-MM-dd").format(eventDateTo!),
      "event_date_tamil":
      int.tryParse(eventDateTamilController.text.trim()) ?? 0,
      "tamil_month": tamilMonthController.text.trim(),
      "event_day": eventDayController.text.trim(),
    };

    final response = await BookingService.createBooking(bookingData);
    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (response['success']) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Booking successful!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      String errorMsg;
      if (response['conflict'] != null) {
        final fromUtc = DateTime.parse(response['conflict']['from']);
        final toUtc = DateTime.parse(response['conflict']['to']);
        final from = fromUtc.toLocal();
        final to = toUtc.toLocal();

        errorMsg =
        "Hall is already booked from ${DateFormat('dd MMM, hh:mm a').format(from)} "
            "to ${DateFormat('dd MMM, hh:mm a').format(to)}";
      } else {
        errorMsg = response['message'] ?? "Booking failed. Please try again.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    customerController.dispose();
    phoneController.dispose();
    altPhoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    eventController.dispose();
    notesController.dispose();
    advanceController.dispose();
    rentController.dispose();
    tamilMonthController.dispose();
    eventDayController.dispose();
    eventDateTamilController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(title: const Text("Book Hall"), backgroundColor: Colors.orange),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                  validator: _validatePhone,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: altPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: "Alternate Phone(s) - comma separated"),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: _validateEmail,
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
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
                  controller: rentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Total Rent (₹)"),
                  validator: (v) =>
                  v == null || v.isEmpty ? "Enter total rent" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: advanceController,
                  keyboardType: TextInputType.number,
                  decoration:
                  const InputDecoration(labelText: "Advance Paid (₹)"),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: eventDateTamilController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "Tamil Date"),
                  readOnly: true,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: tamilMonthController,
                  decoration: const InputDecoration(labelText: "Tamil Month"),
                  readOnly: true,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: eventDayController,
                  decoration: const InputDecoration(labelText: "Event Day"),
                  readOnly: true,
                ),
                const SizedBox(height: 20),
                const Text("Event Date Range",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickEventDateRange,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Select Event Date Range",
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      eventDateFrom != null && eventDateTo != null
                          ? "${DateFormat('dd MMM yyyy').format(eventDateFrom!)} → ${DateFormat('dd MMM yyyy').format(eventDateTo!)}"
                          : "Select Event Date Range",
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Hall Usage Range",
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _createBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text("Confirm Booking",
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Accurate Tamil calendar conversion
class GregorianToTamilCalendar {
  static const List<String> tamilMonths = [
    "Chithirai",
    "Vaikasi",
    "Aani",
    "Aadi",
    "Avani",
    "Purattasi",
    "Aipasi",
    "Karthigai",
    "Margazhi",
    "Thai",
    "Masi",
    "Panguni"
  ];

  // Start dates of Tamil months (month/day), the year will be applied dynamically
  static const List<Map<String, int>> tamilMonthStarts = [
    {"month": 4, "day": 14},
    {"month": 5, "day": 15},
    {"month": 6, "day": 15},
    {"month": 7, "day": 16},
    {"month": 8, "day": 16},
    {"month": 9, "day": 16},
    {"month": 10, "day": 16},
    {"month": 11, "day": 15},
    {"month": 12, "day": 15},
    {"month": 1, "day": 14},
    {"month": 2, "day": 13},
    {"month": 3, "day": 14},
  ];

  static Map<String, dynamic> convert(DateTime date) {
    int year = date.year;

    // Generate Tamil month start dates for the current year
    List<DateTime> monthStartDates = tamilMonthStarts.map((m) {
      int monthYear = (m["month"]! < 4) ? year + 1 : year; // months Jan-Mar belong to next Tamil year
      return DateTime(monthYear, m["month"]!, m["day"]!);
    }).toList();

    // Find the current Tamil month
    int monthIndex = 0;
    for (int i = 0; i < monthStartDates.length; i++) {
      final startDate = monthStartDates[i];
      final nextIndex = (i + 1) % monthStartDates.length;
      final nextStartDate = monthStartDates[nextIndex];
      if ((date.isAtSameMomentAs(startDate) || date.isAfter(startDate)) &&
          date.isBefore(nextStartDate)) {
        monthIndex = i;
        break;
      }
    }

    // Calculate Tamil day
    final monthStartDate = monthStartDates[monthIndex];
    int tamilDay = date.difference(monthStartDate).inDays + 1;
    if (tamilDay <= 0) {
      final prevIndex = (monthIndex - 1 + monthStartDates.length) %
          monthStartDates.length;
      final prevMonthStart = monthStartDates[prevIndex];
      tamilDay = date.difference(prevMonthStart).inDays + 1;
      monthIndex = prevIndex;
    }

    return {
      "tamilDay": tamilDay,
      "tamilMonth": tamilMonths[monthIndex],
    };
  }
}


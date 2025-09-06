import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../services/booking_service.dart';
import 'booking_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<String, List<String>> bookedDates = {};
  bool isLoading = true;
  bool isLoggedIn = false;
  String? userRole;

  static const int totalSlots = 8;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    fetchBookings();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool("isLoggedIn") ?? false;
      userRole = prefs.getString("role");
    });
  }

  Future<void> fetchBookings() async {
    setState(() => isLoading = true);
    final result = await BookingService.getBookings();
    if (result['success']) {
      final data = result['data'] as List;
      final Map<String, List<String>> temp = {};
      for (var booking in data){
        DateTime fromDateTime = DateTime.parse(booking['from_datetime']);
        DateTime toDateTime = DateTime.parse(booking['to_datetime']);
        final date = DateFormat('yyyy-MM-dd').format(fromDateTime);
        final timeRange =
            "${DateFormat('hh:mm a').format(fromDateTime)} - ${DateFormat('hh:mm a').format(toDateTime)}";
        temp[date] ??= [];
        temp[date]!.add(timeRange);
      }

      setState(() => bookedDates = temp);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Failed to fetch bookings")),
      );
    }
    setState(() => isLoading = false);
  }

  Color _getDayColor(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    if (!bookedDates.containsKey(dateStr)) return Colors.green;
    final slots = bookedDates[dateStr]!;
    final bookedCount = slots.length;
    if (bookedCount == 0) return Colors.green;
    if (bookedCount < totalSlots) return Colors.orange;
    return Colors.red;
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.orange, size: 28),
                  SizedBox(width: 10),
                  Text(
                    "Booking Info",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "To book the hall, please contact the manager.\nIf you are a manager, please login.",
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/login");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookedSlotsDialog(List<String> slots, DateTime selectedDay) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slots.isEmpty ? "No Bookings Yet" : "Booked Slots",
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              const SizedBox(height: 10),
              for (var timeRange in slots)
                Text(timeRange, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (isLoggedIn && (userRole == "manager" || userRole == "admin")) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingPage(selectedDate: selectedDay),
                          ),
                        ).then((result) {
                          if (result == true) fetchBookings();
                        });
                      } else {
                        _showLoginDialog();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Book Now"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    if (selectedDay.isBefore(DateTime.now())) return;

    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
    final slots = bookedDates[dateStr] ?? [];

    // Fully booked
    if (slots.length >= totalSlots) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This date is fully booked!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show booked slots (for everyone)
    _showBookedSlotsDialog(slots, selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            const SizedBox(height: 16),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  enabledDayPredicate: (day) => !day.isBefore(today),
                  onDaySelected: _onDaySelected,
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      if (day.isBefore(today)) {
                        return Center(
                          child: Text(
                            "${day.day}",
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        );
                      }
                      final color = _getDayColor(day);
                      return Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 3,
                                offset: Offset(1, 2))
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "${day.day}",
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                    todayBuilder: (context, day, focusedDay) {
                      final color = isSameDay(_selectedDay, day)
                          ? Colors.blue
                          : _getDayColor(day);
                      return Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color,
                          border: Border.all(color: Colors.black26, width: 2),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 3,
                                offset: Offset(1, 2))
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "${day.day}",
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildLegendItem(Colors.green, "Available")),
                      Expanded(child: _buildLegendItem(Colors.orange, "Partially Booked")),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildLegendItem(Colors.red, "Fully Booked")),
                      Expanded(child: _buildLegendItem(Colors.blue, "Selected")),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12, width: 1),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(1, 1))
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

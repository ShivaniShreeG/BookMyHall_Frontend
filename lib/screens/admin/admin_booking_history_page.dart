import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/booking_service.dart';
import 'admin_booking_details_page.dart';

class AdminBookingHistoryPage extends StatefulWidget {
  const AdminBookingHistoryPage({super.key});

  @override
  State<AdminBookingHistoryPage> createState() => _AdminBookingHistoryPageState();
}

class _AdminBookingHistoryPageState extends State<AdminBookingHistoryPage> {
  late Future<Map<String, dynamic>> _bookingHistoryFuture;

  List bookings = [];
  List filteredBookings = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _bookingHistoryFuture = BookingService.getBookingHistory();
  }

  DateTime _parseLocalDateTime(String dateTimeStr) {
    return DateTime.parse(dateTimeStr).toLocal();
  }

  /// ✅ Filter function
  void _filterBookings(String query) {
    setState(() {
      searchQuery = query.toLowerCase();

      filteredBookings = bookings.where((item) {
        final booking = item["booking"];
        final name = (booking["customer_name"] ?? "").toString().toLowerCase();
        final phone = (booking["customer_phone"] ?? "").toString().toLowerCase();

        final fromDateTime = _parseLocalDateTime(booking["from_datetime"]);
        final toDateTime = _parseLocalDateTime(booking["to_datetime"]);
        final dateStr =
        "${DateFormat("MMM d, yyyy").format(fromDateTime)} ${DateFormat("MMM d, yyyy").format(toDateTime)}"
            .toLowerCase();

        return name.contains(searchQuery) ||
            phone.contains(searchQuery) ||
            dateStr.contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // ✅ AppBar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade700, Colors.indigo.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "📜 Booking History",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _bookingHistoryFuture = BookingService.getBookingHistory();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        future: _bookingHistoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("❌ No data received"));
          }

          final response = snapshot.data!;
          if (!response["success"]) {
            return Center(
              child: Text(
                "⚠️ Failed to load booking history\n"
                    "Status: ${response["status"] ?? "Unknown"}\n"
                    "Message: ${response["message"] ?? "Unknown error"}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            );
          }

          final rawData = response["data"];
          bookings = [];
          if (rawData is List) bookings = rawData;

          if (bookings.isEmpty) {
            return const Center(
              child: Text(
                "📭 No booking history available",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          bookings.sort((a, b) {
            final fromA = _parseLocalDateTime(a["booking"]["from_datetime"]);
            final fromB = _parseLocalDateTime(b["booking"]["from_datetime"]);
            return fromB.compareTo(fromA);
          });

          final displayList = searchQuery.isEmpty ? bookings : filteredBookings;

          return Column(
            children: [
              // 🔍 Search bar
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search by name, phone or date",
                    prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          searchQuery = "";
                          filteredBookings = bookings;
                        });
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _filterBookings,
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final booking = displayList[index]["booking"];
                    final fromDateTime = _parseLocalDateTime(booking["from_datetime"]);
                    final toDateTime = _parseLocalDateTime(booking["to_datetime"]);

                    final fromDate = DateFormat("MMM d, yyyy").format(fromDateTime);
                    final toDate = DateFormat("MMM d, yyyy").format(toDateTime);
                    final fromTime = DateFormat("hh:mm a").format(fromDateTime);
                    final toTime = DateFormat("hh:mm a").format(toDateTime);

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AdminBookingDetailsPage(bookingId: booking["booking_id"]),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 Gradient Header
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.indigo.shade400, Colors.indigo.shade700],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(18)),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Booking #${booking["booking_id"]}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: booking["status"] == "booked"
                                          ? Colors.green.shade400
                                          : booking["status"] == "cancelled"
                                          ? Colors.red.shade400
                                          : Colors.orange.shade400,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      booking["status"] ?? "Unknown",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 👤 Customer Info
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.indigo.shade50,
                                        child: const Icon(Icons.person, color: Colors.indigo),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          booking["customer_name"] ?? "Unknown Customer",
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (booking["customer_phone"] != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.grey.shade200,
                                          child: const Icon(Icons.phone,
                                              size: 16, color: Colors.black54),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          booking["customer_phone"],
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ],

                                  const Divider(height: 24),

                                  // 📅 Date + Time
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 16, color: Colors.indigo),
                                      const SizedBox(width: 6),
                                      Text(
                                        fromDate == toDate ? fromDate : "$fromDate → $toDate",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time,
                                          size: 16, color: Colors.indigo),
                                      const SizedBox(width: 6),
                                      Text("$fromTime - $toTime",
                                          style: const TextStyle(fontSize: 14)),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // 🎉 Event
                                  Row(
                                    children: [
                                      const Icon(Icons.celebration,
                                          size: 16, color: Colors.deepPurple),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          booking["event_details"] ?? "No details",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.indigo.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

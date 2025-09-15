import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/booking_service.dart';

class AdminBookingDetailsPage extends StatefulWidget {
  final int bookingId;

  const AdminBookingDetailsPage({super.key, required this.bookingId});

  @override
  State<AdminBookingDetailsPage> createState() => _AdminBookingDetailsPageState();
}

class _AdminBookingDetailsPageState extends State<AdminBookingDetailsPage> {
  late Future<Map<String, dynamic>> _bookingFuture;

  @override
  void initState() {
    super.initState();
    _bookingFuture = BookingService.getBookingById(widget.bookingId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Details"),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _bookingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!["success"]) {
            return const Center(child: Text("❌ Failed to load booking details"));
          }

          final booking = snapshot.data!["data"];
          final fromDate = DateTime.parse(booking["from_datetime"]);
          final toDate = DateTime.parse(booking["to_datetime"]);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Customer: ${booking["customer_name"]}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text("Phone: ${booking["customer_phone"] ?? "N/A"}"),
                    const SizedBox(height: 8),
                    Text("Event: ${booking["event_details"] ?? "N/A"}"),
                    const SizedBox(height: 8),
                    Text(
                        "Date: ${DateFormat("EEE, MMM d, yyyy").format(fromDate)}"),
                    const SizedBox(height: 8),
                    Text(
                        "Time: ${DateFormat("hh:mm a").format(fromDate)} - ${DateFormat("hh:mm a").format(toDate)}"),
                    const SizedBox(height: 8),
                    Text("Status: ${booking["status"]}"),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

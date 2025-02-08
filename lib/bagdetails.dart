import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartbag2/reminders.dart';

class Bagdetails extends StatefulWidget {
  String bagId;
  Bagdetails({super.key, required this.bagId});

  @override
  State<Bagdetails> createState() => _BagdetailsState();
}

class _BagdetailsState extends State<Bagdetails> {
  final User currentUser = FirebaseAuth.instance.currentUser!;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("bags");
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  Map<dynamic, dynamic>? bagData;
  bool loading = true;
  bool isBagLost = false;
  bool isReminderOn = false;

  @override
  void initState() {
    super.initState();
    fetchBagDetails();
  }

  // Fetching the bag details from Firebase
  void fetchBagDetails() {
    _databaseRef.child(widget.bagId).onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        setState(() {
          bagData = snapshot.value as Map<dynamic, dynamic>;
          isBagLost = bagData?['isLost'] ?? false;
          isReminderOn = bagData?['reminder'] ?? false;
          loading = false;
        });
      } else {
        setState(() {
          bagData = null;
          loading = false;
        });
      }
    });
  }

  
  void toggleFindMyBag(bool value) {
    setState(() {
      isBagLost = value;
    });

    _databaseRef.child(widget.bagId).update({"lost": value});
  }

  void toggleReminders(bool value) {
  setState(() {
    isReminderOn = value;
  });

  _databaseRef.child(widget.bagId).child("reminders").update({"status": value});
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bag Details"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : bagData == null
              ? const Center(child: Text("Bag not found"))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Name: ${bagData!['name'] ?? "Unknown"}",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Battery: ${bagData!['battery']?.toString() ?? "Unknown"}%",
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            "Weight: ${bagData!['weight']?.toString() ?? "Unknown"} kg",
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            "Last Location: ${bagData!['last_location']?['latitude']?.toString() ?? "Unknown"}, "
                            "${bagData!['last_location']?['longitude']?.toString() ?? "Unknown"}",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 20),

                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Find My Bag",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              Switch(
                                value: isBagLost,
                                onChanged: toggleFindMyBag,
                              ),
                            ],
                          ),

                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Reminders",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              Switch(
                                value: isReminderOn,
                                onChanged: toggleReminders,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      height: 450,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: GoogleMap(
                          mapType: MapType.normal,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              bagData!['last_location']['latitude'] ?? 0.0,
                              bagData!['last_location']['longitude'] ?? 0.0,
                            ),
                            zoom: 15,
                          ),
                          onMapCreated: (GoogleMapController controller) {
                            _controller.complete(controller);
                          },
                          markers: {
                            Marker(
                              markerId: const MarkerId('current_location'),
                              position: LatLng(
                                bagData!['last_location']['latitude'] ?? 0.0,
                                bagData!['last_location']['longitude'] ?? 0.0,
                              ),
                            ),
                          },
                          zoomControlsEnabled: true,
                        ),
                      ),
                    ),
                  ],
                ),
                
                floatingActionButton: SizedBox(
                  width: 180, 
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      showDialog(
                        context: context, 
                        builder: (context) => Reminders(bagId: widget.bagId),
                      );
                    },
                    backgroundColor: Colors.teal, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      "Set a Reminder",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
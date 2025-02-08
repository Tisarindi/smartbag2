import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smartbag2/addbag.dart';
import 'package:smartbag2/bagdetails.dart';

class Dashboard extends StatefulWidget {
  final User currentUser = FirebaseAuth.instance.currentUser!;
  Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("bags");
  List<Map<dynamic, dynamic>> bags = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchBagDetails();
    //addBagsToRealtimeDB();
  }

  //delete this function: only use for create temp bags
  Future<void> addBagsToRealtimeDB() async {
    final databaseRef = FirebaseDatabase.instance.ref();

//     final bags = [
//       {
//             "id": "abcd1",
//             "name": "Bag 1",
//             "ownerId": "QKzb7M4mSrSW8ethBqqcMqBsQ6I2",
//             "contactNo": "07611223333",
//             "battery": 100,
//             "weight": 5,
//             "last_location": {
//                 "latitude": 12.9716,
//                 "longitude": 77.5946,
//                 "last_updated": "2021-06-01T12:00:00Z"
//             },
//             "lost": false,
//             "reminders": {
//                 "status": false,
//                 "sunday": "History, Maths, Science",
//                 "monday": null,
//                 "tuesday": "Science, English, Biology",
//                 "wednesday": null,
//                 "thursday": null,
//                 "friday": null,
//                 "saturday": null
//             } 
//         },
//         {
//             "id": "abcd2",
//             "name": "Bag 2",
//             "ownerId": "QKzb7M4mSrSW8ethBqqcMqBsQ6I2",
//             "contactNo": "07611223333",
//             "battery": 50,
//             "weight": 5,
//             "last_location": {
//                 "latitude": 12.9716,
//                 "longitude": 77.5946,
//                 "last_updated": "2021-06-01T12:00:00Z"
//             },
//             "lost": false,
//             "reminders": {
//                 "status": false,
//                 "sunday": "History, Maths, Science",
//                 "monday": null,
//                 "tuesday": "Science, English, Biology",
//                 "wednesday": null,
//                 "thursday": null,
//                 "friday": null,
//                 "saturday": null
//             } 
//         },
//         {
//             "id": "abcd3",
//             "battery": 18,
//             "weight": 5,
//             "last_location": {
//                 "latitude": 12.9716,
//                 "longitude": 77.5946,
//                 "last_updated": "2021-06-01T12:00:00Z"
//             },
//             "lost": false,
//             "reminders": {
//                 "status": false,
//                 "sunday": "History, Maths, Science",
//                 "monday": null,
//                 "tuesday": "Science, English, Biology",
//                 "wednesday": null,
//                 "thursday": null,
//                 "friday": null,
//                 "saturday": null
//             } 
// }
//     ];

    try {
      for (var bag in bags) {
        final bagID = bag['id']; 
        await databaseRef.child('bags/$bagID').set(bag);
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
}

  void fetchBagDetails() {
    final uid = widget.currentUser.uid;	
    // addBagsToRealtimeDB(); 
    
    _databaseRef
        .orderByChild('ownerId')
        .equalTo(uid)
        .onValue
        .listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        print("dashboarddd data:");
        final List<Map<dynamic, dynamic>> updatedBags = [];
        data.forEach((key, value) {
          if (value['ownerId'] == uid) {
            updatedBags.add({
              'id': key,
              'name': value['name'] ?? 'Unknown',
              'battery': value['battery'],
              'weight': value['weight'],
              'last_location': value['last_location'],
            });
          }
        });

        setState(() {
          bags = updatedBags;
          loading = false;
        });
      } else {
        setState(() {
          bags = [];
          loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Profile Details'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${widget.currentUser.displayName ?? "Unknown"}'),
                      Text('Email: ${widget.currentUser.email ?? "Unknown"}'),	
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : bags.isEmpty 
          ? const Center(child: Text('No bags found'))
          : ListView.builder(
              itemCount: bags.length,
              itemBuilder: (context, index) {
                final bag = bags[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text("Name: ${bag['name']}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Battery: ${bag['battery']}%"),
                        Text("Weight: ${bag['weight']} kg"),
                        Text("Last Location: ${bag['last_location'] ?? 'Unknown'}"),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Bagdetails(bagId: bag['id'].toString()),
                        ),
                      );
                    },
                  ),
                );

              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context, 
            builder: (BuildContext context){
              return AddBagDialog(onBagAdded: fetchBagDetails);

            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
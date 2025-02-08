import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class Reminders extends StatefulWidget {
  final String bagId;
  const Reminders({super.key, required this.bagId});

  @override
  State<Reminders> createState() => _RemindersState();
}

class _RemindersState extends State<Reminders> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("bags");
  String selectedDay = "Sunday"; 
  TextEditingController descriptionController = TextEditingController();

void saveReminder() {
  String description = descriptionController.text.trim();

  if (description.isNotEmpty) {
    // Converting to lowercase 
    String lowercaseDay = selectedDay.toLowerCase();
    _databaseRef.child("${widget.bagId}/reminders/$lowercaseDay").set(description);
    Navigator.pop(context);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter a description")),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Set a Reminder"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: selectedDay,
            onChanged: (newValue) {
              setState(() {
                selectedDay = newValue!;
              });
            },
            items: [
              "Sunday",
              "Monday",
              "Tuesday",
              "Wednesday",
              "Thursday",
              "Friday",
              "Saturday"
            ].map((day) {
              return DropdownMenuItem(value: day, child: Text(day));
            }).toList(),
            decoration: const InputDecoration(labelText: "Select a Day"),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(labelText: "Description"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Close"),
        ),

        ElevatedButton(
          onPressed: saveReminder,
          child: const Text("Add"),
        ),
      ],
    );
  }
}

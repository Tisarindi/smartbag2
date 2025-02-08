import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddBagDialog extends StatefulWidget {
  final Function() onBagAdded;

  const AddBagDialog({super.key, required this.onBagAdded});

  @override
  _AddBagDialogState createState() => _AddBagDialogState();
}

class _AddBagDialogState extends State<AddBagDialog> {
  final TextEditingController bagNameController = TextEditingController();
  final TextEditingController bagIdController = TextEditingController();
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("bags");
  final User currentUser = FirebaseAuth.instance.currentUser!;
  bool isChecking = false;

  void _checkAndAddBag() async {
    String bagName = bagNameController.text.trim();
    String bagId = bagIdController.text.trim();

    if (bagName.isEmpty || bagId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter all details")),
      );
      return;
    }

    setState(() {
      isChecking = true;
    });

    // Checking if bag id already exists or not
    final bagSnapshot = await _databaseRef.child(bagId).get();
    
    if (!bagSnapshot.exists) {
      setState(() {
        isChecking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bag ID not found. Please enter a valid Bag ID.")),
      );
      return;
    }

    // Adding bag to user's account
    await _databaseRef.child(bagId).update({
      'ownerId': currentUser.uid,
      'name': bagName,
    });

    setState(() {
      isChecking = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Bag Added Successfully")),
    );

    widget.onBagAdded(); 
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add New Bag"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: bagNameController,
            decoration: const InputDecoration(
              labelText: "Bag Name",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: bagIdController,
            decoration: const InputDecoration(
              labelText: "Bag ID",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
        ElevatedButton(
          onPressed: isChecking ? null : _checkAndAddBag, 
          child: isChecking
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Add"),
        ),
      ],
    );
  }
}

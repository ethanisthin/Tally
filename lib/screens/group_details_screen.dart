import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/firebase_service.dart';

class GroupDetailsScreen extends StatefulWidget {
  final Group group;
  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  late Group group;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    group = widget.group;
  }

  Future<void> _editGroup(BuildContext context) async {
    final nameController = TextEditingController(text: group.name);
    final locationController = TextEditingController(text: group.location);
    final peopleController = TextEditingController(text: group.numberOfPeople.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
            TextField(controller: peopleController, decoration: const InputDecoration(labelText: 'Number of People'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final updatedGroup = group.copyWith(
                name: nameController.text,
                location: locationController.text,
                numberOfPeople: int.tryParse(peopleController.text) ?? group.numberOfPeople,
              );
              await _firebaseService.updateGroup(updatedGroup);
              setState(() {
                group = updatedGroup;
              });
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group updated!')));
    }
  }

   Future<void> _addMemberNameDialog(BuildContext context) async {
    final controller = TextEditingController();
    String? errorText;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Add Member by Name'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'User Name',
                    errorText: errorText,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) {
                    setState(() => errorText = 'Please enter a name');
                    return;
                  }
                  // Query Firestore for user by name
                  final userQuery = await _firebaseService.firestore
                      .collection('users')
                      .where('name', isEqualTo: name)
                      .limit(1)
                      .get();
                  if (userQuery.docs.isEmpty) {
                    setState(() => errorText = 'User not found');
                    return;
                  }
                  final userId = userQuery.docs.first.id;
                  await _firebaseService.addUserToGroup(group.id, userId);
                  setState(() {
                    group.members.add(userId);
                    group = group.copyWith(members: List.from(group.members));
                  });
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editGroup(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${group.location}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('People: ${group.numberOfPeople}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            const Text('Members: ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: group.members.length,
                itemBuilder: (context, index) {
                  final memberId = group.members[index];
                  return ListTile(
                    title: Text(memberId),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle),
                      onPressed: () async {
                        await _firebaseService.removeUserFromGroup(group.id, memberId);
                        setState(() {
                          group.members.removeAt(index);
                          group = group.copyWith(members: List.from(group.members));
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton(
                onPressed: () => _addMemberNameDialog(context),
                child: const Text('Add Member'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
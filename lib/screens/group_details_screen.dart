import 'package:flutter/material.dart';
import 'package:trip_expense_tracker/screens/create_purchase_screen.dart';
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

  Future<Map<String, String>> _getUserNames(List<String> userIds) async {
    final usersCollection = FirebaseService().firestore.collection('users');
    final names = <String, String>{};
    for (final id in userIds){
      final doc = await usersCollection.doc(id).get();
      names[id] = doc.data()?['name'] ?? id;
    }
    return names;
  }

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
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: 'Add Purchase',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CreatePurchaseScreen(group: group)));
            },
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


            const Text('Purchases:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
            future: _firebaseService.getGroupPurchases(group.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No purchases yet.');
              }
              final purchases = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: purchases.length,
                itemBuilder: (context, index) {
                  final purchase = purchases[index];
                  final payeeIds = List<String>.from(purchase['payees'] ?? []);
                  return FutureBuilder<Map<String, String>>(future: _getUserNames(payeeIds), 
                  builder: (context, snapshot) {
                    final payeeNames = snapshot.data?.values.join(', ') ?? payeeIds.join(', ');
                    return ListTile(
                          title: Text(purchase['name'] ?? 'Unnamed'),
                          subtitle: Text('Payees: $payeeNames'),
                          trailing: Text(purchase['splitMethod'] ?? ''),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(purchase['name'] ?? 'Purchase Details'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Split Method: ${purchase['splitMethod'] ?? ''}'),
                                    const SizedBox(height: 8),
                                    Text('Payees: $payeeNames'),
                                    const SizedBox(height: 8),
                                    if (purchase['amounts'] != null)
                                    ...((purchase['amounts'] as Map<String, dynamic>).entries.map((e) {
                                      final amount = (e.value is num) ? (e.value as num).toStringAsFixed(2) : e.value.toString();
                                      return Text('${snapshot.data?[e.key] ?? e.key}: \$$amount');
                                    })),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final purchaseId = purchase['id'] ?? '';
                                      if (purchaseId.isNotEmpty) {
                                        await _firebaseService.deletePurchase(group.id, purchaseId);
                                        Navigator.pop(context); 
                                        setState(() {});
                                      }
                                    },
                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                  },
                );
                  
                },
              );
            },
          ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, String>>(
              future: _getUserNames(group.members),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final memberNames = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: group.members.length,
                  itemBuilder: (context, index) {
                    final memberId = group.members[index];
                    final name = memberNames[memberId] ?? memberId;
                    return ListTile(
                      title: Text(name),
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
                );
              },
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
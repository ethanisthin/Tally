import 'package:flutter/material.dart';
import 'package:tally/screens/create_purchase_screen.dart';
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
    for (final id in userIds) {
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


  Future<void> _updatePaymentStatus(String purchaseId, String userId, bool isPaid) async {
    await _firebaseService.userPaymentStatus(group.id, purchaseId, userId, isPaid);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment status updated'))
    );
  }


  Future<Map<String, Map<String, dynamic>>> _calculateFinancialSummary() async {
    final purchases = await _firebaseService.getGroupPurchases(group.id);
    final summary = <String, Map<String, dynamic>>{};

    for (final purchase in purchases) {
      final payees = List<String>.from(purchase['payees'] ?? []);
      final amounts = purchase['amounts'] as Map<String, dynamic>?;
      final paymentStatus = purchase['paymentStatus'] as Map<String, dynamic>?;

      if (amounts != null) {
        for (final userId in payees) {
          if (!summary.containsKey(userId)) {
            summary[userId] = {'totalOwed': 0.0, 'totalPaid': 0.0};
          }

          final amount = amounts[userId] is num ? (amounts[userId] as num).toDouble() : 0.0;
          summary[userId]!['totalOwed'] = (summary[userId]!['totalOwed'] as double) + amount;

          if (paymentStatus != null && paymentStatus[userId] == true) {
            summary[userId]!['totalPaid'] = (summary[userId]!['totalPaid'] as double) + amount;
          }
        }
      }
    }

    return summary;
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


            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Financial Summary',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _firebaseService.getGroupPurchasesStream(group.id),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final purchases = snapshot.data!;
                        final summary = <String, Map<String, dynamic>>{};

                        for (final purchase in purchases) {
                          final payees = List<String>.from(purchase['payees'] ?? []);
                          final amounts = purchase['amounts'] as Map<String, dynamic>?;
                          final paymentStatus = purchase['paymentStatus'] as Map<String, dynamic>?;

                          if (amounts != null) {
                            for (final userId in payees) {
                              summary[userId] ??= {'totalOwed': 0.0, 'totalPaid': 0.0};
                              final amount = amounts[userId] is num ? (amounts[userId] as num).toDouble() : 0.0;
                              summary[userId]!['totalOwed'] += amount;
                              if (paymentStatus != null && paymentStatus[userId] == true) {
                                summary[userId]!['totalPaid'] += amount;
                              }
                            }
                          }
                        }

                        return FutureBuilder<Map<String, String>>(
                          future: _getUserNames(summary.keys.toList()),
                          builder: (context, namesSnapshot) {
                            if (!namesSnapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final names = namesSnapshot.data!;
                            return Column(
                              children: summary.entries.map((entry) {
                                final userId = entry.key;
                                final data = entry.value;
                                final userName = names[userId] ?? userId;
                                final totalOwed = data['totalOwed'] as double;
                                final totalPaid = data['totalPaid'] as double;
                                final balance = totalPaid - totalOwed;

                                return ListTile(
                                  title: Text(userName),
                                  subtitle: Text(
                                    'Paid: \$${totalPaid.toStringAsFixed(2)} / Owed: \$${totalOwed.toStringAsFixed(2)}'
                                  ),
                                  trailing: Text(
                                    '${balance >= 0 ? '+' : ''}\$${balance.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: balance >= 0 ? Colors.green : Colors.red,
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Text('Members: ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<Map<String, String>>(
              future: _getUserNames(group.members),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final memberNames = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: group.members.length,
                  itemBuilder: (context, index) {
                    final memberId = group.members[index];
                    final name = memberNames[memberId];
                    return ListTile(
                      title: Text(name ?? 'Loading...'),
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
            const SizedBox(height: 16),
            const Text('Purchases:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firebaseService.getGroupPurchasesStream(group.id),
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
                    itemCount: purchases.length,
                    itemBuilder: (context, index) {
                      final purchase = purchases[index];
                      final payeeIds = List<String>.from(purchase['payees'] ?? []);
                      return FutureBuilder<Map<String, String>>(
                        future: _getUserNames(payeeIds),
                        builder: (context, snapshot) {
                          final payeeNames = snapshot.hasData
                              ? snapshot.data!.values.join(', ')
                              : List.filled(payeeIds.length, '...').join(', ');
                          final paymentStatus = (purchase['paymentStatus'] as Map<String, dynamic>?) ?? {};
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(purchase['name'] ?? 'Unnamed'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Payees: $payeeNames'),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    children: payeeIds.map((userId) {
                                      final isPaid = paymentStatus[userId] == true;
                                      final userName = snapshot.data?[userId] ?? userId.substring(0, 4);

                                      return Chip(
                                        avatar: Icon(
                                          isPaid ? Icons.check_circle : Icons.pending,
                                          color: isPaid ? Colors.green : Colors.orange,
                                          size: 18,
                                        ),
                                        label: Text(userName),
                                        backgroundColor: isPaid
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.orange.withOpacity(0.1),
                                        labelStyle: TextStyle(
                                          color: isPaid ? Colors.green.shade800 : Colors.orange.shade800,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                (() {
                                  final amounts = purchase['amounts'] as Map<String, dynamic>?;
                                  if (amounts == null) return '';
                                  final total = amounts.values
                                      .map((v) => v is num ? v.toDouble() : 0.0)
                                      .fold(0.0, (a, b) => a + b);
                                  return '\$${total.toStringAsFixed(2)}';
                                })(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => StatefulBuilder(
                                    builder: (context, setState) => AlertDialog(
                                      title: Text(purchase['name'] ?? 'Purchase Details'),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Split Method: ${purchase['splitMethod'] ?? ''}'),
                                            const SizedBox(height: 16),
                                            const Text('Payees & Payment Status:',
                                              style: TextStyle(fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 8),


                                            ...payeeIds.map((userId) {
                                              final paymentStatus = (purchase['paymentStatus'] as Map<String, dynamic>?) ?? {};
                                              final isPaid = paymentStatus[userId] == true;
                                              final userName = snapshot.data?[userId] ?? '...';
                                              final amount = purchase['amounts']?[userId];
                                              final amountStr = amount is num
                                                ? '\$${amount.toStringAsFixed(2)}'
                                                : '';

                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                decoration: BoxDecoration(
                                                  color: isPaid
                                                    ? Colors.green.withOpacity(0.1)
                                                    : Colors.orange.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: ListTile(
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                                  leading: Icon(
                                                    isPaid ? Icons.check_circle : Icons.pending,
                                                    color: isPaid ? Colors.green : Colors.orange,
                                                  ),
                                                  title: Text(userName),
                                                  subtitle: Text(amountStr),
                                                  trailing: Switch(
                                                    value: isPaid,
                                                    activeColor: Colors.green,
                                                    onChanged: (newValue) async {
                                                      await _updatePaymentStatus(
                                                        purchase['id'],
                                                        userId,
                                                        newValue
                                                      );
                                                      setState(() {
                                                        paymentStatus[userId] = newValue;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              );
                                            }).toList(),

                                            const Divider(height: 24),


                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text('Total:',
                                                  style: TextStyle(fontWeight: FontWeight.bold)),
                                                Text(
                                                  (() {
                                                    final amounts = purchase['amounts'] as Map<String, dynamic>?;
                                                    if (amounts == null) return '';
                                                    final total = amounts.values
                                                        .map((v) => v is num ? v.toDouble() : 0.0)
                                                        .fold(0.0, (a, b) => a + b);
                                                    return '\$${total.toStringAsFixed(2)}';
                                                  })(),
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Close'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => CreatePurchaseScreen(
                                                  group: group,
                                                  purchase: purchase,
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text('Edit'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            final purchaseId = purchase['id'] ?? '';
                                            if (purchaseId.isNotEmpty) {
                                              await _firebaseService.deletePurchase(group.id, purchaseId);
                                              Navigator.pop(context);
                                            }
                                          },
                                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
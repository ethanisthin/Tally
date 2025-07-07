import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/firebase_service.dart';
import 'package:flutter/services.dart';

class CreatePurchaseScreen extends StatefulWidget {
  final Group group;
  const CreatePurchaseScreen({super.key, required this.group});

  @override
  State<CreatePurchaseScreen> createState() => _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends State<CreatePurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  String purchaseName = '';
  List<String> selectedPayees = [];
  String splitMethod = 'equal';
  Map<String, double> amounts = {};

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Purchase')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Purchase Name'),
                onChanged: (val) => setState(() => purchaseName = val),
                validator: (val) => val == null || val.isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              const Text('Select Payees:', style: TextStyle(fontWeight: FontWeight.bold)),
              FutureBuilder<Map<String, String>>(
                future: _getUserNames(widget.group.members),
                builder: (context, snapshot) {
                  final memberNames = snapshot.data ?? {};
                  return Column(
                    children: widget.group.members.map((memberId) {
                      final displayName = memberNames[memberId] ?? memberId;
                      return CheckboxListTile(
                        title: Text(displayName),
                        value: selectedPayees.contains(memberId),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedPayees.add(memberId);
                            } else {
                              selectedPayees.remove(memberId);
                              amounts.remove(memberId);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: splitMethod,
                items: const [
                  DropdownMenuItem(value: 'equal', child: Text('Split Equally')),
                  DropdownMenuItem(value: 'unequal', child: Text('Split Unequally')),
                ],
                onChanged: (val) => setState(() => splitMethod = val ?? 'equal'),
                decoration: const InputDecoration(labelText: 'Split Method'),
              ),
              const SizedBox(height: 16),
              if (splitMethod == 'equal')
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Total Amount'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  onChanged: (val) {
                    final amount = double.tryParse(val) ?? 0.0;
                    setState(() {
                      for (var payee in selectedPayees) {
                        amounts[payee] = amount / (selectedPayees.isEmpty ? 1 : selectedPayees.length);
                      }
                    });
                  },
                ),
              if (splitMethod == 'unequal')
                Column(
                  children: selectedPayees.map((payee) {
                    return TextFormField(
                      decoration: InputDecoration(labelText: 'Amount for $payee'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      initialValue: amounts[payee]?.toStringAsFixed(2) ?? '',
                      onChanged: (val) {
                        setState(() {
                          amounts[payee] = double.tryParse(val) ?? 0.0;
                        });
                      },
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Enter amount';
                        final num? parsed = num.tryParse(val);
                        if (parsed == null) return 'Invalid number';
                        if (parsed < 0) return 'Must be positive';
                        if (!RegExp(r'^\d*\.?\d{0,2}$').hasMatch(val)) return 'Max 2 decimals';
                        return null;
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await FirebaseService().addPurchaseToGroup(
                      groupId: widget.group.id,
                      name: purchaseName,
                      payees: selectedPayees,
                      amounts: amounts,
                      splitMethod: splitMethod,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save Purchase'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
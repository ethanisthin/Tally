import 'package:flutter/material.dart';
import '../services/authentication_service.dart';
import '../services/user_profile_service.dart';

class ProfileScreen extends StatefulWidget {
  ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthenticationService _authService = AuthenticationService();
  final UserProfileService _userService = UserProfileService();

  final _nameController = TextEditingController();
  final _paymentController = TextEditingController();
  bool _editing = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) return const Center(child: Text('Not logged in'));

    return FutureBuilder(
      future: _userService.getUserProfile(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final doc = snapshot.data;
        final data = doc?.data() as Map<String, dynamic>?;
        if (data == null) {
          return const Center(child: Text('No profile data found.'));
        }

        if (!_editing) {
          _nameController.text = data['name'] ?? '';
          _paymentController.text = data['paymentPreference'] ?? '';
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: Icon(_editing ? Icons.save : Icons.edit),
                onPressed: () async {
                  if (_editing) {
                    try {
                      await _userService.updateUserProfile(
                        user.uid,
                        name: _nameController.text,
                        paymentPreference: _paymentController.text,
                      );
                      setState(() {
                        _editing = false;
                        _error = null;
                      });
                    } catch (e) {
                      setState(() => _error = e.toString());
                    }
                  } else {
                    setState(() => _editing = true);
                  }
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${data['email']}'),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  enabled: _editing,
                ),
                TextField(
                  controller: _paymentController,
                  decoration: const InputDecoration(labelText: 'Payment Preference'),
                  enabled: _editing,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
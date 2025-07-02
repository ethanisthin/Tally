import 'package:flutter/material.dart';
import '../services/authentication_service.dart';
import '../services/user_profile_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final AuthenticationService _authService = AuthenticationService();
  final UserProfileService _userService = UserProfileService();
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: () async {
                try {
                  final userCredential = await _authService.registerWithEmail(_emailController.text, _passwordController.text);
                  await _userService.createUserProfile(
                    userCredential.user!,
                    name: _nameController.text,
                  );
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                } catch (e) {
                  setState(() => _error = e.toString());
                }
              },
              child: const Text('Register'),
            ),
            TextButton(onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            }, child: const Text('Have an account? Login')),
          ],
        ),
      ),
    );
  }
}
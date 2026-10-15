import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../state/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),
            Icon(Icons.two_wheeler, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text('KUNBAR Mitra', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
            const Text('Driver & kurir jastip / ojek', textAlign: TextAlign.center),
            const SizedBox(height: 32),
            if (Config.demo)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: const Text('MODE DEMO: Supabase belum diatur. Isi email/password bebas.'),
              ),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, style: const TextStyle(fontSize: 18), decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 16),
            TextField(controller: _pass, obscureText: true, style: const TextStyle(fontSize: 18), decoration: const InputDecoration(labelText: 'Password')),
            if (s.error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(s.error!, style: const TextStyle(color: Colors.red, fontSize: 16))),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: s.loading ? null : () => s.login(_email.text, _pass.text),
              child: s.loading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3)) : const Text('MASUK'),
            ),
          ],
        ),
      ),
    );
  }
}

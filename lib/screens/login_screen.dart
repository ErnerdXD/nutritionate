import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final message = AuthService.instance.takePendingLoginMessage();
      if (mounted && message != null) _showAccountNotFound(message);
    });
  }

  Future<void> _signIn({required bool loginOnly}) async {
    setState(() => _busy = true);
    try {
      await AuthService.instance.signInWithGoogle(loginOnly: loginOnly);
    } on GoogleSignInException catch (error) {
      if (error.code != GoogleSignInExceptionCode.canceled) {
        _showError(error.description ?? 'Google sign-in failed.');
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'nutritionate-account-not-found') {
        if (mounted) {
          final message =
              AuthService.instance.takePendingLoginMessage() ??
              error.message ??
              'This account does not exist yet. Please sign up first.';
          await _showAccountNotFound(message);
        }
      } else {
        _showError(error.message ?? 'Firebase sign-in failed.');
      }
    } catch (_) {
      _showError('Could not sign in. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showAccountNotFound(String message) async {
    if (!mounted) return;
    final signUp = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.person_add_alt_1_outlined),
        title: const Text('No Nutritionate account'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign up'),
          ),
        ],
      ),
    );
    if (signUp == true && mounted) await _signIn(loginOnly: false);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _recover() async {
    await launchUrl(
      Uri.parse('https://accounts.google.com/signin/recovery'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.eco_outlined,
                size: 82,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to Nutritionate',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Scan food labels, understand nutrition, and save preferences securely to your account.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _busy ? null : () => _signIn(loginOnly: false),
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.account_circle_outlined),
                label: const Text('Sign up with Google'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _signIn(loginOnly: true),
                icon: const Icon(Icons.login),
                label: const Text('Log in with Google'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
              TextButton(
                onPressed: _recover,
                child: const Text('Trouble signing in?'),
              ),
              const SizedBox(height: 8),
              Text(
                'Nutritionate uses Google sign-in only. Password recovery is handled securely by Google.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/theme_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _signingOutIncompleteSession = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => ThemeService.instance.apply(darkMode: false),
          );
          return const LoginScreen();
        }
        return FutureBuilder(
          future: ProfileService().load(user),
          builder: (context, onboarding) {
            if (onboarding.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final preferences = onboarding.data;
            if (preferences?.onboardingComplete == true) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => ThemeService.instance.apply(
                  darkMode: preferences!.darkMode,
                ),
              );
              return const HomeScreen();
            }
            if (!AuthService.instance.signedInDuringThisRun) {
              if (!_signingOutIncompleteSession) {
                _signingOutIncompleteSession = true;
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await AuthService.instance.signOut();
                  if (mounted) {
                    setState(() => _signingOutIncompleteSession = false);
                  }
                });
              }
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return OnboardingScreen(user: user);
          },
        );
      },
    );
  }
}

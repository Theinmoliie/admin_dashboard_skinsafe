import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the first build is complete
    // before attempting any navigation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirect();
    });
  }

  Future<void> _redirect() async {
    // A short delay to allow Supabase to initialize its session
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      // If there's a session, check if the user is an admin
      final isAdmin = await _authService.isAdmin();
      if (isAdmin && mounted) {
        // If they are an admin, go to the dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        // If not an admin, sign them out and go to the login screen
        await Supabase.instance.client.auth.signOut();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      // If there is no session, go to the login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // A simple loading screen UI
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }
}
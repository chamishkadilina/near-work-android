import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:nearwork/features/auth/providers/auth_provider.dart';
import 'package:nearwork/features/auth/screens/login_screen.dart';
import 'package:nearwork/features/explore/providers/job_provider.dart';
import 'package:nearwork/features/profile/providers/profile_provider.dart';
import 'package:nearwork/core/navigation/navigation_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp();
  runApp(const NearWorkApp());
}

class NearWorkApp extends StatelessWidget {
  const NearWorkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // If authenticated, show NavBar (home)
    if (authProvider.isAuthenticated) {
      return const NavBar();
    }

    // If not authenticated, show LoginScreen
    return const LoginScreen();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/app.dart';

Future<void> main() async {
  print("🚀 [DEBUG] APP BOOTING...");
  WidgetsFlutterBinding.ensureInitialized();
  try {
    print("🚀 [DEBUG] STARTING FIREBASE...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("🚀 [DEBUG] FIREBASE INITIALIZED!");
  } catch (e) {
    debugPrint("Firebase Init Error: $e");
  }
  runApp(
    const ProviderScope(
      child: SocietyApp(),
    ),
  );
}

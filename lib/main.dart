import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
// import 'screens/forgot_password_screen.dart';
// import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
// import 'screens/classification_screen.dart';
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   if (kIsWeb) {
//     await Firebase.initializeApp(
//       options: FirebaseOptions(
//         apiKey: "AIzaSyA3e-v7vugeIJ4_G1kEq4BjaRZRTZ2ykLI",
//         authDomain: "finance-58867.firebaseapp.com",
//         projectId: "finance-58867",
//         storageBucket: "finance-58867.firebasestorage.app",
//         messagingSenderId: "493447811499",
//         appId: "1:493447811499:web:54202fe1a3834c2e37c2ee",
//         measurementId: "G-YFY58TXTME",
//       ),
//     );
//     runApp(FinanceGPTApp());
//   } else {
//     try {
//       await Firebase.initializeApp();

//       // Enable Firebase App Check
//       await FirebaseAppCheck.instance.activate(
//         webProvider: ReCaptchaV3Provider('6Ld6QgkrAAAAAA-5RhTyRMlJeIU9Awn2FlB6Ws5H'),
//         androidProvider: AndroidProvider.playIntegrity, // Or use SafetyNet if needed
//         appleProvider: AppleProvider.deviceCheck,
//       );
//     } catch (e) {
//       print("Firebase initialization error: $e");
//     } finally {
//       runApp(FinanceGPTApp());
//     }
//   }
// }
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // await Firebase.initializeApp(
    //   options: FirebaseOptions(
    //     apiKey: "AIzaSyA3e-v7vugeIJ4_G1kEq4BjaRZRTZ2ykLI",
    //     authDomain: "finance-58867.firebaseapp.com",
    //     projectId: "finance-58867",
    //     storageBucket: "finance-58867.firebasestorage.app",
    //     messagingSenderId: "493447811499",
    //     appId: "1:493447811499:web:54202fe1a3834c2e37c2ee",
    //     measurementId: "G-YFY58TXTME",
    //   ),
    // );
    await Firebase.initializeApp();  // ✅ CORRECT for Android
    if (!kIsWeb) {
      // Enable Firebase App Check
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      );
    }

    runApp(FinanceGPTApp());
  } catch (e) {
    print("Firebase initialization error: $e");
  }
}


class FinanceGPTApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance GPT',
      debugShowCheckedModeBanner: false,
      // debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Using named routes for convenience
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
      },
    );
  }
}
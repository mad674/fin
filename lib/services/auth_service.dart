import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Twilio credentials (store these securely)
  static String _twilioAccountSid = 'AC57eb1405e42bc6400350981888b251a2';
  static String _twilioAuthToken = '739764ec6ead1dcde8d73e854bdc419f';
  static String _twilioPhoneNumber = '+16199276298';
  
  // Use a flag to control debug mode for OTP sending.
  static bool debugMode = false;
  
  // Store verification codes for OTPs
  static Map<String, String> _verificationCodes = {};

  /// Check internet connectivity.
  static Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Send OTP to phone using Twilio SMS API.
  static Future<bool> sendOTP(String phone) async {
    try {
      bool hasConnectivity = await _checkConnectivity();
      if (!hasConnectivity) {
        print("No internet connection available");
        return false;
      }
      
      // Generate a random 6-digit OTP.
      String otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      String formattedPhone = "+91$phone"; // adjust country code if needed
      _verificationCodes[formattedPhone] = otp;
      
      if (debugMode) {
        print("DEBUG MODE: OTP for $formattedPhone is $otp");
        return true;
      }
      
      final String url = 'https://api.twilio.com/2010-04-01/Accounts/$_twilioAccountSid/Messages.json';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_twilioAccountSid:$_twilioAuthToken'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': _twilioPhoneNumber,
          'To': formattedPhone,
          'Body': 'Your Finance GPT verification code is: $otp',
        },
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 201) {
        print("OTP sent to $formattedPhone");
        return true;
      } else {
        print("Error sending OTP: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error in sendOTP: $e");
      return false;
    }
  }

  /// Send OTP via email using Mailgun.
  static Future<bool> sendEmailOTP(String email) async {
    try {
      bool hasConnectivity = await _checkConnectivity();
      if (!hasConnectivity) {
        print("No internet connection available");
        return false;
      }
      
      String otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      _verificationCodes[email] = otp;
      
      if (debugMode) {
        print("DEBUG MODE: OTP for $email is $otp");
        return true;
      }
      
      // Replace with your Mailgun details:
      final String domain = 'sandboxed978122d5b44a6f9fbca83f580a2552.mailgun.org'; // e.g., mg.yourdomain.com
      final String apiKey = '8fb5762e7d424f3a05a7f35bd34d2e1d-24bda9c7-667bc0df';
      final String url = 'https://api.mailgun.net/v3/$domain/messages';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('api:$apiKey'))}',
        },
        body: {
          'from': 'Finance GPT <mailgun@$domain>',
          'to': email,
          'subject': 'Your Finance GPT Verification Code',
          'text': 'Your verification code is: $otp',
        },
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        print("Email OTP sent to $email via Mailgun");
        return true;
      } else {
        print("Error sending email OTP via Mailgun: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error in sendEmailOTP (Mailgun): $e");
      return false;
    }
  }

  /// Verify phone OTP.
  static Future<bool> verifyPhoneOTP(String phone, String otp) async {
    try {
      String formattedPhone = "+91$phone";
      if (_verificationCodes[formattedPhone] == otp) {
        _verificationCodes.remove(formattedPhone);
        return true;
      }
      print("Verification failed for $formattedPhone. Provided OTP: $otp, Expected: ${_verificationCodes[formattedPhone]}");
      return false;
    } catch (e) {
      print("Error in verifyPhoneOTP: $e");
      return false;
    }
  }

  /// Verify email OTP.
  static Future<bool> verifyEmailOTP(String email, String otp) async {
    try {
      if (_verificationCodes[email] == otp) {
        _verificationCodes.remove(email);
        return true;
      }
      print("Verification failed for $email.");
      return false;
    } catch (e) {
      print("Error in verifyEmailOTP: $e");
      return false;
    }
  }

  /// Register a new user (Firebase throws if email already exists).
  static Future<UserCredential?> registerUser({
    required String email,
    required String password,
    required String phone,
    bool phoneVerified = false,
    bool emailVerified = false,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      try {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'phone': phone,
          'emailVerified': emailVerified,
          'phoneVerified': phoneVerified,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (fireError) {
        print("Warning: Firestore write failed: $fireError");
      }
      return userCredential;
    } catch (e) {
      print("Error in registerUser: $e");
      return null;
    }
  }

  /// Login using email and password.
  static Future<UserCredential?> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print("Error in login: $e");
      return null;
    }
  }

  /// Send password reset email.
  static Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print("Error in sendPasswordResetEmail: $e");
      return false;
    }
  }

  /// Update the current user's password.
  static Future<bool> updatePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        return true;
      }
      print("No user logged in for updating password.");
      return false;
    } catch (e) {
      print("Error in updatePassword: $e");
      return false;
    }
  }


  static Future<bool> linkEmailPassword(String email, String password) async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Check if the user is already linked with the email/password provider
      final providerData = currentUser.providerData;
      for (var info in providerData) {
        if (info.providerId == 'password') {
          print('Email/password is already linked.');
          return true; // The email/password is already linked
        }
      }

      final credential = EmailAuthProvider.credential(email: email, password: password);
      await currentUser.linkWithCredential(credential);
      print('Email/password linked successfully.');
      return true;
    } else {
      print('No user logged in for linking email.');
      return false;
    }
  } catch (e) {
    print('Error linking: ${e.toString()}');
    return false;
  }
}


}

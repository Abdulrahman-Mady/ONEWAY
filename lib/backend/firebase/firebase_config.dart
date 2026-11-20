import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyAjpW45nLhRkARGAc2F2EG6IkCzgsX3ppY",
            authDomain: "oneway-f665d.firebaseapp.com",
            projectId: "oneway-f665d",
            storageBucket: "oneway-f665d.firebasestorage.app",
            messagingSenderId: "977208268825",
            appId: "1:977208268825:web:15c7a1a1a711b0a8b07288",
            measurementId: "G-LXMNTNBQ4H"));
  } else {
    await Firebase.initializeApp();
  }
}

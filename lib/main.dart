import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:merchant_app/AllScreens/loginScreen.dart';
import 'package:merchant_app/AllScreens/mainscreen.dart';
import 'package:merchant_app/AllScreens/registrationScreen.dart';
import 'package:merchant_app/DataHandler/appData.dart';
import 'package:provider/provider.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

DatabaseReference usersRef = FirebaseDatabase.instance.reference().child("users");

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppData(),
      child: MaterialApp(
        title: 'Merchant App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: FirebaseAuth.instance.currentUser == null ? LoginScreen.idScreen : MainScreen.idScreen,
        routes: {
          RegistrationScreen.idScreen: (context) =>  RegistrationScreen(),
          LoginScreen.idScreen: (context) =>  LoginScreen(),
          MainScreen.idScreen: (context) =>  MainScreen(),
        },
      ),
    );
  }
}



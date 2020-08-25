import 'package:flashchat/screen/chat_screen.dart';
import 'package:flashchat/screen/home_screen.dart';
import 'package:flashchat/screen/login_screen.dart';
import 'package:flashchat/screen/settings_screen.dart';
import 'package:flutter/material.dart';

void main() async {
//  Injector.configure(Flavor.PROD);
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      //home: HomeScreen(),
      initialRoute: 'login_screen',
      routes: {
        'login_screen': (context) => LoginScreen(),
        'home_screen': (context) => HomeScreen(),
        'chat_screen': (context) => ChatScreen(),
        'settings_screen': (context) => SettingsScreen(),
      },
    );
  }
}
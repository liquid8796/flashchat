import 'dart:convert';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flashchat/const.dart';
import 'package:flashchat/screen/home_screen.dart';
import 'package:flashchat/widget/loading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {

  @override
  _LoginScreenState createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String email;
  String password;

  bool isLoading = false;
  bool isLoggedIn = false;
  FirebaseUser currentUser;
  SharedPreferences prefs;

  bool validate(){
    final FormState form = _formKey.currentState;
    if(form.validate()){
      return true;
    }else{
      return false;
    }
  }

  void validateAndSubmit() async {
    if(validate()){
      try{
        checkLogin(email, password);
      }catch(e){
        print(e);
      }
    }
  }

  String isLogin = "";
  Future<String> checkLogin(String email, String password) async {
    print('email= '+email);
    print('password= '+password);
    String info = "email="+email+"&password="+password;
    var response = await http.post(
      Uri.encodeFull("https://flashchat8796.azurewebsites.net/api/app/login?"+info),
      headers: {"Content-Type": "application/json"},
    );
    isLogin = jsonDecode(response.body).toString();
    print("user="+isLogin.toString());

    if(isLogin != "failed"){
      Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(currentUserId: isLogin)));
      return isLogin;
    }
    else{
      Fluttertoast.showToast(msg: "Wrong username or password");
    }
    return null;
  }

  void isSignedIn() async {
    this.setState(() {
      isLoading = true;
    });

    prefs = await SharedPreferences.getInstance();

    isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(currentUserId: prefs.getString('id'))),
      );
    }

    this.setState(() {
      isLoading = false;
    });
  }
  Future<Null> handleSignIn() async {
    prefs = await SharedPreferences.getInstance();

    this.setState(() {
      isLoading = true;
    });

    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    FirebaseUser firebaseUser = (await firebaseAuth.signInWithCredential(credential)).user;

    if (firebaseUser != null) {
      // Check is already sign up
      final QuerySnapshot result =
      await Firestore.instance.collection('users').where('id', isEqualTo: firebaseUser.uid).getDocuments();
      final List<DocumentSnapshot> documents = result.documents;
      if (documents.length == 0) {
        // Update data to server if new user
        Firestore.instance.collection('users').document(firebaseUser.uid).setData({
          'nickname': firebaseUser.displayName,
          'photoUrl': firebaseUser.photoUrl,
          'id': firebaseUser.uid,
          'createdAt': DateTime.now().toString(),
          'chattingWith': null
        });

        // Write data to local
        currentUser = firebaseUser;
        await prefs.setString('id', currentUser.uid);
        await prefs.setString('nickname', currentUser.displayName);
        await prefs.setString('photoUrl', currentUser.photoUrl);
      } else {
        // Write data to local
        await prefs.setString('id', documents[0]['id']);
        await prefs.setString('nickname', documents[0]['nickname']);
        await prefs.setString('photoUrl', documents[0]['photoUrl']);
        await prefs.setString('aboutMe', documents[0]['aboutMe']);
      }
      Fluttertoast.showToast(msg: "Sign in success");
      this.setState(() {
        isLoading = false;
      });

      Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(currentUserId: firebaseUser.uid)));
    } else {
      Fluttertoast.showToast(msg: "Sign in fail");
      this.setState(() {
        isLoading = false;
      });
    }
  }
  @override
  void initState() {
    super.initState();
    isSignedIn();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 100.0),
                    Stack(

                      children: <Widget>[
                        Positioned(
                          left: 20.0,
                          top: 15.0,
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.yellow,
                                borderRadius: BorderRadius.circular(20.0)
                            ),
                            width: 70.0,
                            height: 20.0,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 32.0),
                          child: Text(
                            "Sign In",
                            style:
                            TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30.0),
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 8.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: "Email", hasFloatingPlaceholder: true),
                        onChanged: (value){
                          email = value;
                        },
                      ),
                    ),
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 8.0),
                      child: TextFormField(
                        obscureText: true,
                        decoration: InputDecoration(
                            labelText: "Password", hasFloatingPlaceholder: true),
                        onChanged: (value){
                          password = value;
                        },
                      ),
                    ),
                    Container(
                        padding: const EdgeInsets.only(right: 16.0),
                        alignment: Alignment.centerRight,
                        child: Text("Forgot your password?")),
                    const SizedBox(height: 120.0),
                    Align(
                      alignment: Alignment.centerRight,
                      child: RaisedButton(
                        padding: const EdgeInsets.fromLTRB(40.0, 16.0, 30.0, 16.0),
                        color: Colors.yellow,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30.0),
                                bottomLeft: Radius.circular(30.0))),
                        onPressed: () {
                          validateAndSubmit();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              "Sign In".toUpperCase(),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16.0),
                            ),
                            const SizedBox(width: 40.0),
                            Icon(
                              FontAwesomeIcons.arrowRight,
                              size: 18.0,
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 50.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        OutlineButton.icon(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 30.0,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0)),
                          borderSide: BorderSide(color: Colors.red),
                          color: Colors.red,
                          highlightedBorderColor: Colors.red,
                          textColor: Colors.red,
                          icon: Icon(
                            FontAwesomeIcons.googlePlusG,
                            size: 18.0,
                          ),
                          label: Text("Google"),
                          onPressed: () {
                            handleSignIn();
                          },
                        ),
                        const SizedBox(width: 10.0),
                        OutlineButton.icon(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 30.0,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0)),
                          highlightedBorderColor: Colors.indigo,
                          borderSide: BorderSide(color: Colors.indigo),
                          color: Colors.indigo,
                          textColor: Colors.indigo,
                          icon: Icon(
                            FontAwesomeIcons.facebookF,
                            size: 18.0,
                          ),
                          label: Text("Facebook"),
                          onPressed: () {},
                        ),

                      ],
                    )
                  ],
                ),
              )
          ),
          Positioned(
            child: isLoading ? const Loading() : Container(),
          ),
        ],
      ),
    );
  }
}


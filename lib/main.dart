import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future signIn() async {
    final user = await GoogleSignInApi.logIn();
    if (user != null) {
      setState(() {
        data = user;
      });
    }
  }

  Future signOut() async {
    await GoogleSignInApi.logOut();
    setState(() {
      data = null;
    });
  }

  User? data;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Material App Bar'),
        ),
        body: Center(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            data != null ? Text(data!.name) : SizedBox.shrink(),
            ButtonBar(
              children: [
                TextButton(
                    onPressed: () async {
                      try {
                        if (data != null) {
                          await signOut();
                        }
                        await signIn();
                      } catch (e) {
                        print("Error login google $e");
                      }
                    },
                    child: Text("Login google")),
                TextButton(
                    onPressed: () async {
                      var result =
                          await FacebookImplementation().loginFacebook();
                      if (result is User) {
                        setState(() {
                          data = result;
                        });
                      }
                    },
                    child: Text("Login facebook")),
                TextButton(
                    onPressed: () {
                      FacebookImplementation.shareToFacebook(
                          'Hola', 'https://www.example.com');
                    },
                    child: Text("Share facebook")),
                TextButton(
                    onPressed: () {
                      TwitterImplementation.shareToTwitter(
                          'Hola', 'https://www.example.com');
                    },
                    child: Text("Share twitter"))
              ],
            ),
          ],
        )),
      ),
    );
  }
}

class TwitterImplementation {
  static const MethodChannel _channelShare = MethodChannel('twitter_share');

  static Future<void> shareToTwitter(String text, String url) async {
    try {
      final result = await _channelShare
          .invokeMethod('shareToTwitter', {'text': text, 'url': url});
      print(result);
    } on PlatformException catch (e) {
      print("Failed to share to Twitter: '${e.message}'.");
    }
  }
}

class FacebookImplementation {
  static const MethodChannel _channelShare = MethodChannel('facebook_share');
  static const MethodChannel _channelLogin = MethodChannel('facebook_auth');

  static Future<void> shareToFacebook(String text, String url) async {
    try {
      final result = await _channelShare
          .invokeMethod('shareToFacebook', {'text': text, 'url': url});
      print(result);
    } on PlatformException catch (e) {
      print("Failed to share to Facebook: '${e.message}'.");
    }
  }

  Future loginFacebook() async {
    try {
      final result = await _channelLogin.invokeMethod('loginToFacebook');
      return getUserData(result["token"]);
    } on PlatformException catch (e) {
      print("Failed to login to Facebook: '${e.message}'.");
    }
  }

  Future<User?> getUserData(String accessToken) async {
    final url = Uri.parse(
        'https://graph.facebook.com/v12.0/me?fields=name,email,id&access_token=$accessToken');
    final response = await http.get(url);
    print(response.body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User(email: data['email'], name: data['name'], id: data['id']);
    }
    return null;
  }
}

class User {
  final String email;
  final String name;
  final String id;

  User({required this.email, required this.name, required this.id});
}

class GoogleSignInApi {
  static final _googleSignIn = GoogleSignIn();

  static Future logIn() async {
    await _googleSignIn.signIn();

    return User(
      email: _googleSignIn.currentUser!.email,
      id: _googleSignIn.currentUser!.id,
      name: _googleSignIn.currentUser!.displayName!,
    );
  }

  static Future logOut() => _googleSignIn.disconnect();
}

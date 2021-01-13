import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../main.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // InAppWebViewController webView;
  WebViewController _controller;
  GoogleSignIn _googleSignIn = GoogleSignIn();
  FirebaseAuth _auth;
  User _user;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  Future loginWithGoogle() async {
    FirebaseApp defaultApp = await Firebase.initializeApp();
    _auth = FirebaseAuth.instanceFor(app: defaultApp);
    // await _auth.signOut();
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    if (googleUser != null) {
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      _user = (await _auth.signInWithCredential(credential)).user;
      // await firebaseUser.reload();
      Logger().e(_user);
      String url =
          EnvironmentConfig.MAIN_URL + "/user/GoogleLogin?Email=" +
              _user.email.toString() +
              "&Name=" +
              _user.displayName.toString() +
              "&UID=" +
              _user.uid.toString();
      Logger().e(url);
      _controller.loadUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          String curUrl = await _controller.currentUrl();
          if (curUrl.endsWith("HomeKas") || curUrl.endsWith("ListLaporan") || curUrl.endsWith("prfl") || curUrl.endsWith("user/login")) {
            return Future.value(true);
          } else {
            _controller.goBack();
          }
        } else {
          return Future.value(true);
        }
      },
      child: SafeArea(
        child: Scaffold(
          body: WebView(
            debuggingEnabled: true,
            userAgent: "tes",
            javascriptMode: JavascriptMode.unrestricted,
            initialUrl: EnvironmentConfig.MAIN_URL,
            // initialUrl: 'http://mgbix.id:82/kas',
            // initialUrl: "https://accounts.google.com/o/oauth2/auth?redirect_uri=storagerelay%3A%2F%2Fhttp%2Fmgbix.id%3A82%3Fid%3Dauth592590&response_type=permission%20id_token&scope=email%20profile%20openid&openid.realm=&client_id=946006633307-s6nsfgokc8tn28pti2lmldtk7iiduo1b.apps.googleusercontent.com&ss_domain=http%3A%2F%2Fmgbix.id%3A82&fetch_basic_profile=true&gsiwebsdk=2",
            onWebViewCreated: (WebViewController webViewController) {
              _controller = webViewController;
            },
            navigationDelegate: (NavigationRequest request) {
              if (request.url.startsWith('https://accounts.google.com/')) {
                loginWithGoogle();
                return NavigationDecision.prevent;
              }
              print('allowing navigation to $request');
              return NavigationDecision.navigate;
            },
          ),
        ),
      ),
    );
  }
}

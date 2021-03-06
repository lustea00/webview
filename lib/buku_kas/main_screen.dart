import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_open_whatsapp/flutter_open_whatsapp.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
// import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../main.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // InAppWebViewController webView;
  InAppWebViewController _controller;
  GoogleSignIn _googleSignIn = GoogleSignIn();
  FirebaseAuth _auth;
  User _user;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  sendWhatsApp(String url) {
    try {
      String phone = url.split("=")[1];
      FlutterOpenWhatsapp.sendSingleMessage(phone, "");
    } catch (_) {
      Fluttertoast.showToast(
          msg: _.toString(),
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  Future loginWithGoogle() async {
    FirebaseApp defaultApp = await Firebase.initializeApp();
    _auth = FirebaseAuth.instanceFor(app: defaultApp);
    // await _auth.signOut();
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
        _user = (await _auth.signInWithCredential(credential)).user;
        // await firebaseUser.reload();
        Logger().e(_user);
        String url = EnvironmentConfig.MAIN_URL +
            "/user/GoogleLogin?Email=" +
            _user.email.toString() +
            "&Name=" +
            _user.displayName.toString() +
            "&UID=" +
            _user.uid.toString();
        Logger().e(url);
        _controller.loadUrl(url: url);
      }
    } catch (_) {
      Fluttertoast.showToast(
          msg: _.toString(),
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          String curUrl = await _controller.getUrl();
          if (curUrl.endsWith("HomeKas") ||
              curUrl.endsWith("ListLaporan") ||
              curUrl.endsWith("prfl") ||
              curUrl.endsWith("user/login")) {
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
          body: InAppWebView(
            initialUrl: EnvironmentConfig.MAIN_URL,
            // initialUrl: 'http://mgbix.id:82/kas',
            // initialUrl: "https://accounts.google.com/o/oauth2/auth?redirect_uri=storagerelay%3A%2F%2Fhttp%2Fmgbix.id%3A82%3Fid%3Dauth592590&response_type=permission%20id_token&scope=email%20profile%20openid&openid.realm=&client_id=946006633307-s6nsfgokc8tn28pti2lmldtk7iiduo1b.apps.googleusercontent.com&ss_domain=http%3A%2F%2Fmgbix.id%3A82&fetch_basic_profile=true&gsiwebsdk=2",
            // initialOptions: InAppWebViewGroupOptions(
            //   crossPlatform: InAppWebViewOptions(
            //     debuggingEnabled: true,
            //   )
            // ),
            // debuggingEnabled: true,
            // userAgent: "tes",
            // javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (InAppWebViewController webViewController) {
              _controller = webViewController;
            },
            onLoadStart: (InAppWebViewController controller, String url) {
              if (url.startsWith('https://accounts.google.com/')) {
                loginWithGoogle();
                controller.stopLoading();
              }
              if (url.startsWith("https://api.whatsapp.com/send/")) {
                sendWhatsApp(url);
                controller.stopLoading();
              }
            },
            // navigationDelegate: (NavigationRequest request) {
            //   if (request.url.startsWith('https://accounts.google.com/')) {
            //     loginWithGoogle();
            //     return NavigationDecision.prevent;
            //   }
            //   if (request.url.startsWith("https://api.whatsapp.com/send/")) {
            //     sendWhatsApp(request.url);
            //     return NavigationDecision.prevent;
            //   }
            //   return NavigationDecision.navigate;
            // },
          ),
        ),
      ),
    );
  }
}

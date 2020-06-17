import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fyx/PlatformAwareWidget.dart';
import 'package:fyx/PlatformThemeData.dart';
import 'package:fyx/pages/AboutPage.dart';
import 'package:fyx/pages/DiscussionPage.dart';
import 'package:fyx/pages/GalleryPage.dart';
import 'package:fyx/pages/HomePage.dart';
import 'package:fyx/pages/LoginPage.dart';
import 'package:fyx/pages/NewMessagePage.dart';
import 'package:fyx/pages/SettingsPage.dart';
import 'package:fyx/pages/TutorialPage.dart';

class PlatformApp extends PlatformAwareWidget<MaterialApp, CupertinoApp> {
  final Widget home;
  final String title;
  final PlatformThemeData theme;
  final bool debugShowCheckedModeBanner;
  final List<NavigatorObserver> listNavigatorObservers;
  static GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();

  PlatformApp({this.home, this.title, this.theme, this.debugShowCheckedModeBanner, this.listNavigatorObservers});

  @override
  MaterialApp createAndroidWidget(BuildContext context) {
    return MaterialApp(
      home: this.home,
      title: this.title,
      theme: this.theme?.material(),
      debugShowCheckedModeBanner: this.debugShowCheckedModeBanner,
      onGenerateRoute: routes,
      navigatorKey: navigatorKey,
      navigatorObservers: listNavigatorObservers,
    );
  }

  @override
  CupertinoApp createCupertinoWidget(BuildContext context) {
    return CupertinoApp(
      home: this.home,
      title: this.title,
      theme: this.theme?.cupertino(),
      debugShowCheckedModeBanner: this.debugShowCheckedModeBanner,
      onGenerateRoute: routes,
      onUnknownRoute: (RouteSettings settings) => CupertinoPageRoute(builder: (_) => DiscussionPage(), settings: settings),
      navigatorKey: navigatorKey,
      navigatorObservers: listNavigatorObservers,
    );
  }

  Route routes(RouteSettings settings) {
    switch (settings.name) {
      case '/token':
        print('[Router] Token');
        return CupertinoPageRoute(builder: (_) => TutorialPage(), settings: settings);
      case '/home':
        print('[Router] Homepage');
        return CupertinoPageRoute(builder: (_) => HomePage(), settings: settings);
      case '/login':
        print('[Router] Login');
        return CupertinoPageRoute(builder: (_) => LoginPage(), settings: settings);
      case '/discussion':
        print('[Router] Discussion');
        return CupertinoPageRoute(builder: (_) => DiscussionPage(), settings: settings);
      case '/new-message':
        print('[Router] New Message');
        return CupertinoPageRoute(builder: (_) => NewMessagePage(), settings: settings, fullscreenDialog: true);
      case '/gallery':
        print('[Router] Gallery');
        return PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 0), opaque: false, pageBuilder: (_, __, ___) => GalleryPage(), settings: settings, fullscreenDialog: true);
      case '/settings':
        print('[Router] Settings');
        return CupertinoPageRoute(builder: (_) => SettingsPage(), settings: settings);
      case '/settings/about':
        print('[Router] Settings / About');
        return CupertinoPageRoute(builder: (_) => AboutPage(), settings: settings);
      default:
        print('[Router] Discussion');
        return CupertinoPageRoute(builder: (_) => DiscussionPage(), settings: settings);
    }
  }
}

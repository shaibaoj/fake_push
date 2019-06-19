import 'dart:async';
import 'dart:io';

import 'package:fake_push/fake_push.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runZoned(() {
    runApp(MyApp());
  }, onError: (Object error, StackTrace stack) {
    print(error);
    print(stack);
  });

  if (Platform.isAndroid) {
    SystemUiOverlayStyle systemUiOverlayStyle =
        const SystemUiOverlayStyle(statusBarColor: Colors.transparent);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomeState();
  }
}

class _HomeState extends State<Home> {
  Push _push = Push()..registerApp();

  StreamSubscription<String> _registeredDeviceToken;
  StreamSubscription<Message> _message;
  StreamSubscription<Message> _notification;
  StreamSubscription<Message> _launchNotification;
  StreamSubscription<Message> _resumeNotification;

  @override
  void initState() {
    super.initState();
    _push.startWork(enableDebug: !_isReleaseMode());
    _push.areNotificationsEnabled().then((bool isEnabled) {
      if (!isEnabled) {
        _push.requestNotificationsPermission();
      }
    });

    _registeredDeviceToken =
        _push.registeredDeviceToken().listen(_handleRegisteredDeviceToken);
    _message = _push.message().listen(_handleMessage);
    _notification = _push.notification().listen(_handleNotification);
    _launchNotification =
        _push.launchNotification().listen(_handleLaunchNotification);
    _resumeNotification =
        _push.resumeNotification().listen(_handleResumeNotification);
  }

  @override
  void dispose() {
    if (_registeredDeviceToken != null) {
      _registeredDeviceToken.cancel();
    }
    if (_message != null) {
      _message.cancel();
    }
    if (_notification != null) {
      _notification.cancel();
    }
    if (_launchNotification != null) {
      _launchNotification.cancel();
    }
    if (_resumeNotification != null) {
      _resumeNotification.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fake Push Demo'),
      ),
      body: Center(
        child: GestureDetector(
          child: Text('${Platform.operatingSystem}'),
          onTap: () {},
        ),
      ),
    );
  }

  void _handleRegisteredDeviceToken(String deviceToken) {
    print('deviceToken: $deviceToken');
  }

  void _handleMessage(Message message) {
    print(
        'message: ${message.title} - ${message.content} - ${message.customContent}');
  }

  void _handleNotification(Message notification) {
    print(
        'notification: ${notification.title} - ${notification.content} - ${notification.customContent}');
  }

  void _handleLaunchNotification(Message notification) {
    print(
        'launchNotification: ${notification.title} - ${notification.content} - ${notification.customContent}');
  }

  void _handleResumeNotification(Message notification) {
    print(
        'resumeNotification: ${notification.title} - ${notification.content} - ${notification.customContent}');
  }

  bool _isReleaseMode() {
    return const bool.fromEnvironment('dart.vm.product');
  }
}

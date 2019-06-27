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

  StreamSubscription<String> _receiveDeviceToken;
  StreamSubscription<Message> _receiveMessage;
  StreamSubscription<Message> _receiveNotification;
  StreamSubscription<Message> _launchNotification;
  StreamSubscription<Message> _resumeNotification;

  @override
  void initState() {
    super.initState();
    _receiveDeviceToken =
        _push.receiveDeviceToken().listen(_handleReceiveDeviceToken);
    _receiveMessage = _push.receiveMessage().listen(_handleReceiveMessage);
    _receiveNotification =
        _push.receiveNotification().listen(_handleReceiveNotification);
    _launchNotification =
        _push.launchNotification().listen(_handleLaunchNotification);
    _resumeNotification =
        _push.resumeNotification().listen(_handleResumeNotification);

    _push.startWork(enableDebug: !_isReleaseMode());
    _push.areNotificationsEnabled().then((bool isEnabled) {
      if (!isEnabled) {
        _push.openNotificationsSettings();
      }
    });
  }

  @override
  void dispose() {
    if (_receiveDeviceToken != null) {
      _receiveDeviceToken.cancel();
    }
    if (_receiveMessage != null) {
      _receiveMessage.cancel();
    }
    if (_receiveNotification != null) {
      _receiveNotification.cancel();
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

  void _handleReceiveDeviceToken(String deviceToken) async {
    print('deviceToken: $deviceToken - ${await _push.getDeviceToken()}');
  }

  void _handleReceiveMessage(Message message) {
    print(
        'message: ${message.title} - ${message.content} - ${message.customContent}');
  }

  void _handleReceiveNotification(Message notification) {
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

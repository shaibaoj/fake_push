import 'dart:async';

import 'package:fake_push/src/domain/message.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

class Push {
  static const String _METHOD_ARENOTIFICATIONSENABLED =
      'areNotificationsEnabled';
  static const String _METHOD_REQUESTNOTIFICATIONSPERMISSION =
      'requestNotificationsPermission';
  static const String _METHOD_STARTWORK = 'startWork';
  static const String _METHOD_GETDEVICETOKEN = 'getDeviceToken';
  static const String _METHOD_STOPWORK = 'stopWork';
  static const String _METHOD_BINDACCOUNT = 'bindAccount';
  static const String _METHOD_UNBINDACCOUNT = 'unbindAccount';
  static const String _METHOD_BINDTAGS = 'bindTags';
  static const String _METHOD_UNBINDTAGS = 'unbindTags';

  static const String _METHOD_ONREGISTEREDDEVICETOKEN =
      'onRegisteredDeviceToken';
  static const String _METHOD_ONMESSAGE = 'onMessage';
  static const String _METHOD_ONNOTIFICATION = 'onNotification';
  static const String _METHOD_ONLAUNCHNOTIFICATION = 'onLaunchNotification';
  static const String _METHOD_ONRESUMENOTIFICATION = 'onResumeNotification';

  static const String _ARGUMENT_KEY_ENABLEDEBUG = 'enableDebug';
  static const String _ARGUMENT_KEY_ACCOUNT = 'account';
  static const String _ARGUMENT_KEY_TAGS = 'tags';

  final MethodChannel _channel =
      const MethodChannel('v7lin.github.io/fake_push');

  final StreamController<String> _registeredDeviceTokenStreamController =
      StreamController<String>.broadcast();

  final StreamController<Message> _messageStreamController =
      StreamController<Message>.broadcast();

  final StreamController<Message> _notificationStreamController =
      StreamController<Message>.broadcast();

  final StreamController<Message> _launchNotificationStreamController =
      StreamController<Message>.broadcast();

  final StreamController<Message> _resumeNotificationStreamController =
      StreamController<Message>.broadcast();

  Future<void> registerApp() async {
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case _METHOD_ONREGISTEREDDEVICETOKEN:
        _registeredDeviceTokenStreamController.add(call.arguments as String);
        break;
      case _METHOD_ONMESSAGE:
        _messageStreamController.add(MessageSerializer()
            .fromMap(call.arguments as Map<dynamic, dynamic>));
        break;
      case _METHOD_ONNOTIFICATION:
        _notificationStreamController.add(MessageSerializer()
            .fromMap(call.arguments as Map<dynamic, dynamic>));
        break;
      case _METHOD_ONLAUNCHNOTIFICATION:
        _launchNotificationStreamController.add(MessageSerializer()
            .fromMap(call.arguments as Map<dynamic, dynamic>));
        break;
      case _METHOD_ONRESUMENOTIFICATION:
        _resumeNotificationStreamController.add(MessageSerializer()
            .fromMap(call.arguments as Map<dynamic, dynamic>));
        break;
    }
  }

  /// 通知开关是否打开
  Future<bool> areNotificationsEnabled() {
    return _channel.invokeMethod(_METHOD_ARENOTIFICATIONSENABLED);
  }

  /// 请求打开通知开关
  Future<void> requestNotificationsPermission() {
    return _channel.invokeMethod(_METHOD_REQUESTNOTIFICATIONSPERMISSION);
  }

  /// 开始推送
  Future<void> startWork({
    bool enableDebug = false,
  }) {
    return _channel.invokeMethod(
      _METHOD_STARTWORK,
      <String, dynamic>{
        _ARGUMENT_KEY_ENABLEDEBUG: enableDebug,
      },
    );
  }

  Future<String> getDeviceToken() {
    return _channel
        .invokeMethod(_METHOD_GETDEVICETOKEN)
        .then((dynamic resp) => resp as String);
  }

  /// 接收DeviceToken
  Stream<String> registeredDeviceToken() {
    return _registeredDeviceTokenStreamController.stream;
  }

  /// 停止推送
  Future<void> stopWork() {
    return _channel.invokeMethod(_METHOD_STOPWORK);
  }

  /// 接收透传消息（静默消息）
  Stream<Message> message() {
    return _messageStreamController.stream;
  }

  /// 接收通知消息
  Stream<Message> notification() {
    return _notificationStreamController.stream;
  }

  /// 接收通知栏点击事件 - 后台
  Stream<Message> launchNotification() {
    return _launchNotificationStreamController.stream;
  }

  /// 接收通知栏点击事件 - 前台
  Stream<Message> resumeNotification() {
    return _resumeNotificationStreamController.stream;
  }

  /// 绑定帐号
  Future<void> bindAccount({
    @required String account,
  }) {
    assert(account != null && account.isNotEmpty);
    return _channel.invokeMethod(
      _METHOD_BINDACCOUNT,
      <String, dynamic>{
        _ARGUMENT_KEY_ACCOUNT: account,
      },
    );
  }

  /// 解绑帐号
  Future<void> unbindAccount({
    @required String account,
  }) {
    assert(account != null && account.isNotEmpty);
    return _channel.invokeMethod(
      _METHOD_UNBINDACCOUNT,
      <String, dynamic>{
        _ARGUMENT_KEY_ACCOUNT: account,
      },
    );
  }

  /// 绑定标签
  Future<void> bindTags({
    @required List<String> tags,
  }) {
    assert(tags != null && tags.isNotEmpty);
    return _channel.invokeMethod(
      _METHOD_BINDTAGS,
      <String, dynamic>{
        _ARGUMENT_KEY_TAGS: tags,
      },
    );
  }

  /// 解绑标签
  Future<void> unbindTags({
    @required List<String> tags,
  }) {
    assert(tags != null && tags.isNotEmpty);
    return _channel.invokeMethod(
      _METHOD_UNBINDTAGS,
      <String, dynamic>{
        _ARGUMENT_KEY_TAGS: tags,
      },
    );
  }
}

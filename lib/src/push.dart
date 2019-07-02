import 'dart:async';

import 'package:fake_push/src/domain/message.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

class Push {
  static const String _METHOD_ARENOTIFICATIONSENABLED =
      'areNotificationsEnabled';
  static const String _METHOD_OPENNOTIFICATIONSSETTINGS =
      'openNotificationsSettings';
  static const String _METHOD_STARTWORK = 'startWork';
  static const String _METHOD_STOPWORK = 'stopWork';
  static const String _METHOD_GETDEVICETOKEN = 'getDeviceToken';
  static const String _METHOD_BINDACCOUNT = 'bindAccount';
  static const String _METHOD_UNBINDACCOUNT = 'unbindAccount';
  static const String _METHOD_BINDTAGS = 'bindTags';
  static const String _METHOD_UNBINDTAGS = 'unbindTags';

  static const String _METHOD_ONRECEIVEDEVICETOKEN = 'onReceiveDeviceToken';
  static const String _METHOD_ONRECEIVEMESSAGE = 'onReceiveMessage';
  static const String _METHOD_ONRECEIVENOTIFICATION = 'onReceiveNotification';
  static const String _METHOD_ONLAUNCHNOTIFICATION = 'onLaunchNotification';
  static const String _METHOD_ONRESUMENOTIFICATION = 'onResumeNotification';

  static const String _ARGUMENT_KEY_ENABLEDEBUG = 'enableDebug';
  static const String _ARGUMENT_KEY_ACCOUNT = 'account';
  static const String _ARGUMENT_KEY_TAGS = 'tags';

  final MethodChannel _channel =
      const MethodChannel('v7lin.github.io/fake_push');

  final StreamController<String> _receiveDeviceTokenStreamController =
      StreamController<String>.broadcast();

  final StreamController<Message> _receiveMessageStreamController =
      StreamController<Message>.broadcast();

  final StreamController<Message> _receiveNotificationStreamController =
      StreamController<Message>.broadcast();

  final StreamController<String> _launchNotificationStreamController =
      StreamController<String>.broadcast();

  final StreamController<String> _resumeNotificationStreamController =
      StreamController<String>.broadcast();

  Future<void> registerApp() async {
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case _METHOD_ONRECEIVEDEVICETOKEN:
        _receiveDeviceTokenStreamController.add(call.arguments as String);
        break;
      case _METHOD_ONRECEIVEMESSAGE:
        _receiveMessageStreamController.add(MessageSerializer()
            .fromMap(call.arguments as Map<dynamic, dynamic>));
        break;
      case _METHOD_ONRECEIVENOTIFICATION:
        _receiveNotificationStreamController.add(MessageSerializer()
            .fromMap(call.arguments as Map<dynamic, dynamic>));
        break;
      case _METHOD_ONLAUNCHNOTIFICATION:
        _launchNotificationStreamController.add(call.arguments as String);
        break;
      case _METHOD_ONRESUMENOTIFICATION:
        _resumeNotificationStreamController.add(call.arguments as String);
        break;
    }
  }

  /// 通知开关是否打开
  Future<bool> areNotificationsEnabled() {
    return _channel.invokeMethod(_METHOD_ARENOTIFICATIONSENABLED);
  }

  /// 请求打开通知开关
  Future<void> openNotificationsSettings() {
    return _channel.invokeMethod(_METHOD_OPENNOTIFICATIONSSETTINGS);
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

  /// 停止推送
  Future<void> stopWork() {
    return _channel.invokeMethod(_METHOD_STOPWORK);
  }

  /// 接收DeviceToken
  Stream<String> receiveDeviceToken() {
    return _receiveDeviceTokenStreamController.stream;
  }

  /// 接收透传消息（静默消息）
  /// title 喂狗了，Android 始终为空
  /// 华为通道透传喂狗了 - 请用 content，不要用 customContent
  Stream<Message> receiveMessage() {
    return _receiveMessageStreamController.stream;
  }

  /// 接收通知消息
  /// 慎用 - 华为通道不支持抵达回调
  Stream<Message> receiveNotification() {
    return _receiveNotificationStreamController.stream;
  }

  /// 接收通知栏点击事件 - 后台
  Stream<String> launchNotification() {
    return _launchNotificationStreamController.stream;
  }

  /// 接收通知栏点击事件 - 前台
  Stream<String> resumeNotification() {
    return _resumeNotificationStreamController.stream;
  }

  /// 获取 DeviceToken
  Future<String> getDeviceToken() {
    return _channel.invokeMethod(_METHOD_GETDEVICETOKEN);
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

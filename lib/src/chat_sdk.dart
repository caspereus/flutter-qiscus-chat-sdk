library qiscus_sdk;

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tuple/tuple.dart';

import 'model/qiscus_account.dart';
import 'model/qiscus_chat_room.dart';

export 'model/qiscus_account.dart';
export 'model/qiscus_chat_room.dart';

class ChatSdk {
  static const MethodChannel _channel = const MethodChannel('bahaso.com/qiscus_chat_sdk');

  static Future<void> setup({@required String appId}) {
    dev.log("chat Sdk setup", name: "Qiscus Chat SDK");
    return _channel.invokeMethod('setup', {'appId': appId});
  }

  static Future<void> clearUser() {
    dev.log("chat sdk clearing user", name: "Qiscus Chat SDK");
    return _channel.invokeMethod("clearUser");
  }

  static Future<void> registerDeviceToken(String token) {
    dev.log("chat sdk register device token", name: "Qiscus Chat SDK");
    return _channel.invokeMethod("registerDeviceToken", {"token": token});
  }

  static Future<void> removeDeviceToken(String token) {
    dev.log("chat sdk remove device token", name: "Qiscus Chat SDK");
    return _channel.invokeMethod("removeDeviceToken", {"token": token});
  }

  static Future<void> enableFcmPushNotification(bool value) {
    dev.log("chat sdk enable fcm push notification", name: "Qiscus Chat SDK");
    return _channel.invokeMethod("setEnableFcmPushNotification", {"value": value});
  }

  static Future<void> enableDebugMode(bool value) {
    dev.log("chat sdk enable debug mode", name: "Qiscus Chat SDK");
    return _channel.invokeMethod("enableDebugMode", {"value": value});
  }

  static Future<void> setNotificationListener() {}

  static Future<QiscusAccount> login({
    @required String userId,
    @required String userKey,
    @required String username,
    String avatarUrl: '',
    Map<String, dynamic> extras,
  }) async {
    dev.log("chat sdk login", name: "Qiscus Chat SDK");
    Map<String, dynamic> arguments = _prepareLoginArguments(
      userId: userId,
      userKey: userKey,
      username: username,
      avatarUrl: avatarUrl,
      extras: extras,
    );
    String jsonStr = await _channel.invokeMethod("login", arguments);
    return QiscusAccount.fromJson(jsonDecode(jsonStr));
  }

  static Map<String, dynamic> _prepareLoginArguments({
    @required String userId,
    @required String userKey,
    @required String username,
    String avatarUrl: '',
    Map<String, dynamic> extras,
  }) {
    Map<String, dynamic> arguments = {
      'userId': userId,
      'userKey': userKey,
      'username': username,
    };
    if (avatarUrl != null && avatarUrl != '') arguments['avatarUrl'] = avatarUrl;
    if (extras != null) arguments['extras'] = extras;
    return arguments;
  }

  static Future<QiscusAccount> loginWithJWT(Future<String> getJWTToken(String nonce)) async {
    dev.log("chat sdk loginWithJWT", name: "Qiscus Chat SDK");
    String nonce = await _channel.invokeMethod('getNonce');

    dev.log("sdk before jwt", name: 'Qiscus chat sdk');

    String jwt = await getJWTToken(nonce);

    String jsonStr = await _channel.invokeMethod("setUserWithIdentityToken", {'token': jwt});

    return QiscusAccount.fromJson(jsonDecode(jsonStr));
  }

  static Future<QiscusAccount> updateUser({
    @required String username,
    @required String avatarUrl,
    Map<String, dynamic> extras,
  }) async {
    dev.log("chat sdk updateUser", name: "Qiscus Chat SDK");

    Map<String, dynamic> arguments = {
      'username': username,
      'avatarUrl': avatarUrl,
    };
    if (extras != null) arguments['extras'] = extras;

    String jsonStr = await _channel.invokeMethod('updateUser', arguments);

    return QiscusAccount.fromJson(jsonDecode(jsonStr));
  }

  static Future<bool> hasLogin() {
    return _channel.invokeMethod('hasLogin');
  }

  static Future<List<QiscusAccount>> getAllUsers(
      {String searchUsername: '', int page, int limit}) async {
    List<String> list = await _channel.invokeMethod(
        'getAllUsers', {'searchUsername': searchUsername, 'page': page, 'limit': limit});

    return list.map((jsonStr) {
      return QiscusAccount.fromJson(jsonDecode(jsonStr));
    });
  }

  static Future<QiscusChatRoom> chatUser({
    @required String userId,
    Map<String, dynamic> extras,
  }) async {
    Map<String, dynamic> arguments = {
      'userId': userId,
    };
    if (extras != null) arguments['extras'] = extras;

    String json = await _channel.invokeMethod('chatUser', arguments);

    return QiscusChatRoom.fromJson(jsonDecode(json));
  }

  static Future<bool> addOrUpdateLocalChatRoom(QiscusChatRoom chatRoom) async {
    var args = {'chatRoom': jsonEncode(chatRoom)};
    return await _channel.invokeMethod(
      'addOrUpdateLocalChatRoom',
      args,
    );
  }

  static Future<Tuple2<QiscusChatRoom, List<QiscusComment>>> getChatRoomWithMessages(
      int roomId) async {
    Map<String, String> chatRoomListPairJsonStr = await _channel
        .invokeMapMethod<String, String>('getChatRoomWithMessages', {'roomId': roomId});
    QiscusChatRoom qiscusChatRoom =
        QiscusChatRoom.fromJson(jsonDecode(chatRoomListPairJsonStr['chatRoom']));
    List<QiscusComment> messages =
        (jsonDecode(chatRoomListPairJsonStr['messages']) as List).map((each) {
      return QiscusComment.fromJson(each);
    }).toList();

    return Tuple2(qiscusChatRoom, messages);
  }

  static Future<QiscusChatRoom> getLocalChatRoom(int roomId) async {
    String jsonStr = await _channel.invokeMethod('getLocalChatRoom', {'roomId': roomId});
    Map<String, dynamic> map = jsonDecode(jsonStr);

    return QiscusChatRoom.fromJson(map);
  }

  static Future<List<QiscusChatRoom>> getLocalChatRoomByIds(List<int> roomIds) async {
    String json = await _channel.invokeMethod('getLocalChatRoomByRoomIds', {'roomIds': roomIds});
    return (jsonDecode(json) as List).map((each) {
      return QiscusChatRoom.fromJson(each);
    }).toList();
  }

  static Future<List<QiscusChatRoom>> getAllChatRooms({
    bool showParticipant: true,
    bool showRemoved: false,
    bool showEmpty: false,
    int page: 1,
    int limit: 100,
  }) async {
    String json = await _channel.invokeMethod('getAllChatRooms', {
      'showParticipant': showParticipant,
      'showRemoved': showRemoved,
      'showEmpty': showEmpty,
      'page': page,
      'limit': limit,
    });

    return (jsonDecode(json) as List).map((each) {
      return QiscusChatRoom.fromJson(each);
    }).toList();
  }

  static Future<List<QiscusChatRoom>> getLocalChatRooms({int limit: 100, int offset}) async {
    Map<String, int> arguments = {'limit': limit};
    if (offset != null) arguments['offset'] = offset;
    String json = await _channel.invokeMethod('getLocalChatRooms', arguments);
    dev.log("getlocalhatrooms: $json");

    return (jsonDecode(json) as List).map((each) {
      return QiscusChatRoom.fromJson(each);
    }).toList();
  }

  static Future<int> getTotalUnreadCount() async {
    return await _channel.invokeMethod('getTotalUnreadCount');
  }

  static Future<QiscusComment> sendMessage({
    @required int roomId,
    String message,
    String type,
    File imageFile,
    Map<String, dynamic> extras,
    Map<String, dynamic> payload,
  }) async {
    String caption = "";
    if (type == CommentType.FILE_ATTACHMENT) {
      caption = message;
    } else if (type == CommentType.TEXT) {
      var args = {
        'roomId': roomId,
        'message': message,
        'type': CommentType.TEXT,
      };
      if (extras != null) args['extras'] = extras;
      String json = await _channel.invokeMethod('sendMessage', args);

      return QiscusComment.fromJson(jsonDecode(json));
    }
  }

  /// get Qiscus account that has been log in
  static Future<QiscusAccount> getQiscusAccount() async {
    String json = await _channel.invokeMethod('getQiscusAccount');

    return QiscusAccount.fromJson(jsonDecode(json));
  }
}
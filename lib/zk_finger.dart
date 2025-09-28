import 'dart:async';

import 'package:flutter/services.dart';

///TODO: Catch app lifecycles on kill (and close connection)
class ZkFinger {
  static const MethodChannel _channel = const MethodChannel('zkfinger');

  static const EventChannel statusChangeStream =
      EventChannel('com.mamasodikov.zkfinger10/status_change');
  static const EventChannel imageStream =
      EventChannel('com.mamasodikov.zkfinger10/finger_image');

  static Future<String?> get platformVersion async {
    return _channel.invokeMethod('getPlatformVersion');
  }

  static Future<bool?> openConnection() async {
    return _channel.invokeMethod('openConnection');
  }

  static Future<bool?> closeConnection() async {
    return _channel.invokeMethod('closeConnection');
  }

  static Future<bool?> startListen({String? userId}) async {
    return _channel
        .invokeMethod('startListen', <String, String?>{'id': userId});
  }

  static Future<bool?> stopListen() async {
    return _channel.invokeMethod('stopListen');
  }

  static Future<bool?> identify({String? userId}) async {
    return _channel.invokeMethod('identify', <String, String?>{'id': userId});
  }

  static Future<bool?> verify({String? finger1, String? finger2}) async {
    return _channel.invokeMethod(
        'verify', <String, String?>{'finger1': finger1, 'finger2': finger2});
  }

  static Future<bool?> registerFinger({String? userId}) async {
    final bool? success = await _channel
        .invokeMethod('register', <String, String?>{'id': userId});
    return success;
  }

  static Future<bool?> clearFingerDatabase() async {
    return await _channel.invokeMethod('clear');
  }

  static Future<bool?> clearAndLoadDatabase({Map<String, String>? vUserList}) async {
    return await _channel.invokeMethod('clearAndLoad', <String, Map<String, String>? >{'fingers': vUserList});
  }

  static Future<bool?> delete({String? userId}) async {
    return _channel.invokeMethod('delete', <String, String?>{'id': userId});
  }

  static Future<bool?> onDestroy() async {
    return await _channel.invokeMethod('onDestroy');
  }

  // New bidirectional data management methods

  /// Get fingerprint feature data for a specific user ID
  static Future<String?> getUserFeature({required String userId}) async {
    try {
      return await _channel.invokeMethod('getUserFeature', <String, String>{'id': userId});
    } catch (e) {
      return null;
    }
  }

  /// Get all users and their fingerprint data from the database
  static Future<Map<String, String>?> getAllUsers() async {
    try {
      final result = await _channel.invokeMethod('getAllUsers');
      if (result is Map) {
        return Map<String, String>.from(result);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get the total count of users in the database
  static Future<int?> getUserCount() async {
    try {
      return await _channel.invokeMethod('getUserCount');
    } catch (e) {
      return null;
    }
  }

  /// Update fingerprint feature data for an existing user
  static Future<bool?> updateUserFeature({required String userId, required String feature}) async {
    try {
      return await _channel.invokeMethod('updateUserFeature', <String, String>{
        'id': userId,
        'data': feature
      });
    } catch (e) {
      return false;
    }
  }

  /// Check if a user exists in the database
  static Future<bool?> checkUserExists({required String userId}) async {
    try {
      return await _channel.invokeMethod('checkUserExists', <String, String>{'id': userId});
    } catch (e) {
      return false;
    }
  }
}

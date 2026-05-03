import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // request permission and store token
  Future<void> initialize(String uid) async {
    // request permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // get token
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveToken(uid, token);
      }

      // listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _saveToken(uid, newToken);
      });
    }

    // handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // handled by the app when in foreground
      debugPrint('foreground message: ${message.notification?.title}');
    });

    // handle background tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('notification tapped: ${message.notification?.title}');
    });
  }

  Future<void> _saveToken(String uid, String token) async {
    await _db.collection('users').doc(uid).update({
      'fcmToken': token,
      'tokenUpdatedAt': DateTime.now().toIso8601String(),
    });
  }

  // subscribe to group topic for session notifications
  Future<void> subscribeToGroup(String groupId) async {
    await _fcm.subscribeToTopic('group_$groupId');
  }

  Future<void> unsubscribeFromGroup(String groupId) async {
    await _fcm.unsubscribeFromTopic('group_$groupId');
  }
}

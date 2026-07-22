import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:nazar_ott/data/models/response_model/content_response_model/content_model.dart';
import 'package:nazar_ott/view_model/auth_controller/auth_controller.dart';
import 'package:nazar_ott/view_model/content_controller/content_controller.dart';
import 'package:path_provider/path_provider.dart';
import '../data/network/base_api_service.dart';
import '../utils/constants.dart';
import '../app/routes/app_routes.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService extends GetxController {
  static NotificationService get to => Get.find();

  // Lazy initialization for Firebase components to avoid crashes on non-configured platforms
  FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final RxList<Map<String, dynamic>> notifications =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  String? _currentToken;

  Future<void> init() async {
    if (GetPlatform.isWeb) {
      print("🌐 Notifications skipped on Web for now.");
      return;
    }
    print("🚀 NotificationService INIT STARTED");
    tz.initializeTimeZones();

    // Initialize Firebase if not already initialized
    await Firebase.initializeApp();

    /// 🔐 Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print("🔔 Permission Status: ${settings.authorizationStatus}");

    // Get FCM Token
    _currentToken = await _firebaseMessaging.getToken();
    print("FCM Token: $_currentToken");

    if (_currentToken != null) {
      uploadToken(); // Use the standardized upload method
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _currentToken = newToken;
      uploadToken();
    });

    /// 🔔 Initialize Local Notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification click here (foreground local notification tap)
        print("Notification clicked: ${response.payload}");
        _handleNotificationTapFromPayload(response.payload);
      },
    );

    /// 📩 Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Foreground Message Received: ${message.notification?.title}");
      _handleMessage(message);
      _showLocalNotification(message);
    });

    /// 📲 Notification Click (App in background, tapped to open)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(
        "📲 Notification Clicked (Background): ${message.notification?.title}",
      );
      _handleMessage(message);
      _handleNotificationTap(
        message.data['contentId'],
        message.data['contentType'],
      );
    });

    /// 🚀 App opened from terminated state via notification tap
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      print(
        "🚀 App opened from terminated state via notification: ${initialMessage.notification?.title}",
      );
      _handleNotificationTap(
        initialMessage.data['contentId'],
        initialMessage.data['contentType'],
      );
    }

    _loadNotifications();
    fetchNotifications(); // Initial fetch from server
    print("🚀 NotificationService INIT COMPLETED");
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // If the date is in the past, don't schedule
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _localNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'nazar_reminders',
          'Nazar OTT Reminders',
          channelDescription: 'Reminders for upcoming movies and series',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _localNotificationsPlugin.cancel(id);
  }

  /// 📡 Standardized method to send token to backend
  Future<void> uploadToken() async {
    if (GetPlatform.isWeb) return;
    try {
      // 🔄 If token is not yet available, try to fetch it
      if (_currentToken == null) {
        print("🔍 Attempting to fetch FCM Token...");
        _currentToken = await _firebaseMessaging.getToken();
      }

      if (_currentToken == null) {
        print("⚠️ FCM Token is still NULL. Cannot upload.");
        return;
      }

      print("📡 Uploading FCM Token to Backend: $_currentToken");
      final BaseApiService apiService = Get.find<BaseApiService>();
      final response = await apiService.postApi(AppConstants.updateFcmToken, {
        'token': _currentToken,
      });
      print("✅ FCM Token Synced Successfully: $response");
    } catch (e) {
      print("⚠️ FCM Token Sync Failed: $e");
    }
  }

  /// 📥 Fetch Notifications from Backend
  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      final BaseApiService apiService = Get.find<BaseApiService>();
      final response = await apiService.getApi(AppConstants.getNotifications);

      if (response != null && response['success'] == true) {
        final List fetchedList = response['notifications'] ?? [];
        notifications.assignAll(
          fetchedList.map((e) {
            final metadata = e['metadata'] as Map<String, dynamic>?;
            return {
              'id': e['_id'],
              'title': e['title'],
              'body': e['message'],
              'time':
                  e['sentAt'] ?? e['createdAt'] ?? DateTime.now().toString(),
              'isRead': e['isRead'] ?? false,
              'type': e['type'],
              'image': e['imageUrl'] as String?, // 🖼️ optional image URL
              'contentId': metadata?['contentId'] as String?, // 🔗 content id
              'contentType':
                  metadata?['contentType'] as String?, // movie / series
            };
          }).toList(),
        );
        _saveNotifications();
        print("✅ Fetched ${notifications.length} notifications from server");
      }
    } catch (e) {
      print("Error fetching notifications: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ Mark Single Notification as Read
  Future<void> markAsRead(int index) async {
    if (index >= notifications.length) return;
    if (notifications[index]['isRead'] == true) return;

    final String? id = notifications[index]['id'];
    if (id == null) {
      notifications[index]['isRead'] = true;
      notifications.refresh();
      _saveNotifications();
      return;
    }

    try {
      final BaseApiService apiService = Get.find<BaseApiService>();
      final response = await apiService.pacthApi(
        AppConstants.markNotificationRead(id),
        {},
      );

      if (response != null && response['success'] == true) {
        notifications[index]['isRead'] = true;
        notifications.refresh();
        _saveNotifications();
      }
    } catch (e) {
      print("Error marking notification read: $e");
    }
  }

  /// ✅ Mark All Notifications as Read
  Future<void> markAllAsRead() async {
    try {
      final BaseApiService apiService = Get.find<BaseApiService>();
      final response = await apiService.pacthApi(
        AppConstants.markAllNotificationsRead,
        {},
      );

      if (response != null && response['success'] == true) {
        for (var n in notifications) {
          n['isRead'] = true;
        }
        notifications.refresh();
        _saveNotifications();
      }
    } catch (e) {
      print("Error marking all read: $e");
    }
  }

  /// ❌ Delete Single Notification
  Future<void> deleteSingleNotification(int index) async {
    if (index >= notifications.length) return;

    final String? id = notifications[index]['id'];
    if (id == null) {
      notifications.removeAt(index);
      _saveNotifications();
      return;
    }

    try {
      final BaseApiService apiService = Get.find<BaseApiService>();
      final response = await apiService.deleteApi(
        AppConstants.deleteNotification(id),
        {},
      );

      if (response != null && response['success'] == true) {
        notifications.removeAt(index);
        _saveNotifications();
      }
    } catch (e) {
      print("Error deleting notification: $e");
      // Fallback: Remove locally if API fails
      notifications.removeAt(index);
      _saveNotifications();
    }
  }

  /// 🧹 Clear All Notifications (Local)
  void clearNotifications() {
    notifications.clear();
    _saveNotifications();
  }

  void _handleMessage(RemoteMessage message) {
    if (message.notification != null) {
      print("📩 Processing Message: ${message.notification?.title}");
      fetchNotifications(); // Refresh list from server
    }
  }

  /// 🔗 Navigate based on contentId/contentType sent in the notification data
  void _handleNotificationTap(String? contentId, String? contentType) {
    if (contentId == null || contentId.isEmpty) return;

    try {
      final ContentController contentController = Get.find<ContentController>();
      final AuthController authController = Get.find<AuthController>();

      final ContentModel? matchedContent = contentController.allContent
          .firstWhereOrNull(
            (c) => c.id == contentId,
          ); // 🔧 ADJUST: use the actual id field name on ContentModel

      if (matchedContent == null) {
        print(
          "⚠️ Content with id $contentId not found locally, skipping navigation.",
        );
        return;
      }

      Get.toNamed(
        AppRoutes.dramaDetails,
        arguments: {
          'content': matchedContent,
          'isSignedIn': authController.isLoggedIn.value,
        },
      );
    } catch (e) {
      print("⚠️ Failed to navigate from notification tap: $e");
    }
  }

  /// Local notification taps only give us a single String payload,
  /// so decode the JSON we encoded when the notification was shown.
  void _handleNotificationTapFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      _handleNotificationTap(
        decoded['contentId'] as String?,
        decoded['contentType'] as String?,
      );
    } catch (e) {
      print("⚠️ Failed to decode notification payload: $e");
    }
  }

  /// 📥 Download image locally so Android can render BigPictureStyle
  Future<String?> _downloadImageForNotification(String imageUrl) async {
    try {
      final Directory dir = await getTemporaryDirectory();
      final String filePath =
          '${dir.path}/notif_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final Dio dio = Dio();
      await dio.download(imageUrl, filePath);

      return filePath;
    } catch (e) {
      print("⚠️ Failed to download notification image: $e");
      return null;
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (message.notification == null) return;

    // Image can come either via FCM's notification.android.imageUrl
    // or via a custom data['image'] field — support both.
    final String? imageUrl =
        message.notification?.android?.imageUrl ?? message.data['image'];

    AndroidNotificationDetails androidDetails;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      final String? localPath = await _downloadImageForNotification(imageUrl);

      if (localPath != null) {
        androidDetails = AndroidNotificationDetails(
          'nazar_ott_channel',
          'Nazar OTT Notifications',
          channelDescription: 'Important notifications from Nazar OTT',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigPictureStyleInformation(
            FilePathAndroidBitmap(localPath),
            largeIcon: FilePathAndroidBitmap(localPath),
            contentTitle: message.notification?.title,
            summaryText: message.notification?.body,
            htmlFormatContentTitle: true,
            htmlFormatSummaryText: true,
          ),
        );
      } else {
        // Image download failed — fall back to plain notification
        androidDetails = const AndroidNotificationDetails(
          'nazar_ott_channel',
          'Nazar OTT Notifications',
          channelDescription: 'Important notifications from Nazar OTT',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        );
      }
    } else {
      // No image provided — plain notification, this is fine
      androidDetails = const AndroidNotificationDetails(
        'nazar_ott_channel',
        'Nazar OTT Notifications',
        channelDescription: 'Important notifications from Nazar OTT',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );
    }

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformDetails,
      // Store contentId + contentType as JSON so a tap can navigate correctly
      payload: jsonEncode({
        'contentId': message.data['contentId'],
        'contentType': message.data['contentType'],
      }),
    );
  }

  void _loadNotifications() {
    try {
      var box = Hive.box('appBox');
      List? saved = box.get('notifications');
      if (saved != null) {
        // ✅ Robust conversion from Map<dynamic, dynamic> to Map<String, dynamic>
        final List<Map<String, dynamic>> convertedList = saved.map((item) {
          return Map<String, dynamic>.from(item as Map);
        }).toList();

        notifications.assignAll(convertedList);
        print("✅ Loaded ${notifications.length} saved notifications");
      }
    } catch (e) {
      print("❌ Error loading notifications from Hive: $e");
    }
  }

  void _saveNotifications() {
    try {
      var box = Hive.box('appBox');
      box.put('notifications', notifications.toList());
    } catch (e) {
      print("❌ Error saving notifications to Hive: $e");
    }
  }
}

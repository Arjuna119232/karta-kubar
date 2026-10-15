import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/config.dart';

FirebaseOptions get _fcmOptions => const FirebaseOptions(
      apiKey: Config.fcmApiKey,
      appId: Config.fcmAppId,
      messagingSenderId: Config.fcmSenderId,
      projectId: Config.fcmProjectId,
    );

/// Handler pesan FCM saat aplikasi di background/tertutup.
/// Kirim pesan sebagai DATA-ONLY (tanpa blok "notification") agar suara+getar
/// ditangani channel "orders" di bawah dan tidak muncul dobel.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage m) async {
  await Firebase.initializeApp(options: _fcmOptions);
  await NotificationService.instance.init();
  await NotificationService.instance.showOrder(
    m.data['title'] ?? 'Order baru',
    m.data['body'] ?? 'Ada order masuk, buka aplikasi.',
  );
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool fcmReady = false;

  static const _channel = AndroidNotificationChannel(
    'orders',
    'Order Masuk',
    description: 'Notifikasi order baru dengan suara dan getar',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  Future<void> init() async {
    if (_ready) return;
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ));
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);
    await android?.requestNotificationsPermission();
    _ready = true;
  }

  /// Dipanggil sekali dari main(). Aman dipanggil walau FCM belum dikonfigurasi.
  Future<void> initFcm() async {
    if (!Config.fcmEnabled) return;
    try {
      await Firebase.initializeApp(options: _fcmOptions);
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
      FirebaseMessaging.onMessage.listen((m) {
        showOrder(m.data['title'] ?? m.notification?.title ?? 'Order baru',
            m.data['body'] ?? m.notification?.body ?? 'Ada order masuk');
      });
      fcmReady = true;
    } catch (_) {
      fcmReady = false;
    }
  }

  Future<String?> fcmToken() async {
    if (!fcmReady) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> showOrder(String title, String body) {
    return _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
          category: AndroidNotificationCategory.call,
        ),
      ),
    );
  }
}

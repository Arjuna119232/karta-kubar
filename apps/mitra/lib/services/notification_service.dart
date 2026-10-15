import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/config.dart';
import 'notifikasi.dart';

FirebaseOptions get _fcmOptions => const FirebaseOptions(
      apiKey: Config.fcmApiKey,
      appId: Config.fcmAppId,
      messagingSenderId: Config.fcmSenderId,
      projectId: Config.fcmProjectId,
    );

/// Handler pesan FCM saat aplikasi di background/tertutup.
/// Kirim pesan sebagai DATA-ONLY agar tidak muncul dobel.
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

  Future<void> init() async {
    if (_ready) return;
    await Notifikasi.instance.init();
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ));
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      'online_status',
      'Status ONLINE',
      description: 'Tanda mitra sedang ONLINE menerima order',
      importance: Importance.low,
    ));
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

  /// Order baru = notifikasi PERSISTEN (tidak bisa di-swipe) sampai mitra
  /// menerima atau menolak. Itu daftar "Order Masuk" di spec.
  Future<void> showOrder(String title, String body) => Notifikasi.instance.tampilkan(
        JenisNotif.orderMasuk,
        judul: title,
        isi: body,
      );

  Future<void> sembunyikanOrderMasuk() =>
      Notifikasi.instance.sembunyikan(JenisNotif.orderMasuk);

  /// Fallback kalau izin lokasi ditolak: notifikasi "ONLINE" yang tetap
  /// nempel (ongoing) walau service GPS tidak bisa jalan.
  static const _idOnline = 999001;

  Future<void> showOnlineStatus() async {
    await init();
    return _plugin.show(
      _idOnline,
      'KUNBAR Mitra • Sedang ONLINE',
      'Menunggu order. Buka aplikasi lalu tekan OFFLINE untuk berhenti.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'online_status',
          'Status ONLINE',
          channelDescription: 'Tanda mitra sedang ONLINE menerima order',
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          importance: Importance.low,
          priority: Priority.low,
          category: AndroidNotificationCategory.service,
        ),
      ),
    );
  }

  Future<void> cancelOnlineStatus() => _plugin.cancel(_idOnline);
}

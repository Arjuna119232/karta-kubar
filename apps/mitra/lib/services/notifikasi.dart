import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Daftar notifikasi KUNBAR Mitra.
///
/// PERSISTEN = tidak bisa di-swipe (`ongoing: true`). Ini sah karena Android
/// mengizinkan notifikasi ongoing; yang memaksa service-nya jalan terus cuma
/// notifikasi "Order Berjalan" dan "Sedang ONLINE" (foreground service).
enum JenisNotif {
  // ---- 8 persisten ----
  orderMasuk(
    'Order Masuk',
    'Ada order baru masuk',
    persisten: true,
    importance: Importance.max,
  ),
  orderBerjalan(
    'Order Berjalan',
    'Ada order yang sedang dikerjakan',
    persisten: true,
    importance: Importance.low,
  ),
  wargaTelepon(
    'Warga Telepon',
    'Warga menelepon',
    persisten: true,
    importance: Importance.max,
    layarPenuh: true,
  ),
  gpsOff(
    'GPS Off',
    'GPS dimatikan',
    persisten: true,
    importance: Importance.high,
  ),
  internetHilang(
    'Internet Hilang',
    'Koneksi terputus',
    persisten: true,
    importance: Importance.high,
  ),
  sos(
    'SOS Darurat',
    'Mode darurat aktif',
    persisten: true,
    importance: Importance.max,
  ),
  bateraiKritis(
    'Baterai Kritis',
    'Baterai di bawah 15%',
    persisten: true,
    importance: Importance.high,
  ),
  orderDibatalkan(
    'Order Dibatalkan',
    'Order dibatalkan warga',
    persisten: true,
    importance: Importance.max,
  ),

  // ---- 12 biasa (bisa di-swipe) ----
  chat('Chat', 'Pesan baru dari warga', importance: Importance.high),
  penghasilan('Penghasilan', 'Order selesai, penghasilan masuk',
      importance: Importance.high),
  rating('Rating Baru', 'Warga memberi rating', importance: Importance.defaultImportance),
  pengingatPickup('Pengingat Pickup', '5 menit lagi ambil order',
      importance: Importance.high),
  pengingatDropoff('Pengingat Dropoff', 'Sudah sampai lokasi antar',
      importance: Importance.high),
  pengingatIstirahat('Pengingat Istirahat', 'Sudah 4 jam online',
      importance: Importance.defaultImportance),
  targetHarian('Target Harian', 'Progres target harian',
      importance: Importance.defaultImportance),
  bonus('Bonus / Promo', 'Ada bonus untuk mitra',
      importance: Importance.defaultImportance),
  pengumuman('Pengumuman', 'Pengumuman dari admin',
      importance: Importance.defaultImportance),
  updateApp('Update App', 'Ada versi baru', importance: Importance.low),
  maintenance('Maintenance', 'Server sedang maintenance',
      importance: Importance.defaultImportance),
  orderDelay('Order Delay', 'Order tertunda', importance: Importance.high);

  const JenisNotif(
    this.judul,
    this.alasan, {
    this.persisten = false,
    this.importance = Importance.defaultImportance,
    this.layarPenuh = false,
  });

  final String judul;

  /// Kenapa notifikasi ini muncul (dipakai di halaman Pengaturan).
  final String alasan;
  final bool persisten;
  final Importance importance;

  /// true = muncul seperti layar panggilan (butuh izin USE_FULL_SCREEN_INTENT).
  final bool layarPenuh;

  int get id => 1000 + index;

  /// Nama getter harus beda dari field instance `persisten` (Dart menolak
  /// static member dan instance member dengan nama sama).
  static List<JenisNotif> get daftarPersisten =>
      JenisNotif.values.where((j) => j.persisten).toList();
}

/// Satu service untuk semua notifikasi: tampil, perbarui, sembunyikan.
class Notifikasi {
  Notifikasi._();
  static final Notifikasi instance = Notifikasi._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool siap = false;

  static const chPenting = 'orders';
  static const chStatus = 'status';

  Future<void> init() async {
    if (siap) return;
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ));
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      chPenting,
      'Order & Penting',
      description: 'Order masuk, warga menelepon, darurat',
      importance: Importance.max,
    ));
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      chStatus,
      'Status & Peringatan',
      description: 'GPS, internet, baterai, pengingat',
      importance: Importance.defaultImportance,
    ));
    siap = true;
  }

  AndroidNotificationDetails _detail(JenisNotif j, {required bool layarPenuh}) {
    final penting = j.importance == Importance.max;
    return AndroidNotificationDetails(
      penting ? chPenting : chStatus,
      penting ? 'Order & Penting' : 'Status & Peringatan',
      channelDescription: j.alasan,
      importance: j.importance,
      priority: penting ? Priority.max : Priority.defaultPriority,
      ongoing: j.persisten,
      autoCancel: !j.persisten,
      onlyAlertOnce: true,
      fullScreenIntent: layarPenuh,
      category: layarPenuh
          ? AndroidNotificationCategory.call
          : AndroidNotificationCategory.event,
      playSound: penting,
      enableVibration: penting,
      visibility: NotificationVisibility.public,
    );
  }

  /// Tampilkan (atau perbarui bila id sama - teks berubah, tidak bunyi lagi).
  Future<void> tampilkan(
    JenisNotif j, {
    required String judul,
    required String isi,
    String? badan,
  }) async {
    await init();
    try {
      await _plugin.show(
        j.id,
        judul,
        isi,
        NotificationDetails(android: _detail(j, layarPenuh: j.layarPenuh)),
        payload: badan,
      );
    } catch (_) {
      // Notifikasi gagal (mis. izin belum diberikan) tidak boleh menjatuhkan app.
    }
  }

  Future<void> sembunyikan(JenisNotif j) async {
    await init();
    try {
      await _plugin.cancel(j.id);
    } catch (_) {}
  }

  /// Id notifikasi persisten yang sedang tampil (untuk debug/pengaturan).
  Future<List<int>> aktifPersisten() async {
    await init();
    try {
      final list = await _plugin.getActiveNotifications();
      final idPersisten = JenisNotif.daftarPersisten.map((j) => j.id).toSet();
      // .id dari ActiveNotification bertipe int? -> harus.whereType<int>()
      return list.map((n) => n.id).whereType<int>().where(idPersisten.contains).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> bersihkanSemua() async {
    await init();
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}

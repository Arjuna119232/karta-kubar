import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../core/format.dart';
import '../models/models.dart';
import '../services/location_service.dart';
import '../services/notifikasi.dart';
import '../services/notification_service.dart';
import '../services/repository.dart';

class AppState extends ChangeNotifier {
  final repo = OrderRepository();
  final _loc = LocationService();
  SharedPreferences? _p;

  bool loggedIn = false, online = false, loading = false, offlineMode = false;

  /// true = halaman izin belum pernah dibuka (tampil sekali setelah login).
  bool izinBelumDitinjau = false;

  /// true = onboarding cara pakai belum pernah dilihat.
  bool onboardingBelumDitinjau = true;

  /// true = sedang menyiapkan GPS/izin setelah mitra menekan ONLINE.
  /// Tombol tetap responsif, hanya berubah jadi "MENYIAPKAN...".
  bool menyiapkanOnline = false;

  /// Sisa detik sebelum order otomatis ditolak (0 = tidak ada timer).
  final _tolakOtomatis = <String, Timer>{};
  static const int detikTolakOtomatis = 30;
  String name = 'Mitra';
  String telepon = '';
  String kontakDarurat = '';
  List<Withdraw> withdrawals = [];
  String? error;
  List<Order> incoming = [], history = [];
  List<Rating> ratings = [];
  Order? active;

  ThemeMode themeMode = ThemeMode.system;
  double radiusKm = 5;
  int openHour = 6, closeHour = 22;
  String vehicleType = 'Motor', vehicleModel = '', plate = '';

  StreamSubscription<List<Order>>? _sub;
  final _rejected = <String>{};

  // Pemantau status (semua hanya hidup saat ONLINE)
  Timer? _tGps, _tInternet, _tIstirahat;
  DateTime? _onlineMulai;

  // ---------- init & auth ----------
  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    final t = _p!.getString('theme') ?? 'system';
    themeMode = ThemeMode.values.firstWhere((e) => e.name == t, orElse: () => ThemeMode.system);
    radiusKm = _p!.getDouble('radius') ?? 5;
    openHour = _p!.getInt('open') ?? 6;
    closeHour = _p!.getInt('close') ?? 22;
    izinBelumDitinjau = _p!.getBool('izin_sheet_v1') != true;
    onboardingBelumDitinjau = _p!.getBool('onboarding_v1') != true;
    kontakDarurat = _p!.getString('kontak_darurat') ?? '';
    withdrawals = _bacaWithdraw();
    name = _p!.getString('mitra_nama') ?? name;
    if (_p!.getString('mitra_telepon') != null) telepon = _p!.getString('mitra_telepon')!;
    vehicleType = _p!.getString('vtype') ?? 'Motor';
    vehicleModel = _p!.getString('vmodel') ?? '';
    plate = _p!.getString('plate') ?? '';
    if (!Config.demo && Supabase.instance.client.auth.currentSession != null) {
      try {
        await _afterLogin();
      } catch (_) {
        // offline saat start: tetap masuk dengan cache
        loggedIn = true;
        offlineMode = true;
        _cacheLoad();
      }
    }
  }

  Future<bool> login(String email, String pass) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (Config.demo) {
        name = email.contains('@') ? email.split('@').first : (email.isEmpty ? 'Mitra Demo' : email);
        loggedIn = true;
        await loadAll();
      } else {
        await Supabase.instance.client.auth.signInWithPassword(email: email.trim(), password: pass);
        await _afterLogin();
      }
    } on AuthException catch (e) {
      error = e.message;
    } catch (e) {
      error = e is String ? e : 'Gagal masuk: $e';
    }
    loading = false;
    notifyListeners();
    return loggedIn;
  }

  Future<void> _afterLogin() async {
    final prof = await repo.profile();
    if (prof['role'] != 'mitra') {
      await repo.signOut();
      throw 'Akun ini bukan akun mitra';
    }
    name = (prof['name'] ?? 'Mitra') as String;
    if (prof['vehicle_type'] != null) vehicleType = prof['vehicle_type'] as String;
    if (prof['vehicle_model'] != null) vehicleModel = prof['vehicle_model'] as String;
    if (prof['plate'] != null) plate = prof['plate'] as String;
    loggedIn = true;
    final tok = await NotificationService.instance.fcmToken();
    if (tok != null) {
      try {
        await repo.updateProfile({'fcm_token': tok});
      } catch (_) {}
    }
    await loadAll();
  }

  // ---------- daftar & onboarding ----------
  Future<String?> daftar({
    required String nama,
    required String email,
    required String password,
    required String telepon,
    required String kendaraan,
    required String plat,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (Config.demo) {
        if (password.length < 6) {
          error = 'Password minimal 6 karakter';
        } else {
          name = nama;
          vehicleType = kendaraan;
          plate = plat.toUpperCase();
          await _p?.setString('mitra_email', email);
          await _p?.setString('mitra_telepon', telepon);
          loggedIn = true;
          await loadAll();
        }
      } else {
        final r = await Supabase.instance.client.auth
            .signUp(email: email.trim(), password: password);
        if (r.user == null) {
          error = 'Pendaftaran gagal. Coba lagi.';
        } else {
          await Supabase.instance.client.from('profiles').update({
            'role': 'mitra',
            'name': nama,
            'phone': telepon,
            'vehicle_type': kendaraan,
            'plate': plat.toUpperCase(),
          }).eq('id', r.user!.id);
          name = nama;
          vehicleType = kendaraan;
          plate = plat.toUpperCase();
          loggedIn = true;
          onboardingBelumDitinjau = true;
          await loadAll();
        }
      }
    } on AuthException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Gagal daftar: $e';
    }
    loading = false;
    notifyListeners();
    return error;
  }

  Future<void> tandaiOnboardingDitinjau() async {
    onboardingBelumDitinjau = false;
    await _p?.setBool('onboarding_v1', true);
    notifyListeners();
  }

  Future<void> tandaiIzinDitinjau() async {
    izinBelumDitinjau = false;
    await _p?.setBool('izin_sheet_v1', true);
    notifyListeners();
  }

  Future<void> logout() async {
    await setOnline(false);
    await _stopLokasi();
    await _loc.stop();
    _hentiPemantau();
    await Notifikasi.instance.sembunyikan(JenisNotif.sos);
    await Notifikasi.instance.sembunyikan(JenisNotif.orderDibatalkan);
    await repo.signOut();
    loggedIn = false;
    active = null;
    incoming = [];
    history = [];
    notifyListeners();
  }

  // ---------- data & cache offline ----------
  Future<void> loadAll() async {
    try {
      history = await repo.history();
      active = await repo.activeOrder();
      ratings = await repo.ratings();
      offlineMode = false;
      _cacheSave();
    } catch (_) {
      offlineMode = true;
      _cacheLoad();
    }
    _syncLocation();
    notifyListeners();
  }

  Future<void> refresh() => loadAll();

  /// Posisi mitra untuk marker peta di Beranda (null kalau izin belum ada).
  Future<({double lat, double lng})?> posisiSaya() => _loc.posisiSekarang();

  void _cacheSave() {
    _p?.setString(
        'cache',
        jsonEncode({
          'history': history.map((o) => o.toMap()).toList(),
          'active': active?.toMap(),
          'incoming': incoming.map((o) => o.toMap()).toList(),
        }));
  }

  void _cacheLoad() {
    final raw = _p?.getString('cache');
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      history = (m['history'] as List).map((e) => Order.fromMap(Map<String, dynamic>.from(e))).toList();
      active = m['active'] == null ? null : Order.fromMap(Map<String, dynamic>.from(m['active']));
      if (incoming.isEmpty) {
        incoming = (m['incoming'] as List).map((e) => Order.fromMap(Map<String, dynamic>.from(e))).toList();
      }
    } catch (_) {}
  }

  // ---------- online / order masuk ----------
  bool get _inHours {
    final h = DateTime.now().hour;
    return openHour <= closeHour ? (h >= openHour && h < closeHour) : (h >= openHour || h < closeHour);
  }

  /// Mengembalikan pesan error (null = sukses).
  Future<String?> setOnline(bool v) async {
    if (v && !_inHours) {
      return 'Di luar jam operasional ($openHour:00–$closeHour:00). Ubah di Pengaturan.';
    }
    online = v;
    // PENTING: status dibalik + UI dibangun ulang SEBELUM kerja berat.
    // Dohulu `await _startLokasi(...)` menahan notifyListeners, dan
    // _startLokasi -> Geolocator.requestPermission() menunggu user menutup dialog
    // Android. Akibatnya tombol ONLINE terlihat "tidak merespons".
    menyiapkanOnline = v;
    notifyListeners();
    try {
      await repo.setOnline(v);
    } catch (_) {}
    if (v) {
      _listen();
      _mulaiPemantau();
      _notifOrderMasuk();
      // Jangan di-await: boleh memunculkan dialog izin lokasi.
      _startLokasi(aktifOrder: active != null && active!.isActive).whenComplete(() {
        menyiapkanOnline = false;
        notifyListeners();
      });
    } else {
      await _sub?.cancel();
      _sub = null;
      incoming = [];
      for (final t in _tolakOtomatis.values) {
        t.cancel();
      }
      _tolakOtomatis.clear();
      await _stopLokasi();
      _hentiPemantau();
      await Notifikasi.instance.sembunyikan(JenisNotif.gpsOff);
      await Notifikasi.instance.sembunyikan(JenisNotif.internetHilang);
      await Notifikasi.instance.sembunyikan(JenisNotif.pengingatIstirahat);
      NotificationService.instance.sembunyikanOrderMasuk();
      menyiapkanOnline = false;
    }
    notifyListeners();
    return null;
  }

  void _listen() {
    _sub?.cancel();
    _sub = repo.watchPending().listen((list) {
      final fresh = list.where((o) => o.distanceKm <= radiusKm && !_rejected.contains(o.id)).toList();
      final known = incoming.map((o) => o.id).toSet();
      final added = fresh.where((o) => !known.contains(o.id)).toList();
      incoming = fresh;
      offlineMode = false;
      for (final o in added) {
        NotificationService.instance.showOrder(
            'Order ${o.typeLabel} baru',
            '${o.customerName} - ${o.distanceKm.toStringAsFixed(1)} km - ${rp(o.fee)}');
      }
      for (final o in added) {
        _jadwalTolakOtomatis(o);
      }
      if (added.isNotEmpty) _notifOrderMasuk();
      _cacheSave();
      notifyListeners();
    }, onError: (_) {
      offlineMode = true;
      notifyListeners();
    });
  }

  Future<String?> accept(Order o) async {
    if (active != null) return 'Selesaikan order aktif dulu';
    try {
      final r = await repo.accept(o.id);
      incoming.removeWhere((x) => x.id == o.id);
      if (r == null) {
        notifyListeners();
        return 'Order sudah diambil mitra lain';
      }
      active = r;
      _batalTolakOtomatis(o.id);
      _notifOrderMasuk();
      _syncLocation();
      _cacheSave();
      notifyListeners();
      return null;
    } catch (_) {
      return 'Gagal menerima order. Cek sinyal lalu coba lagi.';
    }
  }

  void reject(Order o) {
    _batalTolakOtomatis(o.id);
    _rejected.add(o.id);
    incoming.removeWhere((x) => x.id == o.id);
    _notifOrderMasuk();
    notifyListeners();
  }

  Future<String?> advance() async {
    final o = active;
    if (o == null || o.nextStatus == null) return null;
    try {
      final u = await repo.updateStatus(o.id, o.nextStatus!);
      if (u.isDone) {
        history = [u, ...history];
        active = null;
      } else {
        active = u;
      }
      _notifStatusOrder(u.status);
      _syncLocation();
      _cacheSave();
      notifyListeners();
      return null;
    } catch (_) {
      return 'Gagal update status. Cek sinyal lalu coba lagi.';
    }
  }

  // ---------- lokasi & notifikasi ONLINE ----------
  // Selama ONLINE, GPS + notifikasi foreground (tidak bisa di-swipe) menyala.
  // Mati hanya ketika mitra menekan OFFLINE / keluar.
  bool lokasiDariGps = false;

  void _syncLocation() {
    if (!online) {
      _stopLokasi();
      return;
    }
    _startLokasi(aktifOrder: active != null && active!.isActive);
  }

  Future<void> _startLokasi({required bool aktifOrder}) async {
    final id = aktifOrder ? active?.id : null;
    final ok = await _loc.startOnline(
      aktifOrder: aktifOrder,
      orderId: id,
      onPos: (p) {
        if (id != null && id.isNotEmpty) {
          repo.pushLocation(id, p.latitude, p.longitude).catchError((_) {});
        }
      },
    );
    lokasiDariGps = ok;
    if (ok) {
      // Notifikasi foreground (dari service GPS) yang_handle.
      await NotificationService.instance.cancelOnlineStatus();
    } else {
      // Izin lokasi ditolak: pakai notifikasi lokal yang tetap nempel.
      await NotificationService.instance.showOnlineStatus();
    }
    notifyListeners();
  }

  Future<void> _stopLokasi() async {
    await _loc.stop();
    await NotificationService.instance.cancelOnlineStatus();
    lokasiDariGps = false;
  }

  Future<String> sos() async {
    final p = await _loc.current();
    try {
      await repo.sendSos(p?.latitude, p?.longitude, active?.id);
      await _notif(JenisNotif.sos, 'SOS aktif',
          'Admin sudah menerima lokasi. Jangan matikan aplikasi.');
      return 'SOS terkirim ke admin${p == null ? ' (lokasi tidak tersedia)' : ' beserta lokasi Anda'}.';
    } catch (_) {
      return 'SOS gagal terkirim. Telepon 112 sekarang.';
    }
  }

  // ---------- penghasilan ----------
  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime get weekStart => _today.subtract(Duration(days: DateTime.now().weekday - 1));
  DateTime get monthStart => DateTime(DateTime.now().year, DateTime.now().month);
  DateTime get dayStart => _today;

  List<Order> doneSince(DateTime from) =>
      history.where((o) => o.isDone && !o.doneAt.toLocal().isBefore(from)).toList();
  int earned(DateTime from) => doneSince(from).fold(0, (s, o) => s + o.fee);
  int get todayEarnings => earned(_today);

  /// Saldo aktif = semua order selesai dikurangi penarikan yang sudah diproses.
  int get saldoAktif {
    final ditarik = withdrawals
        .where((w) => w.status == StatusWithdraw.dibayar ||
            w.status == StatusWithdraw.disetujui)
        .fold<int>(0, (a, w) => a + w.jumlah);
    final bruto = doneSince(DateTime(2020)).fold<int>(0, (a, o) => a + o.fee);
    return bruto - ditarik;
  }

  /// Kirim permintaan tarik saldo. Demo = tersimpan di perangkat; kalau Supabase
  /// aktif, baris masuk ke tabel `withdrawals` untuk diproses admin.
  Future<String?> mintaTarik({
    required int jumlah,
    required String metode,
    required String tujuan,
  }) async {
    if (jumlah <= 0) return 'Nominal harus lebih dari nol';
    if (tujuan.trim().length < 6) return 'Nomor tujuan terlalu pendek';
    if (jumlah > saldoAktif) return 'Nominal melebihi saldo aktif';
    try {
      if (!Config.demo) {
        await repo.repoTarik(jumlah, metode, tujuan.trim());
      }
      final w = Withdraw(
        id: 'w-${DateTime.now().millisecondsSinceEpoch}',
        jumlah: jumlah,
        metode: metode,
        tujuan: tujuan.trim(),
        status: StatusWithdraw.pending,
        createdAt: DateTime.now(),
      );
      withdrawals = [w, ...withdrawals];
      _simpanTarik();
      notifyListeners();
      return null;
    } catch (_) {
      return 'Gagal mengirim permintaan. Cek sinyal lalu coba lagi.';
    }
  }

  List<Withdraw> _bacaWithdraw() {
    final raw = _p?.getString('withdrawals');
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Withdraw.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _simpanTarik() {
    _p?.setString(
      'withdrawals',
      jsonEncode(withdrawals.map((w) => w.toMap()).toList()),
    );
  }

  /// Target harian mitra (bisa diubah di Jadwal nanti); dipakai untuk progres.
  static const int targetHarian = 75000;
  int get todayCount => doneSince(_today).length;
  double get avgRating => ratings.isEmpty ? 0 : ratings.fold(0, (s, r) => s + r.stars) / ratings.length;

  // ---------- notifikasi: pemicu otomatis ----------
  Future<void> _notif(JenisNotif j, String judul, String isi) =>
      Notifikasi.instance.tampilkan(j, judul: judul, isi: isi);

  /// Sisa detik sebelum order ini ditolak otomatis.
  int sisaTolak(Order o) {
    final sisa = detikTolakOtomatis - DateTime.now().difference(o.createdAt).inSeconds;
    return sisa < 0 ? 0 : sisa;
  }

  void _batalTolakOtomatis(String id) {
    _tolakOtomatis.remove(id)?.cancel();
  }

  /// Order tidak dibalas dalam 30 detik -> hilang dari daftar (ditolak diam-diam).
  void _jadwalTolakOtomatis(Order o) {
    _batalTolakOtomatis(o.id);
    final awal = sisaTolak(o);
    _tolakOtomatis[o.id] = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!incoming.any((x) => x.id == o.id)) {
        t.cancel();
        _tolakOtomatis.remove(o.id);
        return;
      }
      if (sisaTolak(o) <= 0) {
        t.cancel();
        _tolakOtomatis.remove(o.id);
        reject(o);
        return;
      }
      if (sisaTolak(o) != awal) notifyListeners();
    });
  }

  /// Order masuk = notifikasi PERSISTEN sampai diterima/ditolak.
  void _notifOrderMasuk() {
    final n = incoming.length;
    if (n == 0) {
      NotificationService.instance.sembunyikanOrderMasuk();
      return;
    }
    final o = incoming.first;
    _notif(
      JenisNotif.orderMasuk,
      n == 1 ? 'Order ${o.typeLabel} baru masuk' : '$n order menunggu',
      '${o.customerName} - ${o.distanceKm.toStringAsFixed(1)} km - ${rp(o.fee)}',
    );
  }

  /// Order selesai / pindah tahap.
  void _notifStatusOrder(String status) {
    switch (status) {
      case 'arrived':
        _notif(JenisNotif.pengingatDropoff, 'Sudah di lokasi jemput',
            'Lanjut antar barang atau penumpang ke tujuan.');
      case 'delivering':
        _notif(JenisNotif.pengingatPickup, 'Sedang diantar',
            'Wp Mihrim ke warga kalau sudah sampai.');
      case 'done':
        _notif(JenisNotif.penghasilan, 'Order selesai',
            'Penghasilan hari ini ${rp(todayEarnings)} dari $todayCount order.');
        _cekTarget();
      default:
        break;
    }
  }

  void _cekTarget() {
    if (todayCount > 0 && todayCount % 3 == 0 && todayEarnings >= targetHarian) {
      _notif(JenisNotif.targetHarian, 'Target harian tercapai',
          '$todayCount order selesai hari ini. Lanjut!');
    }
  }

  /// Timer yang hidup hanya selama ONLINE.
  void _mulaiPemantau() {
    _hentiPemantau();
    _onlineMulai = DateTime.now();
    _tGps = Timer.periodic(const Duration(seconds: 20), (_) => _cekGps());
    _tInternet = Timer.periodic(const Duration(seconds: 20), (_) => _cekInternet());
    _tIstirahat = Timer.periodic(const Duration(minutes: 30), (_) => _cekIstirahat());
    _cekGps();
    _cekInternet();
  }

  void _hentiPemantau() {
    _tGps?.cancel();
    _tInternet?.cancel();
    _tIstirahat?.cancel();
    _tGps = _tInternet = _tIstirahat = null;
    _onlineMulai = null;
  }

  Future<void> _cekGps() async {
    if (!online) return;
    final nyala = await _loc.lokasiNyala();
    if (nyala) {
      await Notifikasi.instance.sembunyikan(JenisNotif.gpsOff);
    } else {
      _notif(JenisNotif.gpsOff, 'GPS dimatikan',
          'Nyalakan GPS dulu, kalau tidak tidak bisa terima order dan warga tidak melihat posisimu.');
    }
  }

  Future<void> _cekInternet() async {
    if (!online) return;
    var ada = false;
    try {
      final hasil = await InternetAddress.lookup('one.one.one.one')
          .timeout(const Duration(seconds: 6));
      ada = hasil.isNotEmpty && hasil.first.rawAddress.isNotEmpty;
    } catch (_) {
      ada = false;
    }
    if (!online) return;
    if (ada) {
      await Notifikasi.instance.sembunyikan(JenisNotif.internetHilang);
      offlineMode = false;
    } else {
      offlineMode = true;
      _notif(JenisNotif.internetHilang, 'Internet hilang',
          'Order bisa terlambat masuk. Koneksi kembalinya otomatis.');
      notifyListeners();
    }
  }

  Future<void> _cekIstirahat() async {
    if (!online || _onlineMulai == null) return;
    final jamOnline = DateTime.now().difference(_onlineMulai!).inMinutes;
    if (jamOnline >= 240) {
      await Notifikasi.instance.sembunyikan(JenisNotif.pengingatIstirahat);
      _notif(JenisNotif.pengingatIstirahat, 'Sudah 4 jam online',
          'Minum dulu. Istirahat 15 menit tidakurangi Targeting.');
    } else {
      await Notifikasi.instance.sembunyikan(JenisNotif.pengingatIstirahat);
    }
  }

  // ---------- pengaturan ----------
  void setTheme(ThemeMode m) {
    themeMode = m;
    _p?.setString('theme', m.name);
    notifyListeners();
  }

  void setKontakDarurat(String v) {
    kontakDarurat = v;
    _p?.setString('kontak_darurat', v);
    notifyListeners();
  }

  void setRadius(double v) {
    radiusKm = v;
    _p?.setDouble('radius', v);
    notifyListeners();
  }

  Future<void> setHours(int open, int close) async {
    openHour = open;
    closeHour = close;
    _p?.setInt('open', open);
    _p?.setInt('close', close);
    notifyListeners();
    try {
      await repo.updateProfile({'open_hour': open, 'close_hour': close, 'radius_km': radiusKm});
    } catch (_) {}
  }

  Future<void> saveVehicle(String type, String model, String plateNo) async {
    vehicleType = type;
    vehicleModel = model;
    plate = plateNo;
    _p?.setString('vtype', type);
    _p?.setString('vmodel', model);
    _p?.setString('plate', plateNo);
    notifyListeners();
    try {
      await repo.updateProfile({'vehicle_type': type, 'vehicle_model': model, 'plate': plateNo});
    } catch (_) {}
  }

  void addDummyOrder() => repo.addDummy();

  @override
  void dispose() {
    _sub?.cancel();
    for (final t in _tolakOtomatis.values) {
      t.cancel();
    }
    _tolakOtomatis.clear();
    _hentiPemantau();
    _loc.stop();
    NotificationService.instance.cancelOnlineStatus();
    super.dispose();
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../core/format.dart';
import '../models/models.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/repository.dart';

class AppState extends ChangeNotifier {
  final repo = OrderRepository();
  final _loc = LocationService();
  SharedPreferences? _p;

  bool loggedIn = false, online = false, loading = false, offlineMode = false;
  String name = 'Mitra';
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

  // ---------- init & auth ----------
  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    final t = _p!.getString('theme') ?? 'system';
    themeMode = ThemeMode.values.firstWhere((e) => e.name == t, orElse: () => ThemeMode.system);
    radiusKm = _p!.getDouble('radius') ?? 5;
    openHour = _p!.getInt('open') ?? 6;
    closeHour = _p!.getInt('close') ?? 22;
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

  Future<void> logout() async {
    await setOnline(false);
    await _stopLokasi();
    await _loc.stop();
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
    try {
      await repo.setOnline(v);
    } catch (_) {}
    if (v) {
      await _startLokasi(aktifOrder: active != null && active!.isActive);
      _listen();
    } else {
      await _sub?.cancel();
      _sub = null;
      incoming = [];
      await _stopLokasi();
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
            'Order ${o.typeLabel} baru', '${o.distanceKm.toStringAsFixed(1)} km • ${rp(o.fee)}');
      }
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
      _syncLocation();
      _cacheSave();
      notifyListeners();
      return null;
    } catch (_) {
      return 'Gagal menerima order. Cek sinyal lalu coba lagi.';
    }
  }

  void reject(Order o) {
    _rejected.add(o.id);
    incoming.removeWhere((x) => x.id == o.id);
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
  int get todayCount => doneSince(_today).length;
  double get avgRating => ratings.isEmpty ? 0 : ratings.fold(0, (s, r) => s + r.stars) / ratings.length;

  // ---------- pengaturan ----------
  void setTheme(ThemeMode m) {
    themeMode = m;
    _p?.setString('theme', m.name);
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
    _loc.stop();
    NotificationService.instance.cancelOnlineStatus();
    super.dispose();
  }
}

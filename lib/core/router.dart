import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/absen/presentation/absen_screen.dart';
import '../features/aspirasi/presentation/aspirasi_screen.dart';
import '../features/darurat/presentation/darurat_screen.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/galeri/presentation/galeri_screen.dart';
import '../features/profile/presentation/edit_profil_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/pengurus/presentation/pengurus_screen.dart';
import '../features/order/presentation/order_detail.dart';
import '../features/order/presentation/order_form_jastip.dart';
import '../features/order/presentation/order_form_ojek.dart';
import '../features/order/presentation/order_history.dart';
import '../features/order/presentation/order_rating.dart';
import '../features/order/presentation/order_tracking.dart';
import '../features/shell/presentation/app_shell.dart';
import '../features/umkm/presentation/umkm_screen.dart';
import 'auth/session.dart';
import 'auth/user_role.dart';
import 'boot.dart';
import '../shared/widgets/app_icon.dart';
import '../shared/models/order.dart';
import '../shared/widgets/loading_dots.dart';
import '../features/mitra_usaha/domain/mitra_usaha.dart';
import '../features/mitra_usaha/presentation/mitra_usaha_detail.dart';
import '../features/mitra_usaha/presentation/mitra_usaha_peta.dart';
import '../features/order/presentation/pilih_lokasi_peta.dart';
import '../features/mitra_usaha/presentation/mitra_usaha_screen.dart';

/// Halaman "kamu belum punya akses" — muncul kalau guard menolak rute.
class AksesDitolakScreen extends ConsumerWidget {
  const AksesDitolakScreen({super.key, required this.minimal});

  final UserRole minimal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Session session = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppIcon(Ik.lock, size: 56, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 18),
              Text('Akses perlu ${minimal.label}',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                session.sudahLogin
                    ? 'Akun kamu saat ini ${session.efektif.label}. Fitur ini khusus untuk ${minimal.label} ke atas.'
                    : 'Kamu perlu masuk terlebih dahulu untuk memakai fitur ini.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Kembali ke beranda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Guard rute: menolak kalau role session tidak memenuhi [minimal].
///
/// Catatan: ini guard di sisi APP. Keamanan sesungguhnya harus tetap
/// ditegakkan di sisi server lewat Row Level Security Supabase — guard
/// aplikasi cuma untuk UX, bukan pengaman.
class RoleGate extends ConsumerWidget {
  const RoleGate({
    super.key,
    required this.minimal,
    required this.child,
  });

  final UserRole minimal;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Session session = ref.watch(sessionProvider);
    // Sesi dibaca dari SharedPreferences secara async. Selama itu belum
    // selesai, `sudahLogin` masih false dan guard akan sempat menampilkan
    // "Akses Ditolak" untuk user yang sebenarnya masih masuk.
    if (!session.siap) {
      return const LoadingScreen();
    }
    if (!session.sudahLogin || !session.efektif.bisa(minimal)) {
      return AksesDitolakScreen(minimal: minimal);
    }
    return child;
  }
}

/// Transisi halaman: fade + geser naik tipis (halus, tanpa lompatan).
CustomTransitionPage<void> _halaman(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (BuildContext context, Animation<double> anim,
        Animation<double> secondary, Widget c) {
      final Animation<double> curved =
          CurveTween(curve: Curves.easeOutCubic).animate(anim);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: c,
        ),
      );
    },
  );
}

/// Membangun router dengan halaman pertama yang sudah diketahui.
///
/// Sengaja TIDAK ada rute `/` lagi. Dulu `/` memuat widget splash Flutter
/// buatan sendiri (1,8 detik) yang baru menentukan tujuan setelah selesai -
/// artinya aplikasi sempat menggambar satu halaman penuh sebelum halaman
/// yang benar. Sekarang splash ditangani sistem operasi
/// (`Theme.SplashScreen` di Android, `UILaunchScreen` di iOS) dan
/// [tentukanLokasiAwal] sudah dipanggil sebelum `runApp`, jadi router bisa
/// langsung dibuka di halaman yang benar tanpa frame perantara.
///
/// Dipanggil SATU KALI di main() dan hasilnya disimpan, bukan dibangun ulang
/// di `build()`: GoRouter yang dibuat ulang akan membuang seluruh riwayat
/// navigasi setiap kali state provider berubah.
GoRouter buatRouter(LokasiAwal awal) => GoRouter(
  initialLocation: pathUntuk(awal),
  routes: <RouteBase>[
    GoRoute(
      path: '/onboarding',
      pageBuilder: (_, GoRouterState s) =>
          _halaman(s, const OnboardingScreen()),
    ),
    // Wajib ada: tombol "Lewati" di onboarding, tombol "Masuk" di profil, dan
    // tujuan setelah splash semuanya menuju '/auth'. Tanpa rute ini GoRouter
    // melempar `GoException: no routes for location: /auth` = aplikasi crash.
    GoRoute(
      path: '/auth',
      pageBuilder: (_, GoRouterState s) => _halaman(s, const AuthScreen()),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (_, GoRouterState s) => _halaman(s, const AppShell()),
    ),
    GoRoute(
      path: '/absen',
      pageBuilder: (_, GoRouterState s) => _halaman(
        s,
        const RoleGate(
          minimal: UserRole.anggota,
          child: AbsenScreen(),
        ),
      ),
    ),
    // Papan FISH warga. WAJIB ada di sini: aksi cepat di beranda dan kartu
    // di panel pengurus sama-sama menuju rute ini.
    GoRoute(
      path: '/aspirasi',
      pageBuilder: (_, GoRouterState s) => _halaman(
        s,
        const RoleGate(
          minimal: UserRole.warga,
          child: AspirasiScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/umkm',
      pageBuilder: (_, GoRouterState s) => _halaman(
        s,
        const RoleGate(
          minimal: UserRole.guest,
          child: UmkmScreen(),
        ),
      ),
    ),
    // Lapor darurat. Tanpa RoleGate: tamu pun harus bisa menekan tombol
    // merah saat keadaan nyata. Formnya tetap butuh session.
    GoRoute(
      path: '/darurat',
      pageBuilder: (_, GoRouterState s) => _halaman(s, const DaruratScreen()),
    ),
    // Galeri sebagai rute PENUH, bukan cuma tab. Hanya tamu/warga yang punya
    // tab Galeri; anggota ke atas mendapat tab "Kas" sebagai gantinya, jadi
    // tanpa rute ini anggota dan pengurus tidak punya cara membuka Galeri.
    GoRoute(
      path: '/galeri',
      pageBuilder: (_, GoRouterState s) => _halaman(s, const GaleriScreen()),
    ),
    // Tiga layar yang tadinya cuma SnackBar "segera hadir".
    GoRoute(
      path: '/edit-profil',
      pageBuilder: (_, GoRouterState s) => _halaman(
        s,
        const RoleGate(minimal: UserRole.warga, child: EditProfilScreen()),
      ),
    ),
    GoRoute(
      path: '/notifikasi',
      pageBuilder: (_, GoRouterState s) => _halaman(s, const NotifikasiScreen()),
    ),
    GoRoute(
      path: '/bantuan',
      pageBuilder: (_, GoRouterState s) => _halaman(s, const BantuanScreen()),
    ),
    // =====================================================================
    // ORDER: JASTIP & OJEK
    // ---------------------------------------------------------------------
    // Semua memakai `RoleGate(minimal: warga)`: tamu bisa melihat fitur,
    // tapi tidak boleh membuat order yang harus dibayar.
    // =====================================================================
    GoRoute(
      path: '/mitra-usaha',
      pageBuilder: (_, GoRouterState s) =>
          _halaman(s, const MitraUsahaScreen()),
    ),
    // Peta harus SEBELUM '/mitra-usaha/:id', kalau tidak path 'peta' akan
    // tertangkap sebagai id, jadi layar detail mitra yang terbuka.
    GoRoute(
      path: '/mitra-usaha/peta',
      pageBuilder: (_, GoRouterState s) =>
          _halaman(s, const MitraUsahaPetaScreen()),
    ),
    GoRoute(
      path: '/mitra-usaha/:id',
      pageBuilder: (_, GoRouterState s) => _halaman(
        s,
        MitraUsahaDetailScreen(id: s.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/pilih-lokasi',
      pageBuilder: (_, GoRouterState s) {
        final MintaLokasi minta = s.extra is MintaLokasi
            ? s.extra as MintaLokasi
            : const MintaLokasi();
        return _halaman(
          s,
          PilihLokasiPetaScreen(judul: minta.judul, awal: minta.awal),
        );
      },
    ),
    GoRoute(
      path: '/jastip/form',
      pageBuilder: (_, GoRouterState s) => _halaman(
        s,
        RoleGate(
          minimal: UserRole.warga,
          // Dari detail Mitra Usaha: lokasi beli terisi otomatis.
          child: JastipFormScreen(tokoAwal: s.extra as MitraUsaha?),
        ),
      ),
    ),
    GoRoute(
      path: '/ojek/form',
      pageBuilder: (_, GoRouterState s) => _halaman(
        s,
        const RoleGate(minimal: UserRole.warga, child: OjekFormScreen()),
      ),
    ),
    GoRoute(
      path: '/jastip/history',
      pageBuilder: (_, GoRouterState s) => _halaman(
        s,
        const RoleGate(
          minimal: UserRole.warga,
          child: OrderHistoryScreen(jenisAwal: JenisOrder.jastip),
        ),
      ),
    ),
    GoRoute(
      path: '/ojek/history',
      pageBuilder: (_, GoRouterState s) => _halaman(
        s,
        const RoleGate(
          minimal: UserRole.warga,
          child: OrderHistoryScreen(jenisAwal: JenisOrder.ojek),
        ),
      ),
    ),
    // Panel kendali pengurus: antrean FISH + sesi absensi.
    //
    // Rute ini TIDAK dihapus. Menu "Panel Pengurus" di Profil hanya muncul
    // untuk role pengurus, dan pengalih role di APK rilis sudah dimatikan
    // (lihat `AppConfig.roleSwitcher`), jadi warga biasa tidak pernah
    // menemukan jalan ke sini. File dan rutenya tetap disimpan supaya
    // fiturnya tetap bisa dipakai lagi begitu verifikasi dari pengurus hidup.
    GoRoute(
      path: '/pengurus',
      pageBuilder: (_, GoRouterState s) => _halaman(
        s,
        const RoleGate(
          minimal: UserRole.pengurus,
          child: PengurusScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/order/list',
      pageBuilder: (_, GoRouterState s) => _halaman(
        s,
        const RoleGate(minimal: UserRole.warga, child: OrderListScreen()),
      ),
    ),
    // `:jenis` terpisah dari `:id` dengan sengaja. Kalau keduanya digabung
    // jadi satu parameter dengan tanda titik dua di dalamnya, go_router bisa
    // salah membaca titik dua kedua sebagai awal parameter baru.
    GoRoute(
      path: '/order/tracking/:jenis/:id',
      pageBuilder: (_, GoRouterState s) => _halaman(
        s,
        RoleGate(
          minimal: UserRole.warga,
          child: OrderTrackingScreen(
            jenis: s.pathParameters['jenis'] ?? 'jastip',
            orderId: s.pathParameters['id'] ?? '',
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/order/detail/:jenis/:id',
      pageBuilder: (_, GoRouterState s) => _halaman(
        s,
        RoleGate(
          minimal: UserRole.warga,
          child: OrderDetailScreen(
            jenis: s.pathParameters['jenis'] ?? 'jastip',
            orderId: s.pathParameters['id'] ?? '',
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/order/rating/:jenis/:id',
      pageBuilder: (_, GoRouterState s) => _halaman(
        s,
        RoleGate(
          minimal: UserRole.warga,
          child: RatingScreen(
            jenis: s.pathParameters['jenis'] ?? 'jastip',
            orderId: s.pathParameters['id'] ?? '',
          ),
        ),
      ),
    ),
  ],
);
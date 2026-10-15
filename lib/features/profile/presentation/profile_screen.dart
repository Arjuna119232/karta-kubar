import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session.dart';
import '../../../core/auth/user_role.dart';
import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/pseudo_qr.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../core/data/data_providers.dart';
import '../domain/anggota.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Session session = ref.watch(sessionProvider);
    final UserRole role = session.efektif;
    final AuthUser? user = session.user;
    final String nama = user?.name ?? 'Warga KUNBAR';
    // Kartu anggota lewat repository, bukan data demo langsung.
    final Anggota anggota = ref.watch(profilProvider).valueOrNull ??
        Anggota.kosong;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, 16, AppSpacing.screen, 96),
        children: <Widget>[
          _Header(nama: nama, role: role),
          const SizedBox(height: 18),
          if (user != null && role.bisa(UserRole.anggota))
            _KartuAnggota(nama: nama, role: role, anggota: anggota)
          else
            _AjukanVerifikasi(role: role, sudahLogin: user != null),
          if (user != null && role.bisa(UserRole.anggota)) ...<Widget>[
            const SizedBox(height: 18),
            _Statistik(role: role, anggota: anggota),
          ],
          const SizedBox(height: 22),
          const SectionHeader(title: 'Hak akses kamu'),
          _HakAksesCard(role: role),
          const SectionHeader(title: 'Sumber data'),
          const _KartuBackend(),
          const SizedBox(height: AppSpacing.gap),
          if (AppConfig.demoMode) ...<Widget>[
            const _RoleSwitcher(),
            const SizedBox(height: AppSpacing.gap),
          ],
          const _MenuUmum(),
          if (user != null) ...<Widget>[
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
                ref.read(sessionProvider.notifier).keluar();
                ref.read(navigationIndexProvider.notifier).state = 0;
                context.go('/home');
              },
              icon: AppIcon(Ik.logout, color: context.colors.error),
              label: Text('Keluar',
                  style: TextStyle(color: context.colors.error)),
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.nama, required this.role});

  final String nama;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[role.warna, role.warna.withValues(alpha: 0.72)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('WK',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(nama,
                  style: context.text.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  AppIcon(role.ikon, size: 14, color: role.warna),
                  const SizedBox(width: 5),
                  Text(role.label,
                      style: context.text.bodySmall
                          ?.copyWith(color: role.warna)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KartuAnggota extends StatelessWidget {
  const _KartuAnggota({
    required this.nama,
    required this.role,
    required this.anggota,
  });

  final String nama;
  final UserRole role;

  /// Datanya lewat repository (lihat `profilProvider` di ProfileScreen).
  final Anggota anggota;

  @override
  Widget build(BuildContext context) {
    final List<Color> grad = context.semantic.heroGradient;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: grad,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'KARTU ANGGOTA DIGITAL',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  nama,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '${anggota.nomorAnggota} · ${role.label}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    anggota.divisi,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: PseudoQr(
              seed: anggota.nomorAnggota,
              size: 88,
              color: grad.first,
            ),
          ),
        ],
      ),
    );
  }
}

class _AjukanVerifikasi extends StatelessWidget {
  const _AjukanVerifikasi({required this.role, required this.sudahLogin});

  final UserRole role;
  final bool sudahLogin;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppIcon(Ik.shieldCheck,
                  color: role.warna, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sudahLogin ? 'Verifikasi warga' : 'Masuk untuk mulai',
                  style: context.text.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            sudahLogin
                ? 'Lengkapi NIK dan alamat Kuningan Barat agar bisa kirim aspirasi, lapor darurat, dan daftar kegiatan.'
                : 'Kamu sedang melihat sebagai tamu. Masuk untuk mengirim aspirasi, melapor darurat, dan mendaftar kegiatan.',
            style: context.text.bodyMedium
                ?.copyWith(color: context.semantic.textSecondary),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              if (!sudahLogin) {
                context.go('/auth');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Form verifikasi NIK sedang dibangun. Nanti diproses pengurus kelurahan.'),
                  ),
                );
              }
            },
            icon: AppIcon(
                sudahLogin ? Ik.badge : Ik.login,
                size: 18),
            label: Text(sudahLogin ? 'Verifikasi sekarang' : 'Masuk dulu'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Statistik extends StatelessWidget {
  const _Statistik({required this.role, required this.anggota});

  final UserRole role;
  final Anggota anggota;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _KartuAngka(
            icon: Ik.trophy,
            nilai: '${anggota.poin}',
            label: 'Poin kontribusi',
            warna: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.gap),
        Expanded(
          child: _KartuAngka(
            icon: Ik.checkCircle,
            nilai: '${anggota.totalKegiatan}',
            label: 'Kegiatan diikuti',
            warna: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _KartuAngka extends StatelessWidget {
  const _KartuAngka({
    required this.icon,
    required this.nilai,
    required this.label,
    required this.warna,
  });

  final Ik icon;
  final String nilai;
  final String label;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppIcon(icon, color: warna, size: 20),
          ),
          const SizedBox(height: 12),
          Text(nilai, style: context.text.headlineSmall),
          const SizedBox(height: 2),
          Text(label,
              style: context.text.bodySmall
                  ?.copyWith(color: context.semantic.textSecondary)),
        ],
      ),
    );
  }
}

class _HakAksesCard extends StatelessWidget {
  const _HakAksesCard({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppIcon(role.ikon, color: role.warna, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Level ${role.label}',
                    style: context.text.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            role.deskripsi,
            style: context.text.bodySmall
                ?.copyWith(color: context.semantic.textSecondary),
          ),
          const SizedBox(height: 14),
          for (final String h in role.hakAkses)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppIcon(Ik.checkCircle,
                      size: 16, color: role.warna),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(h, style: context.text.bodySmall),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Preview semua level akses. Ini alat bantu developer, bukan fitur produksi.
class _RoleSwitcher extends ConsumerWidget {
  const _RoleSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Session session = ref.watch(sessionProvider);
    final UserRole aktif = session.efektif;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppIcon(Ik.code,
                  size: 20, color: context.semantic.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Preview level akses',
                    style: context.text.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Alat bantu developer untuk melihat tampilan tiap role. Nanti diganti verifikasi dari pengurus.',
            style: context.text.bodySmall
                ?.copyWith(color: context.semantic.textSecondary),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final UserRole r in UserRole.values)
                _RoleChip(
                  role: r,
                  aktif: r == aktif,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final SessionNotifier ctrl =
                        ref.read(sessionProvider.notifier);
                    ref.read(navigationIndexProvider.notifier).state = 0;
                    if (r == UserRole.guest) {
                      ctrl.keluar();
                    } else {
                      ctrl.simpanRole(r);
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.role,
    required this.aktif,
    required this.onTap,
  });

  final UserRole role;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: aktif ? role.warna : role.warna.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppIcon(role.ikon,
                  size: 15, color: aktif ? Colors.white : role.warna),
              const SizedBox(width: 6),
              Text(
                role.label,
                style: context.text.labelSmall?.copyWith(
                  color: aktif ? Colors.white : role.warna,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuUmum extends ConsumerWidget {
  const _MenuUmum();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    final bool lansia = ref.watch(elderModeProvider);
    final UserRole role = ref.watch(sessionProvider).efektif;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          _Baris(
            icon: Ik.autoMode,
            label: 'Tema',
            trailing: SegmentedButton<ThemeMode>(
              segments: const <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    icon: AppIcon(Ik.autoMode, size: 18)),
                ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    icon: AppIcon(Ik.sun, size: 18)),
                ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    icon: AppIcon(Ik.moon, size: 18)),
              ],
              selected: <ThemeMode>{mode},
              showSelectedIcon: false,
              onSelectionChanged: (Set<ThemeMode> s) {
                HapticFeedback.selectionClick();
                ref.read(themeModeProvider.notifier).atur(s.first);
              },
            ),
          ),
          Divider(height: 1, color: context.semantic.line),
          _Baris(
            icon: Ik.accessibility,
            label: 'Mode lansia (teks lebih besar)',
            trailing: Switch(
              value: lansia,
              onChanged: (bool v) {
                HapticFeedback.selectionClick();
                ref.read(elderModeProvider.notifier).atur(v);
              },
            ),
          ),
          if (role.bisa(UserRole.warga)) ...<Widget>[
            Divider(height: 1, color: context.semantic.line),
            _Baris(
              icon: Ik.chat,
              label: 'Aspirasi & Laporan',
              onTap: () => context.go('/aspirasi'),
            ),
          ],
          if (role.bisa(UserRole.pengurus)) ...<Widget>[
            Divider(height: 1, color: context.semantic.line),
            _Baris(
              icon: Ik.adminShield,
              label: 'Panel Pengurus',
              onTap: () => context.go('/pengurus'),
            ),
          ],
          Divider(height: 1, color: context.semantic.line),
          _Baris(
            icon: Ik.edit,
            label: 'Edit profil',
            onTap: () => _segera(context, 'Edit profil'),
          ),
          Divider(height: 1, color: context.semantic.line),
          _Baris(
            icon: Ik.bell,
            label: 'Notifikasi',
            onTap: () => _segera(context, 'Notifikasi'),
          ),
          Divider(height: 1, color: context.semantic.line),
          _Baris(
            icon: Ik.help,
            label: 'Bantuan',
            onTap: () => _segera(context, 'Bantuan'),
          ),
        ],
      ),
    );
  }

  void _segera(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label segera hadir')),
    );
  }
}

class _Baris extends StatelessWidget {
  const _Baris({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  final Ik icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            AppIcon(icon, size: 21, color: context.semantic.textSecondary),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: context.text.titleSmall)),
            if (trailing != null)
              trailing!
            else
              AppIcon(Ik.chevronRight,
                  color: context.semantic.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Menampilkan sumber data yang sedang dipakai. Ini bukti bahwa lapisan
/// repository benar-benar bekerja: layar ini tidak tahu datanya dari perangkat
/// atau dari server, dia cuma membaca nama sumber dari repository.
class _KartuBackend extends ConsumerWidget {
  const _KartuBackend();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StatusBackend s = ref.watch(statusBackendProvider);
    final Color tone = s.supabaseSiap ? AppColors.success : AppColors.warning;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppIcon(s.supabaseSiap ? Ik.shieldCheck : Ik.cloudOff,
                  color: tone, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(s.sumber, style: context.text.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            s.supabaseSiap
                ? 'Terhubung ke Supabase. Data diambil dari server.'
                : 'Mode lokal aktif: aplikasi tetap jalan penuh tanpa internet. '
                    'Untuk menyalakan backend, isi .env lalu build dengan '
                    'SUMBER_DATA=supabase.',
            style: context.text.bodyMedium
                ?.copyWith(color: context.semantic.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            'Kunci API: ${s.ringkasanKunci}',
            style: context.text.labelSmall
                ?.copyWith(color: context.semantic.textSecondary),
          ),
        ],
      ),
    );
  }
}

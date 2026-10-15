import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session.dart';
import '../../../core/auth/user_role.dart';
import '../../aspirasi/data/aspirasi_state.dart';
import '../../aspirasi/domain/aspirasi.dart';
import '../../darurat/data/darurat_repository.dart';
import '../../darurat/domain/darurat.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_views.dart';
import '../../../shared/widgets/haptics.dart';

/// Edit profil. Sebelumnya hanya SnackBar "segera hadir".
///
/// Data disimpan ke sesi aplikasi (SharedPreferences lewat
/// [SessionNotifier]). Begitu backend Supabase menyala, repository profil yang
/// mengambil alih - UI ini tidak berubah.
class EditProfilScreen extends ConsumerStatefulWidget {
  const EditProfilScreen({super.key});

  @override
  ConsumerState<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends ConsumerState<EditProfilScreen> {
  late final TextEditingController _nama =
      TextEditingController(text: ref.read(sessionProvider).user?.name ?? '');
  late final TextEditingController _telepon =
      TextEditingController(text: ref.read(sessionProvider).user?.phone ?? '');
  final TextEditingController _nik = TextEditingController(
      text: ref.read(sessionProvider).user?.nik ?? '');
  final TextEditingController _alamat =
      TextEditingController(text: ref.read(sessionProvider).user?.alamat ?? '');
  final TextEditingController _rt =
      TextEditingController(text: ref.read(sessionProvider).user?.rt ?? '');
  final TextEditingController _rw =
      TextEditingController(text: ref.read(sessionProvider).user?.rw ?? '');

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _simpan = false;

  @override
  void dispose() {
    _nama.dispose();
    _telepon.dispose();
    _nik.dispose();
    _alamat.dispose();
    _rt.dispose();
    _rw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profil')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, 12, AppSpacing.screen, 32),
            children: <Widget>[
              const SectionHeader(title: 'Data dasar'),
              TextFormField(
                controller: _nama,
                textCapitalization: TextCapitalization.words,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Nama lengkap',
                  border: OutlineInputBorder(),
                ),
                validator: (String? v) => (v == null || v.trim().length < 3)
                    ? 'Nama minimal 3 huruf.'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _telepon,
                keyboardType: TextInputType.phone,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Nomor WhatsApp',
                  border: OutlineInputBorder(),
                ),
                validator: (String? v) {
                  final String t = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  if (t.length < 9 || t.length > 15) {
                    return 'Nomor WhatsApp 9-15 digit.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              const SectionHeader(title: 'Domisili'),
              Text(
                'NIK dan alamat dipakai untuk verifikasi warga. Yang mengisi '
                'otomatis verified adalah pengurus, bukan aplikasi.',
                style: context.text.bodySmall
                    ?.copyWith(color: context.semantic.textSecondary),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nik,
                keyboardType: TextInputType.number,
                maxLength: 16,
                decoration: const InputDecoration(
                  labelText: 'NIK (16 digit)',
                  border: OutlineInputBorder(),
                ),
                validator: (String? v) {
                  final String t = (v ?? '').trim();
                  if (t.isEmpty) return null; // boleh kosong
                  if (t.length != 16) return 'NIK harus 16 digit.';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _alamat,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 160,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _rt,
                      maxLength: 3,
                      decoration: const InputDecoration(
                        labelText: 'RT',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _rw,
                      maxLength: 3,
                      decoration: const InputDecoration(
                        labelText: 'RW',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Simpan perubahan',
                icon: Ik.check,
                loading: _simpan,
                onPressed: _simpan ? null : _simpanProfil,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _simpanProfil() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _simpan = true);

    final AuthUser lama = ref.read(sessionProvider).user ??
        const AuthUser(name: '', phone: '');
    await ref.read(sessionProvider.notifier).masuk(
          AuthUser(
            name: _nama.text.trim(),
            phone: _telepon.text.trim(),
            nik: _nik.text.trim().isEmpty ? null : _nik.text.trim(),
            alamat: _alamat.text.trim().isEmpty ? null : _alamat.text.trim(),
            rt: _rt.text.trim().isEmpty ? null : _rt.text.trim(),
            rw: _rw.text.trim().isEmpty ? null : _rw.text.trim(),
          ),
        );
    // `masuk` mengembalikan role ke 'warga' (itu perilaku signup), jadi role
    // lama dikembalikan supaya pemilik akun admin tidak kehilangan akses
    // hanya karenaheng edit profil.
    final UserRole saatIni = ref.read(sessionProvider).role;
    if (saatIni != UserRole.warga && lama.name.isNotEmpty) {
      await ref.read(sessionProvider.notifier).simpanRole(saatIni);
    }

    if (!mounted) return;
    setState(() => _simpan = false);
    Haptics.sedang();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil disimpan.')),
    );
  }
}

/// Daftar notifikasi.
///
/// Jujur soal statusnya: notifikasi belum datang dari server, jadi daftar
/// ini menampilkan **riwayat perubahan status laporan milikmu sendiri**
/// (FISH + darurat) - data yang benar-benar ada. Tidak ada pesan palsu
/// seperti "2 pengumuman baru".
class NotifikasiScreen extends ConsumerWidget {
  const NotifikasiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Aspirasi>> fish = ref.watch(aspirasiProvider);
    final AsyncValue<List<LaporanDarurat>> darurat = ref.watch(daruratProvider);

    final List<_Notif> items = <_Notif>[
      for (final Aspirasi f in fish.valueOrNull ?? <Aspirasi>[])
        _Notif(
          judul: f.judul,
          isi: 'Status FISH sekarang ${f.status.label.toLowerCase()}.',
          waktu: f.umur,
          ikon: Ik.chat,
          warna: f.status.warna,
          dibuat: f.dibuat,
        ),
      for (final LaporanDarurat g in darurat.valueOrNull ?? <LaporanDarurat>[])
        _Notif(
          judul: g.jenis.label,
          isi: 'Laporan darurat ${g.status.label.toLowerCase()}.',
          waktu: g.umur,
          ikon: Ik.megaphone,
          warna: g.status.warna,
          dibuat: g.dibuat,
        ),
    ]..sort((_Notif x, _Notif y) => y.urutan.compareTo(x.urutan)); // terbaru dulu

    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: SafeArea(
        top: false,
        child: items.isEmpty
            ? const AppEmptyState(
                title: 'Belum ada notifikasi',
                message: 'Notifikasi muncul saat status FISH atau laporan '
                    'darurat kamu berubah.',
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen, 12, AppSpacing.screen, 32),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.gap),
                  child: _KartuNotif(item: items[i]),
                ),
              ),
      ),
    );
  }
}

class _Notif {
  _Notif({
    required this.judul,
    required this.isi,
    required this.waktu,
    required this.ikon,
    required this.warna,
    DateTime? dibuat,
  }) : urutan = dibuat ?? DateTime.now();

  final String judul;
  final String isi;
  final String waktu;
  final Ik ikon;
  final Color warna;
  final DateTime urutan;
}

class _KartuNotif extends StatelessWidget {
  const _KartuNotif({required this.item});

  final _Notif item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.warna.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: AppIcon(item.ikon, size: 19, color: item.warna),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.judul,
                    style: context.text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(item.isi, style: context.text.bodyMedium),
                const SizedBox(height: 6),
                Text(
                  item.waktu,
                  style: context.text.labelSmall
                      ?.copyWith(color: context.semantic.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bantuan: pertanyaan yang sering muncul + cara menghubungi pengurus.
class BantuanScreen extends StatelessWidget {
  const BantuanScreen({super.key});

  static const List<(String, String)> _faq = <(String, String)>[
    (
      'Bagaimana cara jadi anggota karang taruna?',
      'Daftar lewat kelurahan atau balai RW. Setelah terdaftar, pengurus '
      'mengaktifkan akun ke level Anggota KT.',
    ),
    (
      'Kenapa laporan saya belum ditanggapi?',
      'Statusnya terlihat di papan Aspirasi. Pengurus biasanya memprioritaskan '
          'tidak terduga. Laporan berstatus Baru biasanya diproses 1-3 hari.',
    ),
    (
      'Apakah data saya aman?',
      'Data profil hanya dipakai untuk verifikasi warga dan tidak dibagikan '
          'ke pihak luar.',
    ),
    (
      'Kenapa businesses UMKM saya belum ada centang?',
      'Centang berarti sudah diperiksa pengurus. Ajukan dulu lewat menu UMKM.',
    ),
    (
      'Bagaimana melapor keadaan darurat?',
      'Pakai tombol Lapor Darurat di beranda. Untuk HELP langsung ke nomor '
          'resmi 112/119/110/115.',
    ),
    (
      'Aplikasi ini butuh internet?',
      'Untuk kirim laporan dan buka data terbaru, ya. Data yang sudah '
          'terbuka tetap bisa dibaca tanpa sinyal.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bantuan')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, 12, AppSpacing.screen, 32),
          children: <Widget>[
            for (final (String q, String a) in _faq)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.gap),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(q, style: context.text.titleSmall),
                      const SizedBox(height: 6),
                      Text(a, style: context.text.bodyMedium),
                    ],
                  ),
                ),
              ),
            const SectionHeader(title: 'Hubungi pengurus'),
            AppCard(
              child: Row(
                children: <Widget>[
                  AppIcon(Ik.phone, color: context.colors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'RW 05 - Kuningan Barat. Nomor telepon pengurus bisa diperoleh di balai RW pada jam kerja.',
                      style: context.text.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import 'otp_screen.dart';
import '../../../shared/widgets/app_icon.dart';
import '../domain/validasi.dart';

enum AuthMode { masuk, daftar }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nama = TextEditingController();
  final TextEditingController _telepon = TextEditingController(text: '62');
  bool _setuju = false;
  AuthMode _mode = AuthMode.masuk;

  @override
  void dispose() {
    _nama.dispose();
    _telepon.dispose();
    super.dispose();
  }

  // Aturannya ada di domain, bukan di sini, supaya bisa diuji tanpa merakit
  // seluruh form dan bisa dipakai ulang untuk mode email (Supabase).
  String? _validNama(String? v) =>
      ValidasiAkun.nama(v, wajib: _mode == AuthMode.daftar);

  String? _validTelepon(String? v) => ValidasiAkun.telepon(v);

  void _submit() {
    FocusScope.of(context).unfocus();
    final bool valid = _formKey.currentState?.validate() ?? false;
    if (!_setuju) {
      _snack('Kamu harus menyetujui Syarat & Ketentuan dulu');
      return;
    }
    if (!valid) return;
    final String nomor = ValidasiAkun.keFormatInternasional(_telepon.text);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OtpScreen(
          nomor: nomor,
          nama: _mode == AuthMode.daftar ? _nama.text.trim() : '',
        ),
      ),
    );
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final bool daftar = _mode == AuthMode.daftar;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen + 8, 8, AppSpacing.screen + 8, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const AppIcon(Ik.arrowBack, size: 18),
                    label: const Text('Lewati dulu'),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Text(
                        'KK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  daftar ? 'Daftar keanggotaan' : 'Selamat datang kembali',
                  textAlign: TextAlign.center,
                  style: context.text.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  daftar
                      ? 'Lengkapi data dasar kamu sebagai anggota.'
                      : 'Masuk untuk melihat kegiatan dan iuran kamu.',
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium
                      ?.copyWith(color: context.semantic.textSecondary),
                ),
                const SizedBox(height: 24),
                _ModeSwitch(
                  mode: _mode,
                  onChanged: (AuthMode m) => setState(() {
                    _mode = m;
                    _formKey.currentState?.reset();
                  }),
                ),
                const SizedBox(height: 22),
                if (daftar) ...<Widget>[
                  _Label('Nama lengkap'),
                  TextFormField(
                    controller: _nama,
                    textCapitalization: TextCapitalization.words,
                    validator: _validNama,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Ahmad Fauzi',
                      prefixIcon: AppIcon(Ik.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _Label('Nomor WhatsApp'),
                TextFormField(
                  controller: _telepon,
                  keyboardType: TextInputType.phone,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  validator: _validTelepon,
                  decoration: const InputDecoration(
                    hintText: '6281234567890',
                    prefixIcon: AppIcon(Ik.phone),
                    helperText: 'Tanpa tanda +, contoh: 6281234567890',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _setuju,
                        activeColor: context.colors.primary,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        onChanged: (bool? v) =>
                            setState(() => _setuju = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _setuju = !_setuju),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: RichText(
                            text: TextSpan(
                              style: context.text.bodySmall,
                              children: <InlineSpan>[
                                const TextSpan(
                                    text: 'Saya menyetujui '),
                                TextSpan(
                                  text: 'Syarat & Ketentuan',
                                  style: TextStyle(
                                    color: context.colors.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const TextSpan(
                                    text: ' serta Kebijakan Privasi KUNBAR Connect.'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: daftar ? 'Daftar & kirim OTP' : 'Kirim OTP',
                  icon: Ik.chat,
                  onPressed: _submit,
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: 'Jelajahi tanpa masuk',
                  tone: PrimaryButtonTone.outlined,
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: context.text.labelMedium
            ?.copyWith(color: context.semantic.textSecondary),
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.mode, required this.onChanged});

  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.semantic.line,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        children: <Widget>[
          _Tab(
            label: 'Masuk',
            active: mode == AuthMode.masuk,
            onTap: () => onChanged(AuthMode.masuk),
          ),
          _Tab(
            label: 'Daftar',
            active: mode == AuthMode.daftar,
            onTap: () => onChanged(AuthMode.daftar),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? context.semantic.card : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            boxShadow: active
                ? <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: context.text.labelLarge?.copyWith(
              color: active
                  ? context.colors.primary
                  : context.semantic.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
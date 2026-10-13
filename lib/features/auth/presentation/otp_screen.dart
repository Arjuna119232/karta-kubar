import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';

/// Kode demo karena backend belum aktif.
const String _kodeDemo = '123456';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.nomor, this.nama = ''});

  final String nomor;
  final String nama;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final TextEditingController _kode = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _timer;
  int _sisa = 30;

  @override
  void initState() {
    super.initState();
    _kode.addListener(() => setState(() {}));
    _mulaiTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _kode.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _mulaiTimer() {
    _timer?.cancel();
    _sisa = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return;
      setState(() => _sisa -= 1);
      if (_sisa <= 0) t.cancel();
    });
  }

  bool get _lengkap => _kode.text.length == 6;

  void _verifikasi() {
    if (!_lengkap) return;
    FocusScope.of(context).unfocus();
    if (_kode.text != _kodeDemo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode OTP salah. Untuk demo pakai kode 123456.'),
        ),
      );
      return;
    }
    final String nama =
        widget.nama.trim().isEmpty ? 'Warga KUBAR' : widget.nama.trim();
    ref.read(sessionProvider.notifier).masuk(
          AuthUser(name: nama, phone: widget.nomor),
        );
    HapticFeedback.mediumImpact();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final String tampil = _kode.text;

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen + 8, 8, AppSpacing.screen + 8, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.sms_rounded,
                      size: 34, color: context.colors.primary),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Masukkan kode OTP',
                textAlign: TextAlign.center,
                style: context.text.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  style: context.text.bodyMedium
                      ?.copyWith(color: context.semantic.textSecondary),
                  children: <InlineSpan>[
                    const TextSpan(text: 'Kode 6 digit dikirim ke WhatsApp '),
                    TextSpan(
                      text: widget.nomor,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: context.semantic.textSecondary,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 62,
                child: Stack(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List<Widget>.generate(6, (int i) {
                        final bool isi = i < tampil.length;
                        final bool aktif = _focus.hasFocus && i == tampil.length;
                        return _Kotak(
                          digit: isi ? tampil[i] : '',
                          aktif: aktif,
                        );
                      }),
                    ),
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0,
                        child: TextField(
                          controller: _kode,
                          focusNode: _focus,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Kode demo: 123456',
                textAlign: TextAlign.center,
                style: context.text.bodySmall
                    ?.copyWith(color: context.semantic.textSecondary),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Verifikasi',
                icon: Icons.check_rounded,
                onPressed: _lengkap ? _verifikasi : null,
              ),
              const SizedBox(height: 12),
              Center(
                child: _sisa > 0
                    ? Text(
                        'Kirim ulang kode dalam ${_sisa}s',
                        style: context.text.bodySmall
                            ?.copyWith(color: context.semantic.textSecondary),
                      )
                    : TextButton(
                        onPressed: _mulaiTimer,
                        child: const Text('Kirim ulang kode'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Kotak extends StatelessWidget {
  const _Kotak({required this.digit, required this.aktif});

  final String digit;
  final bool aktif;

  @override
  Widget build(BuildContext context) {
    final bool isi = digit.isNotEmpty;
    return Container(
      width: 52,
      height: 62,
      decoration: BoxDecoration(
        color: context.semantic.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isi || aktif) ? context.colors.primary : context.semantic.line,
          width: isi || aktif ? 1.6 : 1,
        ),
      ),
      child: Center(
        child: Text(
          digit,
          style: context.text.headlineSmall
              ?.copyWith(color: context.colors.primary),
        ),
      ),
    );
  }
}
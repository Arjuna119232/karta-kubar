import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Kartu kaca untuk layer atas peta. Blur dipakai, TAPI teks selalu ikut
/// diletakkan di atas panel solid (bukan di dalam area blur) supaya tidak
/// pernah buram di HP Android.
class Kaca extends StatelessWidget {
  const Kaca({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 22,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final gelap = Theme.of(context).brightness == Brightness.dark;
    final isi = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (gelap ? const Color(0xFF101014) : Colors.white)
                .withValues(alpha: gelap ? 0.62 : 0.82),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 6)),
            ],
          ),
          child: child,
        ),
      ),
    );
    if (onTap == null) return isi;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: isi,
    );
  }
}

/// Tombol gradien besar (AKTIFKAN / NONAKTIFKAN).
class TombolGradien extends StatefulWidget {
  const TombolGradien({
    super.key,
    required this.judul,
    required this.gradien,
    required this.onTekan,
    this.denyut = false,
    this.subjudul,
    this.ikon,
  });

  final String judul;
  final String? subjudul;
  final Gradient gradien;
  final VoidCallback onTekan;

  /// true = denyut pelan saat status aktif (menarik mata tanpa mengganggu).
  final bool denyut;
  final IconData? ikon;

  @override
  State<TombolGradien> createState() => _TombolGradienState();
}

class _TombolGradienState extends State<TombolGradien>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    if (widget.denyut) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant TombolGradien old) {
    super.didUpdateWidget(old);
    if (widget.denyut && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.denyut && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: widget.gradien,
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: [
              BoxShadow(
                color: widget.gradien.colors.first.withValues(alpha: 0.28 + 0.18 * t),
                blurRadius: 18 + 12 * t,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTekan,
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 68),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.ikon != null) ...[
                      Icon(widget.ikon, color: Colors.white, size: 30),
                      const SizedBox(width: 12),
                    ],
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.judul,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                          if (widget.subjudul != null)
                            Text(
                              widget.subjudul!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Kotak aksi cepat: ikon berwarna + label.
class KotakAksi extends StatelessWidget {
  const KotakAksi({
    super.key,
    required this.ikon,
    required this.warna,
    required this.judul,
    required this.onTekan,
    this.lencana,
    this.subjudul,
  });

  final IconData ikon;
  final Color warna;
  final String judul;
  final String? subjudul;
  final int? lencana;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTekan,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: warna.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(ikon, color: warna, size: 26),
                  ),
                  if ((lencana ?? 0) > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${lencana!}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(judul,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              if (subjudul != null)
                Text(subjudul!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
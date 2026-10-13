import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/data/seed_data.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/pseudo_qr.dart';
import '../../../shared/widgets/stat_tile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthUser? user = ref.watch(authUserProvider);
    final String nama = user?.name ?? SeedData.memberName;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, 16, AppSpacing.screen, 96),
        children: <Widget>[
          _ProfileHeader(nama: nama),
          const SizedBox(height: 20),
          const _MemberCard(),
          const SizedBox(height: 18),
          const Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  icon: Icons.emoji_events_rounded,
                  value: '340',
                  label: 'Poin kegiatan',
                  tint: AppColors.warning,
                ),
              ),
              SizedBox(width: AppSpacing.gap),
              Expanded(
                child: StatTile(
                  icon: Icons.check_circle_rounded,
                  value: '18',
                  label: 'Kegiatan diikuti',
                  tint: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                _MenuRow(
                  icon: Icons.edit_outlined,
                  label: 'Edit profil',
                  onTap: () => _soon(context, 'Edit profil'),
                ),
                Divider(height: 1, color: context.semantic.line),
                _MenuRow(
                  icon: Icons.badge_outlined,
                  label: 'Kartu anggota digital',
                  onTap: () => _soon(context, 'Kartu anggota'),
                ),
                Divider(height: 1, color: context.semantic.line),
                _MenuRow(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifikasi',
                  onTap: () => _soon(context, 'Notifikasi'),
                ),
                Divider(height: 1, color: context.semantic.line),
                _MenuRow(
                  icon: Icons.help_outline_rounded,
                  label: 'Bantuan',
                  onTap: () => _soon(context, 'Bantuan'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gap),
          AppCard(
            padding: EdgeInsets.zero,
            child: const _ThemeRow(),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () {
              ref.read(authUserProvider.notifier).state = null;
              context.go('/auth');
            },
            icon: Icon(Icons.logout_rounded, color: context.colors.error),
            label: Text('Keluar',
                style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
    );
  }

  void _soon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label segera hadir')),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.nama});

  final String nama;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[Color(0xFF1B5E20), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'SK',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(nama, style: context.text.titleLarge),
              const SizedBox(height: 2),
              Text(
                '${SeedData.memberDivision} · ${SeedData.memberRole}',
                style: context.text.bodySmall
                    ?.copyWith(color: context.semantic.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard();

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'KARTU ANGGOTA',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  SeedData.memberName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  SeedData.memberId,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Aktif 2026',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: PseudoQr(seed: SeedData.memberId, size: 96, color: grad.first),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 22, color: context.semantic.textSecondary),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: context.text.titleSmall)),
            Icon(Icons.chevron_right_rounded,
                color: context.semantic.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _ThemeRow extends ConsumerWidget {
  const _ThemeRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: <Widget>[
          Icon(Icons.brightness_6_outlined,
              size: 22, color: context.semantic.textSecondary),
          const SizedBox(width: 14),
          Expanded(child: Text('Tema', style: context.text.titleSmall)),
          SegmentedButton<ThemeMode>(
            segments: const <ButtonSegment<ThemeMode>>[
              ButtonSegment<ThemeMode>(
                  value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded, size: 18)),
              ButtonSegment<ThemeMode>(
                  value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded, size: 18)),
              ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded, size: 18)),
            ],
            selected: <ThemeMode>{mode},
            showSelectedIcon: false,
            onSelectionChanged: (Set<ThemeMode> s) {
              HapticFeedback.selectionClick();
              ref.read(themeModeProvider.notifier).state = s.first;
            },
          ),
        ],
      ),
    );
  }
}

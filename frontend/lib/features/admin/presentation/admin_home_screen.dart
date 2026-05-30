import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../../shared/widgets/modern_card.dart';
import '../../../shared/utils/animations.dart';
import '../../../core/theme.dart';
import '../../../core/typography.dart';
import '../../auth/state/auth_controller.dart';
import '../../schools/data/school_dtos.dart';
import '../../schools/data/school_repository.dart';

/// Landing screen for SCHOOL_ADMIN. Lists the schools owned by the current
/// user (filtered client-side because the backend `/api/schools` endpoint
/// doesn't expose an `?owner=me` filter today; the DB does have an
/// `adminId` FK on `school` so we can reuse the public list).
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  bool _loading = false;
  String? _error;
  List<School> _schools = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(schoolRepositoryProvider);
      // Pull a generous page (100) and filter client-side. School admins
      // typically own a handful of schools; cheap enough.
      final user = ref.read(authControllerProvider).user;
      final page =
          await repo.list(SchoolListFilters(adminId: user?.id, limit: 100));
      setState(() {
        _schools = page.items;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;
    return ResponsiveShell(
      title: 'School admin',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Welcome${user != null ? ', ${user.fullName}' : ''}!',
              style: TextStyles.pageHeading),
          const SizedBox(height: 8),
          Text(
            "Manage your schools, submit verification documents, and post "
            "announcements. Followers receive your announcements automatically.",
            style: TextStyles.pageSubheading,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('My schools', style: TextStyles.pageHeading),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading && _schools.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            ModernCard(
              backgroundColor: AppColors.errorLight,
              padding: const EdgeInsets.all(16),
              elevated: false,
              bordered: true,
              child: Text(
                _error!,
                style: TextStyle(color: AppColors.error),
              ),
            )
          else if (_schools.isEmpty)
            ModernCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You haven\'t registered a school yet.',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => context.go('/admin/schools/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('Register your school'),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                for (int index = 0; index < _schools.length; index++)
                  AppAnimations.slideInListItem(
                    delay: Duration(milliseconds: index * 50),
                    child: ModernCard(
                      onTap: () => context.go('/admin/schools/${_schools[index].id}'),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _schools[index].schoolName,
                                  style: TextStyles.cardTitle,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    _buildStatusChip(
                                      _schools[index].curriculum.label(),
                                      AppColors.textSecondary,
                                    ),
                                    _buildStatusChip(
                                      _schools[index].verificationStatus.label(),
                                      _getVerificationColor(_schools[index].verificationStatus),
                                    ),
                                    if ((_schools[index].followerCount ?? 0) > 0)
                                      _buildStatusChip(
                                        '${_schools[index].followerCount} follower(s)',
                                        AppColors.primary,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: 'View public page',
                                onPressed: () => context.go('/schools/${_schools[index].id}'),
                                icon: const Icon(Icons.open_in_new),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.surfaceVariant,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Manage',
                                onPressed: () =>
                                    context.go('/admin/schools/${_schools[index].id}'),
                                icon: const Icon(Icons.settings_outlined),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  foregroundColor: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 24),
          AppAnimations.tapScale(
            onTap: () => context.go('/admin/announcements'),
            child: InfoCard(
              title: 'Announcements',
              description: 'Post updates that fan out to every parent who follows one of your schools.',
              icon: Icons.campaign_outlined,
              iconColor: AppColors.accent,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getVerificationColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return AppColors.success;
      case VerificationStatus.pending:
        return AppColors.warning;
      case VerificationStatus.rejected:
        return AppColors.error;
      case VerificationStatus.revoked:
        return AppColors.error;
    }
  }
}

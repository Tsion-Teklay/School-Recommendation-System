import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../../../shared/widgets/modern_card.dart';
import '../../../shared/widgets/custom_components.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/illustrations.dart';
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
          SpacingHelper.sm,
          Text(
            "Manage your schools, submit verification documents, and post "
            "announcements. Followers receive your announcements automatically.",
            style: TextStyles.pageSubheading,
          ),
          SpacingHelper.xxl,
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
          SpacingHelper.sm,
          if (_loading && _schools.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            ModernCard(
              backgroundColor: AppColors.errorLight,
              padding: const EdgeInsets.all(AppSpacing.lg),
              elevated: false,
              bordered: true,
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
              ),
            )
          else if (_schools.isEmpty)
            EmptyState(
              illustrationType: IllustrationType.emptySchools,
              title: 'You haven\'t registered a school yet',
              description: 'Register your school to start managing announcements, achievements, and verification documents.',
              actionLabel: 'Register your school',
              onAction: () => context.go('/admin/schools/create'),
            )
          else
            Column(
              children: [
                for (int index = 0; index < _schools.length; index++)
                  AppAnimations.slideInListItem(
                    delay: Duration(milliseconds: index * 50),
                    child: ModernCard(
                      onTap: () => context.go('/admin/schools/${_schools[index].id}'),
                      padding: const EdgeInsets.all(AppSpacing.lg),
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
                                SpacingHelper.sm,
                                Wrap(
                                  spacing: AppSpacing.lg,
                                  runSpacing: AppSpacing.xs,
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
                          SizedBox(width: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.xs,
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
          SpacingHelper.xxl,
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
    return AppBadge(
      label: label,
      color: color,
      small: true,
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

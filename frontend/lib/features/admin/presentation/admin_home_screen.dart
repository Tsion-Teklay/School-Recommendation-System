import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/responsive_shell.dart';
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
      final page = await repo.list( SchoolListFilters(adminId: user?.id, limit: 100));
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
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            "Manage your schools, submit verification documents, and post "
            "announcements. Followers receive your announcements automatically.",
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('My schools', style: theme.textTheme.titleLarge),
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
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!),
              ),
            )
          else if (_schools.isEmpty)
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(  
                  children: [  
                    const Text('You haven\'t registered a school yet.'),  
                    const SizedBox(height: 12),  
                    FilledButton.icon(  
                      onPressed: () => context.go('/admin/schools/create'),  
                      icon: const Icon(Icons.add),  
                      label: const Text('Register your school'),  
                    ),  
                  ],  
                ), 
              ),
            )
          else
            Column(
              children: [
                for (final s in _schools)
                  Card(
                    child: ListTile(
                      title: Text(s.schoolName),
                      subtitle: Text(
                        '${s.curriculum.label()} · ${s.verificationStatus.label()}'
                        '${(s.followerCount ?? 0) > 0 ? ' · ${s.followerCount} follower(s)' : ''}',
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            tooltip: 'View public page',
                            onPressed: () => context.go('/schools/${s.id}'),
                            icon: const Icon(Icons.open_in_new),
                          ),
                          IconButton(
                            tooltip: 'Manage',
                            onPressed: () =>
                                context.go('/admin/schools/${s.id}'),
                            icon: const Icon(Icons.settings_outlined),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Announcements', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    "Post updates that fan out to every parent who follows "
                    "one of your schools.",
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => context.go('/admin/announcements'),
                    icon: const Icon(Icons.campaign_outlined),
                    label: const Text('Manage announcements'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/presentation/admin_home_screen.dart';
import '../../auth/data/auth_dtos.dart';
import '../../auth/state/auth_controller.dart';
import '../../moderation/presentation/moderation_reports_screen.dart';
import '../../moe/presentation/moe_home_screen.dart';
import '../../recommendations/presentation/recommendations_screen.dart';

/// Role-routed home. Each role lands on its own portal:
///
/// - **Parent** → recommendations dashboard (Phase 8 headline feature).
/// - **School admin** → my-schools list + verification + announcements
///   (Phase 9 admin portal).
/// - **MoE / Ministry** → analytics dashboard + verification queue + ministry
///   announcements (Phase 9 MoE portal).
/// - **Moderator** → reports queue (Phase 9 moderation portal).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    switch (user?.role) {
      case UserRole.parent:
        return const RecommendationsScreen();
      case UserRole.schoolAdmin:
        return const AdminHomeScreen();
      case UserRole.moeOfficer:
        return const MoeHomeScreen();
      case UserRole.moderator:
        return const ModerationReportsScreen();
      case null:
        // Auth redirect will kick in; render an empty placeholder so we
        // don't briefly flash a stub before navigation completes.
        return const Scaffold(body: SizedBox.shrink());
    }
  }
}

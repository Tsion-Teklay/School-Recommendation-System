import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../../announcements/data/announcement_dtos.dart';
import '../../announcements/data/announcement_repository.dart';
import '../../announcements/presentation/announcements_feed_screen.dart';
import '../../auth/data/auth_dtos.dart';
import '../../auth/state/auth_controller.dart';
import '../../reviews/presentation/reviews_section.dart';
import '../data/school_dtos.dart';
import '../data/school_repository.dart'; // Added to ensure access to schoolRepositoryProvider
import '../state/compare_cart.dart';
import '../state/school_detail_controller.dart';
import 'school_analytics_section.dart';

/// `/schools/:id` — full info card, map (when lat/lng present), follower
/// count + follow toggle, facility image carousel, recent announcements,
/// and the embedded reviews section (Phase 11).
class SchoolDetailScreen extends ConsumerStatefulWidget {
  final int schoolId;
  final int?
      recommendationId; // 1. Accept the telemetry context tracker identifier

  const SchoolDetailScreen({
    super.key,
    required this.schoolId,
    this.recommendationId,
  });

  @override
  ConsumerState<SchoolDetailScreen> createState() => _SchoolDetailScreenState();
}

class _SchoolDetailScreenState extends ConsumerState<SchoolDetailScreen> {
  Map<int, int> _ratingDistribution = {};
  bool _ratingLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRatingDistribution();  

    if (widget.recommendationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await ref.read(schoolRepositoryProvider).updateInteractionResult(
                recommendationId: widget.recommendationId!,
                schoolId: widget.schoolId,
                result: 'OPENED',
              );
        } catch (e) {
          debugPrint('Telemetry extraction error (OPENED): $e');
        }
      });
    }
  }

  Future<void> _loadRatingDistribution() async {
    setState(() => _ratingLoading = true);
    try {
      final distribution = await ref
          .read(schoolRepositoryProvider)
          .getRatingDistribution(widget.schoolId);
      if (mounted) {
        setState(() => _ratingDistribution = distribution);
      }
    } catch (e) {
      debugPrint('Failed to load rating distribution: $e');
    } finally {
      if (mounted) setState(() => _ratingLoading = false);
    }
  }

  void _refreshRatingDistribution() async {  
  setState(() {  
    _ratingLoading = true;  
  });  
  try {  
    final distribution = await ref.read(schoolRepositoryProvider)  
        .getRatingDistribution(widget.schoolId);  
    if (mounted) {  
      setState(() {  
        _ratingDistribution = distribution;  
        _ratingLoading = false;  
      });  
    }  
  } catch (e) {  
    if (mounted) {  
      setState(() {  
        _ratingLoading = false;  
      });  
    }  
  }  
}

  Future<void> _showRevokeConfirmationDialog() async {
    final reasonController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will revoke the school\'s verification status. '
              'The school will not be able to make announcements. '
              'Please provide a reason for this action.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for revocation *',
                hintText: 'Explain why the verification is being revoked',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (result == true) {
      try {
        await ref
            .read(schoolRepositoryProvider)
            .revokeVerification(widget.schoolId, reason);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification revoked successfully')),
        );
        // Get the controller here instead of using ctl
        ref.read(schoolDetailControllerProvider(widget.schoolId)).load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to revoke: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctl = ref.watch(schoolDetailControllerProvider(widget.schoolId));
    final state = ctl.state;
    final auth = ref.watch(authControllerProvider);
    final isParent = auth.user?.role == UserRole.parent;
    final cart = ref.watch(compareCartProvider);

    Widget body;
    if (state.loading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (state.error != null && state.school == null) {
      body = _ErrorState(
        message: state.error!,
        onRetry: ctl.load,
      );
    } else {
      body = _DetailBody(
        school: state.school!,
        isParent: isParent,
        userRole: auth.user?.role,
        isFollowing: state.isFollowing,
        followBusy: state.followBusy,
        recommendationId: widget.recommendationId,
        onToggleFollow: () async {
          if (!state.isFollowing && widget.recommendationId != null) {
            try {
              await ref.read(schoolRepositoryProvider).followWithInteraction(
                    schoolId: widget.schoolId,
                    recommendationId: widget.recommendationId,
                  );
              ctl.load();
            } catch (e) {
              ctl.load();
            }
          } else {
            ctl.toggleFollow();
          }
        },
        onRevokeVerification: auth.user?.role == UserRole.moeOfficer
            ? _showRevokeConfirmationDialog
            : null,
        cart: cart,
        latestError: state.error,
        ratingDistribution: _ratingDistribution,
        onReviewSubmitted: _refreshRatingDistribution,
      );
    }

    return ResponsiveShell(
      title: state.school?.schoolName ?? 'School',
      leading: BackButton(onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/schools');
        }
      }),
      child: body,
    );
  }
}

// Keep the rest of the existing implementations (_DetailBody, _FacilityImagesCarousel, etc.) intact below...
class _DetailBody extends StatelessWidget {
  final School school;
  final bool isParent;
  final UserRole? userRole;
  final bool isFollowing;
  final bool followBusy;
  final int? recommendationId;
  final VoidCallback onToggleFollow;
  final VoidCallback? onRevokeVerification;
  final CompareCart cart;
  final String? latestError;
  final Map<int, int> ratingDistribution;
   final VoidCallback? onReviewSubmitted;

  const _DetailBody({
    required this.school,
    required this.isParent,
    required this.userRole,
    required this.isFollowing,
    required this.followBusy,
    this.recommendationId,
    required this.onToggleFollow,
    this.onRevokeVerification,
    required this.cart,
    required this.latestError,
    required this.ratingDistribution,
      this.onReviewSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inCart = cart.contains(school.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (latestError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      latestError!,
                      style:
                          TextStyle(color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(school.schoolName, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(school.subCity != null ? '${school.subCity} - ${school.woreda ?? 'N/A'}' : 'No location info', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Badge(
                      icon: Icons.school_outlined,
                      label: school.curriculum.label(),
                    ),
                    if (school.schoolLevel != null)
                      _Badge(
                        icon: Icons.grade_outlined,
                        label: school.schoolLevel!.label(),
                      ),
                    _Badge(
                      icon: Icons.payments_outlined,
                      label: 'Fee: ${school.tuitionFee}',
                    ),
                    if ((school.rating ?? 0) > 0)
                      _Badge(
                        icon: Icons.star_outline,
                        label:
                            '${(school.rating ?? 0).toStringAsFixed(1)} (${school.reviewCount ?? 0} reviews)',
                      ),
                    _Badge(
                      icon: school.verificationStatus ==
                              VerificationStatus.verified
                          ? Icons.verified_outlined
                          : Icons.help_outline,
                      label: school.verificationStatus.label(),
                      highlighted: school.verificationStatus ==
                          VerificationStatus.verified,
                    ),
                    _Badge(
                      icon: Icons.people_outline,
                      label:
                          '${school.followerCount ?? 0} follower${(school.followerCount ?? 0) == 1 ? '' : 's'}',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ContactRow(
                  icon: Icons.email_outlined,
                  label: school.contactEmail,
                ),
                if (school.contactPhone != null &&
                    school.contactPhone!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ContactRow(
                    icon: Icons.phone_outlined,
                    label: school.contactPhone!,
                  ),
                ],
                if (school.facilities != null &&
                    school.facilities!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Facilities', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(school.facilities!, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (isParent)
                      FilledButton.icon(
                        onPressed: followBusy ? null : onToggleFollow,
                        icon: Icon(isFollowing
                            ? Icons.notifications_off_outlined
                            : Icons.notifications_active_outlined),
                        label: Text(isFollowing ? 'Unfollow' : 'Follow'),
                      ),
                    if (isParent)
                      OutlinedButton.icon(
                        onPressed: () {
                          if (inCart) {
                            cart.remove(school.id);
                          } else {
                            final added = cart.add(school);
                            if (!added) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Compare cart is full (max 5).'),
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(inCart
                            ? Icons.check_box
                            : Icons.compare_arrows_outlined),
                        label:
                            Text(inCart ? 'In compare cart' : 'Add to compare'),
                      ),
                    if (isParent)
                      OutlinedButton.icon(
                        onPressed: () => context.go('/schools/${school.id}/analytics'),
                        icon: const Icon(Icons.bar_chart_outlined),
                        label: const Text('Analytics'),
                      ),
                    if (onRevokeVerification != null &&
                        school.verificationStatus ==
                            VerificationStatus.verified)
                      FilledButton.icon(
                        onPressed: onRevokeVerification,
                        icon: const Icon(Icons.block),
                        label: const Text('Revoke Verification'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (school.facilityImages.isNotEmpty) ...[
          _FacilityImagesCarousel(images: school.facilityImages),
          const SizedBox(height: 16),
        ],
        if (school.latitude != null && school.longitude != null) ...[
          _MapCard(
            lat: school.latitude!,
            lng: school.longitude!,
            schoolName: school.schoolName,
          ),
          const SizedBox(height: 16),
        ],
        if (school.passingRate != null || school.nationalExamScore != null)
          SchoolAnalyticsSection(
            school: school,
            ratingDistribution: ratingDistribution,
          ),
        _SchoolAnnouncementsSection(schoolId: school.id),
        const SizedBox(height: 16),
        ReviewsSection(schoolId: school.id, onReviewSubmitted: onReviewSubmitted),
      ],
    );
  }
}

class _FacilityImagesCarousel extends StatelessWidget {
  final List<FacilityImage> images;
  const _FacilityImagesCarousel({required this.images});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Facility photos', style: theme.textTheme.titleLarge),
                const Spacer(),
                Text('${images.length}', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final img = images[i];
                  return GestureDetector(
                    onTap: () => _openLightbox(context, img),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _absoluteImage(img.imageUrl),
                        width: 280,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 280,
                          color: theme.colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLightbox(BuildContext context, FacilityImage img) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: Image.network(
            _absoluteImage(img.imageUrl),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _SchoolAnnouncementsSection extends ConsumerStatefulWidget {
  final int schoolId;
  const _SchoolAnnouncementsSection({required this.schoolId});

  @override
  ConsumerState<_SchoolAnnouncementsSection> createState() =>
      _SchoolAnnouncementsSectionState();
}

class _SchoolAnnouncementsSectionState
    extends ConsumerState<_SchoolAnnouncementsSection> {
  bool _loading = true;
  String? _error;
  List<Announcement> _items = const [];

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
      final result = await ref.read(announcementRepositoryProvider).list(
            schoolId: widget.schoolId,
            limit: 5,
          );
      if (!mounted) return;
      setState(() => _items = result.items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Recent announcements', style: theme.textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      context.go('/announcements?schoolId=${widget.schoolId}'),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!)),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No announcements yet.'),
              )
            else
              Column(
                children: [
                  for (final a in _items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: AnnouncementCard(
                        announcement: a,
                        onTap: () => context.go('/announcements/${a.id}'),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final double lat;
  final double lng;
  final String schoolName;
  const _MapCard({
    required this.lat,
    required this.lng,
    required this.schoolName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 280,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(lat, lng),
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom |
                  InteractiveFlag.drag |
                  InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.schoolrec.app',
              maxZoom: 19,
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(lat, lng),
                  width: 40,
                  height: 40,
                  child: Tooltip(
                    message: schoolName,
                    child: Icon(
                      Icons.location_on,
                      size: 40,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;
  const _Badge({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = highlighted
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final fg = highlighted
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: fg)),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ContactRow({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Flexible(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

String _absoluteImage(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('/')) return '${AppConfig.apiBaseUrl}$url';
  return '${AppConfig.apiBaseUrl}/$url';
}

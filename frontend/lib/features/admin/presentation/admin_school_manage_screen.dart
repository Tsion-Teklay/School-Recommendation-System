import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config.dart';
import '../../../shared/utils/image_picker.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../../auth/data/auth_repository.dart';
import '../../schools/data/school_dtos.dart';
import '../../schools/data/school_repository.dart';
import '../../verification/data/verification_dtos.dart';
import '../../verification/data/verification_repository.dart';

/// Manage one school I own. Shows core info + follower count, links out to
/// the public detail page, and surfaces a verification submit form +
/// status of any prior verification requests for this school.
class AdminSchoolManageScreen extends ConsumerStatefulWidget {
  final int schoolId;
  const AdminSchoolManageScreen({super.key, required this.schoolId});

  @override
  ConsumerState<AdminSchoolManageScreen> createState() =>
      _AdminSchoolManageScreenState();
}

class _AdminSchoolManageScreenState
    extends ConsumerState<AdminSchoolManageScreen> {
  bool _loading = false;
  String? _error;
  School? _school;
  List<VerificationRequest> _requests = const [];

  bool _submitting = false;
  String? _submitError;
  final _notesCtrl = TextEditingController();
  final List<PickedFile> _picked = [];

  // Phase 11 — facility image upload state.
  bool _uploadingImage = false;
  String? _imageError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final school =
          await ref.read(schoolRepositoryProvider).getById(widget.schoolId);
      final reqs =
          await ref.read(verificationRepositoryProvider).list(limit: 50);
      setState(() {
        _school = school;
        _requests =
            reqs.items.where((r) => r.schoolId == widget.schoolId).toList();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addStubFile() async {
    // We don't pull in `file_picker` for the MVP; we let the admin describe
    // a single placeholder note and build a tiny in-memory stub file for
    // submission. End-to-end testing on web can swap this for a real file
    // picker in a follow-up. For now, prompt the admin to type a filename
    // and we'll send a minimal text payload as the document.
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Attach a placeholder document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'File picker integration ships separately. Until then, submit '
              'a placeholder describing the document name; the MoE reviewer '
              'will follow up offline if needed.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Filename (e.g. license.pdf)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Attach')),
        ],
      ),
    );
    if (ok != true || controller.text.trim().isEmpty) return;
    final name = controller.text.trim();
    final bytes = Uint8List.fromList('Placeholder content for $name'.codeUnits);
    setState(() {
      _picked.add(PickedFile(filename: name, bytes: bytes));
    });
  }

  Future<void> _pickAndUploadFacilityImage() async {
    setState(() {
      _uploadingImage = true;
      _imageError = null;
    });
    try {
      final picked = await pickImageFromUser();
      if (picked == null) {
        setState(() => _uploadingImage = false);
        return;
      }
      await ref.read(schoolRepositoryProvider).uploadFacilityImage(
            schoolId: widget.schoolId,
            filename: picked.filename,
            bytes: picked.bytes,
            contentType: picked.contentType,
          );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Facility image uploaded.')),
      );
    } on ApiException catch (e) {
      setState(() => _imageError = e.message);
    } catch (e) {
      setState(() => _imageError = e.toString());
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _deleteFacilityImage(FacilityImage img) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete photo?'),
        content: const Text(
            'This will remove the image from the school detail page.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton.tonal(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(schoolRepositoryProvider).deleteFacilityImage(
            schoolId: widget.schoolId,
            imageId: img.id,
          );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _submitVerification() async {
    if (_picked.isEmpty) {
      setState(() => _submitError = 'Attach at least one document.');
      return;
    }
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await ref.read(verificationRepositoryProvider).submit(
            schoolId: widget.schoolId,
            documents: _picked,
            notes:
                _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );
      if (!mounted) return;
      _picked.clear();
      _notesCtrl.clear();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification request submitted.')),
      );
    } on ApiException catch (e) {
      setState(() => _submitError = e.message);
    } catch (e) {
      setState(() => _submitError = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ResponsiveShell(
      title: _school?.schoolName ?? 'Manage school',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/admin'),
      ),
      child: _loading && _school == null
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          : _error != null
              ? Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                      padding: const EdgeInsets.all(16), child: Text(_error!)),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_school != null) _SchoolSummary(school: _school!),
                    const SizedBox(height: 16),
                    if (_school != null)
                      _FacilityImagesCard(
                        images: _school!.facilityImages,
                        uploading: _uploadingImage,
                        error: _imageError,
                        onAdd: _pickAndUploadFacilityImage,
                        onDelete: _deleteFacilityImage,
                      ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Submit verification request',
                                style: theme.textTheme.titleLarge),
                            const SizedBox(height: 8),
                            const Text(
                              "Attach proof-of-license documents (PDF/PNG/JPEG, "
                              "≤10MB each, up to 5 files). The MoE will review "
                              "and approve or reject the request.",
                            ),
                            const SizedBox(height: 12),
                            if (_picked.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final f in _picked)
                                    InputChip(
                                      label: Text(f.filename),
                                      onDeleted: () =>
                                          setState(() => _picked.remove(f)),
                                    ),
                                ],
                              ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _notesCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Notes for reviewer (optional)',
                              ),
                              minLines: 1,
                              maxLines: 3,
                            ),
                            if (_submitError != null) ...[
                              const SizedBox(height: 8),
                              Text(_submitError!,
                                  style: TextStyle(
                                      color: theme.colorScheme.error)),
                            ],
                            const SizedBox(height: 12),
                            // We use `Wrap` rather than `Row + Spacer +
                            // FilledButton.icon` because the latter combo
                            // silently drops the trailing button on the
                            // Flutter web release build (see Phase 9 PR
                            // #22 review thread).
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              spacing: 12,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _submitting ? null : _addStubFile,
                                  icon: const Icon(Icons.attach_file),
                                  label: const Text('Attach document'),
                                ),
                                FilledButton.icon(
                                  onPressed:
                                      _submitting ? null : _submitVerification,
                                  icon: _submitting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Icon(Icons.send),
                                  label: const Text('Submit'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Past verification requests',
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    if (_requests.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No verification requests yet.'),
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (final r in _requests)
                            _VerificationRequestTile(req: r),
                        ],
                      ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.go('/schools/${widget.schoolId}'),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open public school page'),
                      ),
                    ],
                  ],
                ),
    );
  }
}

class _FacilityImagesCard extends StatelessWidget {
  final List<FacilityImage> images;
  final bool uploading;
  final String? error;
  final VoidCallback onAdd;
  final Future<void> Function(FacilityImage img) onDelete;
  const _FacilityImagesCard({
    required this.images,
    required this.uploading,
    required this.error,
    required this.onAdd,
    required this.onDelete,
  });

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
            const SizedBox(height: 4),
            Text(
              'PNG / JPEG / WebP, ≤10MB. These show up in the carousel '
              'on the public school detail page.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error!,
                        style: TextStyle(
                            color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (images.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No photos uploaded yet.'),
              )
            else
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final img = images[i];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _absoluteImage(img.imageUrl),
                            width: 180,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 180,
                              height: 140,
                              color: theme.colorScheme.surfaceContainerHighest,
                              alignment: Alignment.center,
                              child: const Icon(
                                  Icons.image_not_supported_outlined),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.white, size: 18),
                              tooltip: 'Delete',
                              onPressed: () => onDelete(img),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: uploading ? null : onAdd,
              icon: uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_a_photo),
              label: Text(uploading ? 'Uploading…' : 'Add photo'),
            ),
          ],
        ),
      ),
    );
  }
}

String _absoluteImage(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('/')) return '${AppConfig.apiBaseUrl}$url';
  return '${AppConfig.apiBaseUrl}/$url';
}

class _SchoolSummary extends StatelessWidget {
  final School school;
  const _SchoolSummary({required this.school});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(school.schoolName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(school.address, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(school.curriculum.label())),
                Chip(label: Text(school.verificationStatus.label())),
                if (school.tuitionFee > 0)
                  Chip(
                    avatar: const Icon(Icons.payments_outlined, size: 18),
                    label: Text('${school.tuitionFee} / year'),
                  ),
                if ((school.followerCount ?? 0) > 0)
                  Chip(
                    avatar: const Icon(Icons.favorite_outline, size: 18),
                    label: Text('${school.followerCount} follower(s)'),
                  ),
                if ((school.rating ?? 0) > 0)
                  Chip(
                    avatar: const Icon(Icons.star_outline, size: 18),
                    label: Text(
                      '${(school.rating!).toStringAsFixed(1)} '
                      '(${school.reviewCount ?? 0})',
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

class _VerificationRequestTile extends StatelessWidget {
  final VerificationRequest req;
  const _VerificationRequestTile({required this.req});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    switch (req.status) {
      case VerificationRequestStatus.approved:
        color = theme.colorScheme.tertiary;
        break;
      case VerificationRequestStatus.rejected:
        color = theme.colorScheme.error;
        break;
      case VerificationRequestStatus.pending:
        color = theme.colorScheme.primary;
        break;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  backgroundColor: color.withValues(alpha: 0.15),
                  label:
                      Text(req.status.label(), style: TextStyle(color: color)),
                ),
                const Spacer(),
                Text(
                  req.submittedAt.toIso8601String().substring(0, 10),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            if (req.notes?.isNotEmpty ?? false) ...[
              const SizedBox(height: 6),
              Text('Notes: ${req.notes}'),
            ],
            if (req.reviewNotes?.isNotEmpty ?? false) ...[
              const SizedBox(height: 6),
              Text('Reviewer: ${req.reviewNotes}'),
            ],
            if (req.documents.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Documents (${req.documents.length}):'),
              for (final d in req.documents)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Text('· ${d.originalName ?? d.url}',
                      style: theme.textTheme.bodySmall),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../../admin/presentation/admin_announcements_screen.dart';
import '../../announcements/data/announcement_dtos.dart';
import '../../announcements/data/announcement_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/state/auth_controller.dart';
import '../../../shared/utils/image_picker.dart';

/// MoE-only announcements: only ministry-level posts (no schoolId). Hits
/// `/api/announcements/moe`.
class MoeAnnouncementsScreen extends ConsumerStatefulWidget {
  const MoeAnnouncementsScreen({super.key});

  @override
  ConsumerState<MoeAnnouncementsScreen> createState() =>
      _MoeAnnouncementsScreenState();
}

class _MoeAnnouncementsScreenState
    extends ConsumerState<MoeAnnouncementsScreen> {
  bool _loading = false;
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
      final me = ref.read(authControllerProvider).user;
      final result = await ref
          .read(announcementRepositoryProvider)
          .list(limit: 50);
      setState(() {
        _items = result.items
            .where((a) =>
                a.publisherType == PublisherType.moe &&
                (me == null || a.publisherId == me.id))
            .toList();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _compose() async {
    final result = await showDialog<AnnouncementComposeResult>(
      context: context,
      builder: (_) => const AnnouncementComposeDialog(
        schools: [],
        forMoE: true,
      ),
    );
    if (result == null) return;
    try {
      final repo = ref.read(announcementRepositoryProvider);
      final created = await repo.createForMoe(result.input);
      // Phase 11 — attach the optional banner image after creation.
      if (result.image != null) {
        await repo.uploadImage(
          id: created.id,
          filename: result.image!.filename,
          bytes: result.image!.bytes,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ministry announcement published.')),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(Announcement a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete announcement?'),
        content: const Text('This action cannot be undone.'),
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
      await ref.read(announcementRepositoryProvider).delete(a.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _edit(Announcement a) async {
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => _EditAnnouncementDialog(announcement: a),
      );
      if (result == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement updated successfully')),
        );
        await _load();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open edit dialog: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ResponsiveShell(
      title: 'Ministry announcements',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _compose,
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null)
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!),
              ),
            ),
          if (_loading && _items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                  child: Text('No ministry announcements yet. Tap New.')),
            )
          else
            for (final a in _items)
              InkWell(
                onTap: () => context.push('/announcements/${a.id}'),
                borderRadius: BorderRadius.circular(12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(a.title,
                                  style: theme.textTheme.titleMedium),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'edit') _edit(a);
                                if (v == 'delete') _delete(a);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                    value: 'edit', child: Text('Edit')),
                                PopupMenuItem(
                                    value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 6,
                          children: [
                            Chip(label: Text(a.category.label())),
                            Chip(label: Text(a.urgencyLevel.label())),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(a.content),
                        const SizedBox(height: 8),
                        Text(
                          a.datePosted.toIso8601String().substring(0, 16),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

// Phase 11: the dedicated MoE compose dialog was retired in favor of the
// shared `AnnouncementComposeDialog` (forMoE=true) so the image-attachment
// path is identical across roles.

/// Edit dialog for MoE announcements with image management support
class _EditAnnouncementDialog extends ConsumerStatefulWidget {
  final Announcement announcement;
  const _EditAnnouncementDialog({required this.announcement});

  @override
  ConsumerState<_EditAnnouncementDialog> createState() => _EditAnnouncementDialogState();
}

class _EditAnnouncementDialogState extends ConsumerState<_EditAnnouncementDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late AnnouncementCategory _selectedCategory;
  late UrgencyLevel _selectedUrgency;
  bool _isSubmitting = false;
  PickedImage? _pickedImage;
  bool _removeExistingImage = false;
  String? _pickError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement.title);
    _contentController = TextEditingController(text: widget.announcement.content);
    _selectedCategory = widget.announcement.category;
    _selectedUrgency = widget.announcement.urgencyLevel;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _pickError = null);
    try {
      final picked = await pickImageFromUser();
      if (picked == null) return;
      setState(() {
        _pickedImage = picked;
        _removeExistingImage = false;
      });
    } catch (e) {
      setState(() => _pickError = 'Failed to pick image: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImage = null;
      _removeExistingImage = true;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final input = AnnouncementInput(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
        urgencyLevel: _selectedUrgency,
        schoolId: widget.announcement.schoolId,
      );
      
      final repo = ref.read(announcementRepositoryProvider);
      
      // Update the announcement text fields
      await repo.update(widget.announcement.id, input);
      
      // Handle image changes
      if (_pickedImage != null) {
        // Upload new image (replaces existing if any)
        await repo.uploadImage(
          id: widget.announcement.id,
          filename: _pickedImage!.filename,
          bytes: _pickedImage!.bytes,
        );
      } else if (_removeExistingImage && widget.announcement.imgUrl != null) {
        // Remove existing image
        await repo.deleteImage(widget.announcement.id);
      }
      
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasExistingImage = widget.announcement.imgUrl != null && widget.announcement.imgUrl!.isNotEmpty;
    final displayImage = _pickedImage ?? (hasExistingImage && !_removeExistingImage ? widget.announcement.imgUrl : null);
    
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Announcement',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Content field
                      TextFormField(
                        controller: _contentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Content',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Content is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Category and Urgency in a row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<AnnouncementCategory>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                filled: true,
                                fillColor: theme.colorScheme.surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: AnnouncementCategory.values.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category.label()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedCategory = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<UrgencyLevel>(
                              value: _selectedUrgency,
                              decoration: InputDecoration(
                                labelText: 'Urgency',
                                filled: true,
                                fillColor: theme.colorScheme.surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: UrgencyLevel.values.map((level) {
                                return DropdownMenuItem(
                                  value: level,
                                  child: Text(level.label()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedUrgency = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Image section
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image preview or placeholder
                            if (displayImage != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: _pickedImage != null
                                    ? Image.memory(
                                        _pickedImage!.bytes,
                                        width: double.infinity,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        _absoluteImage(widget.announcement.imgUrl!),
                                        width: double.infinity,
                                        height: 150,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: double.infinity,
                                          height: 150,
                                          color: theme.colorScheme.surfaceContainerHighest,
                                          child: const Icon(Icons.image_not_supported_outlined, size: 40),
                                        ),
                                      ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate, 
                                        size: 40, 
                                        color: theme.colorScheme.onSurfaceVariant),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No image selected',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Image actions
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  if (displayImage != null)
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _removeImage,
                                        icon: const Icon(Icons.delete_outline, size: 18),
                                        label: const Text('Remove', style: TextStyle(fontSize: 12)),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                      ),
                                    ),
                                  if (displayImage != null) const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: _pickImage,
                                      icon: Icon(displayImage == null ? Icons.add_photo_alternate : Icons.swap_horiz, size: 18),
                                      label: Text(displayImage == null ? 'Add Image' : 'Replace', style: TextStyle(fontSize: 12)),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_pickError != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _pickError!,
                            style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Footer actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Changes'),
                  ),
                ],
              ),
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/location_helper.dart';

import '../../../core/config.dart';
import '../../../shared/utils/image_picker.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../../../shared/widgets/custom_components.dart';
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

  bool _editing = false;  
  bool _saving = false;
  String? _saveError;

  final _editSchoolName = TextEditingController();
  final _editContactEmail = TextEditingController();
  final _editContactPhone = TextEditingController();
  final _editTuitionFee = TextEditingController();
  final _editFacilities = TextEditingController();
  final _editLatitude = TextEditingController();
  final _editLongitude = TextEditingController();
  final _editWoreda = TextEditingController();
  final _editStreetName = TextEditingController();

  Curriculum? _editCurriculum;
  SchoolLevel? _editSchoolLevel;
  SchoolType? _editSchoolType;
  SubCity? _editSubCity; 

  bool _fetchingLocation = false;
  LatLng? _pin;
  static const _defaultCentre = LatLng(9.0331, 38.7501);

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
    _editSchoolName.dispose();
    _editContactEmail.dispose();
    _editContactPhone.dispose();
    _editTuitionFee.dispose();
    _editFacilities.dispose();
    _editLatitude.dispose();
    _editLongitude.dispose();
    _editWoreda.dispose();
    _editStreetName.dispose();
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
  try {  
    final result = await FilePicker.platform.pickFiles(  
      type: FileType.custom,  
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],  
      withData: true,  
    );  
  
    if (result == null || result.files.isEmpty) return;  
  
    final file = result.files.first;  
      
    // Validate file size (10MB limit)  
    if (file.size > 10 * 1024 * 1024){  
      if (!mounted) return;  
      ScaffoldMessenger.of(context).showSnackBar(  
        const SnackBar(content: Text('File size exceeds 10MB limit')),  
      );  
      return;  
    }  
  
    // Get MIME type  
    String? contentType;  
    if (file.extension != null) {  
      switch (file.extension!.toLowerCase()) {  
        case 'pdf':  
          contentType = 'application/pdf';  
          break;  
        case 'png':  
          contentType = 'image/png';  
          break;  
        case 'jpg':  
        case 'jpeg':  
          contentType = 'image/jpeg';  
          break;  
      }  
    }  
  
    if (file.bytes == null) {  
      if (!mounted) return;  
      ScaffoldMessenger.of(context).showSnackBar(  
        const SnackBar(content: Text('Failed to read file')),  
      );  
      return;  
    }  
  
    setState(() {  
      _picked.add(PickedFile(  
        filename: file.name,  
        bytes: file.bytes!,  
        contentType: contentType,  
      ));  
    });  
  } catch (e) {  
    if (!mounted) return;  
    ScaffoldMessenger.of(context).showSnackBar(  
      SnackBar(content: Text('Error picking file: ${e.toString()}')),  
    );  
  }  
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

void _startEdit() {
  if (_school == null) return;
  setState(() {
    _editing = true;
    _saveError = null;
    _editSchoolName.text = _school!.schoolName;
    _editContactEmail.text = _school!.contactEmail ?? '';
    _editContactPhone.text = _school!.contactPhone ?? '';
    _editTuitionFee.text = _school!.tuitionFee?.toString() ?? '';
    _editFacilities.text = _school!.facilities ?? '';
    _editLatitude.text = _school!.latitude?.toString() ?? '';
    _editLongitude.text = _school!.longitude?.toString() ?? '';
    _editWoreda.text = _school!.woreda ?? '';
    _editStreetName.text = _school!.streetName ?? '';
    if (_school!.latitude != null &&
    _school!.longitude != null) {
  _pin = LatLng(
    _school!.latitude!,
    _school!.longitude!,
  );
}
    _editCurriculum = _school!.curriculum;
    _editSchoolLevel = _school!.schoolLevel;
    _editSchoolType = _school!.schoolType;
    _editSubCity = _school!.subCity;
  });
}

void _cancelEdit() {  
  setState(() {  
    _editing = false;  
    _saveError = null;  
  });  
}

Future<void> _saveEdit() async {
  if (_school == null) return;
  setState(() {
    _saving = true;
    _saveError = null;
  });
  try {
    final updated = await ref.read(schoolRepositoryProvider).update(
          id: _school!.id,
          schoolName: _editSchoolName.text.trim().isEmpty
              ? null
              : _editSchoolName.text.trim(),
          contactEmail: _editContactEmail.text.trim().isEmpty
              ? null
              : _editContactEmail.text.trim(),
          contactPhone: _editContactPhone.text.trim().isEmpty
              ? null
              : _editContactPhone.text.trim(),
          curriculum: _editCurriculum,
          schoolLevel: _editSchoolLevel,
          schoolType: _editSchoolType,
          subCity: _editSubCity,
          woreda: _editWoreda.text.trim().isEmpty
              ? null
              : _editWoreda.text.trim(),
          streetName: _editStreetName.text.trim().isEmpty
              ? null
              : _editStreetName.text.trim(),
          tuitionFee: _editTuitionFee.text.trim().isEmpty
              ? null
              : num.tryParse(_editTuitionFee.text.trim()),
          facilities: _editFacilities.text.trim().isEmpty
              ? null
              : _editFacilities.text.trim(),
          latitude: _editLatitude.text.trim().isEmpty
              ? null
              : double.tryParse(_editLatitude.text.trim()),
          longitude: _editLongitude.text.trim().isEmpty
              ? null
              : double.tryParse(_editLongitude.text.trim()),
        );
    if (!mounted) return;
    setState(() {
      _school = updated;
      _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('School updated successfully')),
    );
  } on ApiException catch (e) {
    setState(() => _saveError = e.message);
  } catch (e) {
    setState(() => _saveError = e.toString());
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}

Future<void> _fetchLocation() async {
  setState(() => _fetchingLocation = true);

  try {
    final loc = await LocationHelper.getCurrentPosition();

    if (loc != null) {
      final point = LatLng(loc.latitude, loc.longitude);

      setState(() {
        _pin = point;

        _editLatitude.text =
            point.latitude.toStringAsFixed(6);

        _editLongitude.text =
            point.longitude.toStringAsFixed(6);
      });
    }
  } catch (e) {
    setState(() => _saveError = e.toString());
  } finally {
    if (mounted) {
      setState(() => _fetchingLocation = false);
    }
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
                    if (_school != null)  
                    _SchoolSummary(
                      school: _school!,
                      editing: _editing,
                      saving: _saving,
                      saveError: _saveError,
                      onEdit: _startEdit,
                      onCancel: _cancelEdit,
                      onSave: _saveEdit,
                      controllers: [
                        _editSchoolName,
                        _editContactEmail,
                        _editContactPhone,
                        _editTuitionFee,
                        _editFacilities,
                        _editLatitude,
                        _editLongitude,
                        _editWoreda,
                        _editStreetName,
                      ],
                      editCurriculum: _editCurriculum,
                      editSchoolLevel: _editSchoolLevel,
                      editSchoolType: _editSchoolType,
                      editSubCity: _editSubCity,
                      onCurriculumChanged: (v) => setState(() => _editCurriculum = v),
                      onSchoolLevelChanged: (v) => setState(() => _editSchoolLevel = v),
                      onSchoolTypeChanged: (v) => setState(() => _editSchoolType = v),
                      onSubCityChanged: (v) => setState(() => _editSubCity = v),
                      fetchingLocation: _fetchingLocation,
onFetchLocation: _fetchLocation,
pin: _pin,
onPinChanged: (latLng) {
  setState(() {
    _pin = latLng;

    _editLatitude.text =
        latLng.latitude.toStringAsFixed(6);

    _editLongitude.text =
        latLng.longitude.toStringAsFixed(6);
  });
}, 
                    ),
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
                            Text('School Demographics', style: theme.textTheme.titleLarge),
                            const SizedBox(height: 8),
                            const Text(
                              'Manage yearly academic performance data including student counts, passing rates, and exam scores.',
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () => context.go('/admin/schools/${widget.schoolId}/demographics'),
                              icon: const Icon(Icons.bar_chart_outlined),
                              label: const Text('Manage Demographics'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('School Achievements', style: theme.textTheme.titleLarge),
                            const SizedBox(height: 8),
                            const Text(
                              'Submit and manage school achievements (Gold/Silver/Bronze) for MoE verification.',
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () => context.go('/admin/schools/${widget.schoolId}/achievements'),
                              icon: const Icon(Icons.emoji_events_outlined),
                              label: const Text('Manage Achievements'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Staff Breakdown', style: theme.textTheme.titleLarge),
                            const SizedBox(height: 8),
                            const Text(
                              'Manage staff qualification breakdown by education level (PhD, Masters, Degree, etc.).',
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () => context.go('/admin/schools/${widget.schoolId}/staff-breakdown'),
                              icon: const Icon(Icons.people_outline),
                              label: const Text('Manage Staff Breakdown'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_school != null && _school!.verificationStatus != VerificationStatus.verified)
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
  final bool editing;
  final bool saving;
  final String? saveError;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  final List<TextEditingController> controllers;

  final Curriculum? editCurriculum;
  final SchoolLevel? editSchoolLevel;
  final SchoolType? editSchoolType;
  final SubCity? editSubCity;

  final ValueChanged<Curriculum?> onCurriculumChanged;
  final ValueChanged<SchoolLevel?> onSchoolLevelChanged;
  final ValueChanged<SchoolType?> onSchoolTypeChanged;
  final ValueChanged<SubCity?> onSubCityChanged;

  final bool fetchingLocation;
  final VoidCallback onFetchLocation;

  final LatLng? pin;
  final ValueChanged<LatLng> onPinChanged;

  const _SchoolSummary({
  required this.school,
  required this.editing,
  required this.saving,
  this.saveError,
  required this.onEdit,
  required this.onCancel,
  required this.onSave,
  required this.controllers,
  this.editCurriculum,
  this.editSchoolLevel,
  this.editSchoolType,
  this.editSubCity,
  required this.onCurriculumChanged,
  required this.onSchoolLevelChanged,
  required this.onSchoolTypeChanged,
  required this.onSubCityChanged,
  required this.fetchingLocation,
  required this.onFetchLocation,
  required this.pin,
  required this.onPinChanged,
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
                Expanded(  
                  child: Text(  
                    editing ? 'Edit school' : school.schoolName,  
                    style: theme.textTheme.headlineSmall,  
                  ),  
                ),  
                if (!editing)  
                  IconButton(  
                    tooltip: 'Edit',  
                    onPressed: onEdit,  
                    icon: const Icon(Icons.edit_outlined),  
                  ),  
              ],  
            ),  
            if (!editing) ...[  
              const SizedBox(height: 4),  
                
              const SizedBox(height: 12),  
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppBadge(
                    label: school.curriculum.label(),
                    small: true,
                  ),
                  AppBadge(
                    label: school.verificationStatus.label(),
                    small: true,
                  ),
                  if ((school.tuitionFee ?? 0) > 0)
                    AppBadge(
                      icon: Icons.payments_outlined,
                      label: '${school.tuitionFee} / year',
                      small: true,
                    ),
                  if ((school.followerCount ?? 0) > 0)
                    AppBadge(
                      icon: Icons.favorite_outline,
                      label: '${school.followerCount} follower(s)',
                      small: true,
                    ),
                  if ((school.rating ?? 0) > 0)
                    AppBadge(
                      icon: Icons.star_outline,
                      label:
                          '${(school.rating!).toStringAsFixed(1)} (${school.reviewCount ?? 0})',
                      small: true,
                    ),  
                ],  
              ),  
            ],  
            if (editing) ...[  
              const SizedBox(height: 16),  
              if (saveError != null) ...[  
                Container(  
                  padding: const EdgeInsets.all(12),  
                  decoration: BoxDecoration(  
                    color: theme.colorScheme.errorContainer,  
                    borderRadius: BorderRadius.circular(8),  
                  ),  
                  child: Text(  
                    saveError!,  
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),  
                  ),  
                ),  
                const SizedBox(height: 16),  
              ],  
              TextFormField(  
                controller: controllers[0],  
                decoration: const InputDecoration(  
                  labelText: 'School name',  
                  border: OutlineInputBorder(),  
                ),  
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers[1],
                decoration: const InputDecoration(
                  labelText: 'Contact email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),  
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers[2],
                decoration: const InputDecoration(
                  labelText: 'Contact phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SubCity>(
                decoration: const InputDecoration(
                  labelText: 'Sub-city',
                  border: OutlineInputBorder(),
                ),
                value: editSubCity,
                items: SubCity.values.map((subCity) {
                  return DropdownMenuItem(value: subCity, child: Text(subCity.label));
                }).toList(),
                onChanged: onSubCityChanged,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers[7],
                decoration: const InputDecoration(
                  labelText: 'Woreda',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers[8],
                decoration: const InputDecoration(
                  labelText: 'Street Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Curriculum>(  
                decoration: const InputDecoration(  
                  labelText: 'Curriculum',  
                  border: OutlineInputBorder(),  
                ),  
                value: editCurriculum,  
                items: Curriculum.values  
                    .map((c) => DropdownMenuItem(  
                          value: c,  
                          child: Text(c.label()),  
                        ))  
                    .toList(),  
                onChanged: onCurriculumChanged,  
              ),  
              const SizedBox(height: 12),
              DropdownButtonFormField<SchoolLevel>(
                decoration: const InputDecoration(
                  labelText: 'School level',
                  border: OutlineInputBorder(),
                ),
                value: editSchoolLevel,
                items: SchoolLevel.values
                    .map((l) => DropdownMenuItem(
                          value: l,
                          child: Text(l.label()),
                        ))
                    .toList(),
                onChanged: onSchoolLevelChanged,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SchoolType>(
                decoration: const InputDecoration(
                  labelText: 'School type',
                  border: OutlineInputBorder(),
                ),
                value: editSchoolType,
                items: SchoolType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label()),
                        ))
                    .toList(),
                onChanged: onSchoolTypeChanged,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers[3],
                decoration: const InputDecoration(
                  labelText: 'Tuition fee',
                  border: OutlineInputBorder(),
                  prefixText: 'ETB ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers[4],
                decoration: const InputDecoration(
                  labelText: 'Facilities',
                  border: OutlineInputBorder(),
                ),  
                maxLines: 3,  
              ),  
              const SizedBox(height: 12),  
              Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        Expanded(
          child: Text(
            'Location',
            style: theme.textTheme.titleSmall,
          ),
        ),
        TextButton.icon(
          onPressed: fetchingLocation
              ? null
              : onFetchLocation,
          icon: fetchingLocation
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.my_location,
                  size: 18,
                ),
          label: const Text(
            'Use current location',
          ),
        ),
      ],
    ),

    const SizedBox(height: 12),

    Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controllers[5],
            decoration: const InputDecoration(
              labelText: 'Latitude',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final lat = double.tryParse(value);
              final lng = double.tryParse(
                controllers[6].text,
              );

              if (lat != null && lng != null) {
                onPinChanged(LatLng(lat, lng));
              }
            },
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: TextFormField(
            controller: controllers[6],
            decoration: const InputDecoration(
              labelText: 'Longitude',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final lat = double.tryParse(
                controllers[5].text,
              );

              final lng = double.tryParse(value);

              if (lat != null && lng != null) {
                onPinChanged(LatLng(lat, lng));
              }
            },
          ),
        ),
      ],
    ),

    const SizedBox(height: 16),

    _MapPicker(
      pin: pin ?? const LatLng(9.0331, 38.7501),
      hasPin: pin != null,
      onTap: (latLng) {
        onPinChanged(latLng);
      },
    ),
  ],
),  
              const SizedBox(height: 16),  
              Row(  
                children: [  
                  FilledButton(  
                    onPressed: saving ? null : onSave,  
                    child: saving  
                        ? const SizedBox(  
                            height: 20,  
                            width: 20,  
                            child: CircularProgressIndicator(strokeWidth: 2),  
                          )  
                        : const Text('Save'),  
                  ),  
                  const SizedBox(width: 12),  
                  OutlinedButton(  
                    onPressed: saving ? null : onCancel,  
                    child: const Text('Cancel'),  
                  ),  
                ],  
              ),  
            ],  
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
                AppBadge(
                  label: req.status.label(),
                  color: color,
                  small: true,
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
                  child: InkWell(
                    onTap: () async {
                      final url = _absoluteImage(d.url);
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    child: Text(
                      '· ${d.originalName ?? d.url}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MapPicker extends StatelessWidget {
  final LatLng pin;
  final bool hasPin;
  final ValueChanged<LatLng> onTap;

  const _MapPicker({
    required this.pin,
    required this.hasPin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 280,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: pin,
            initialZoom: 12,
            onTap: (_, latLng) => onTap(latLng),
            interactionOptions: const InteractionOptions(
              flags:
                  InteractiveFlag.all &
                  ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName:
                  'com.school_rec.app',
            ),

            if (hasPin)
              MarkerLayer(
                markers: [
                  Marker(
                    point: pin,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter,
                    child: Icon(
                      Icons.location_on,
                      size: 40,
                      color:
                          Theme.of(context)
                              .colorScheme
                              .primary,
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
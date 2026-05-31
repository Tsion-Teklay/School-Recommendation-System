import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location_helper.dart';
import 'package:latlong2/latlong.dart';

import 'package:flutter_map/flutter_map.dart';

import '../../../shared/utils/error_handler.dart';
import '../../../shared/utils/message_helper.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../../auth/data/auth_repository.dart';
import '../../schools/data/school_dtos.dart';
import '../../schools/data/school_repository.dart';

class AdminSchoolCreateScreen extends ConsumerStatefulWidget {
  const AdminSchoolCreateScreen({super.key});

  @override
  ConsumerState<AdminSchoolCreateScreen> createState() =>
      _AdminSchoolCreateScreenState();
}

class _AdminSchoolCreateScreenState
    extends ConsumerState<AdminSchoolCreateScreen> {
  final _form = GlobalKey<FormState>();

  final _schoolName = TextEditingController();
  SubCity? _subCity;  
final _woreda = TextEditingController();  
final _streetName = TextEditingController();
  final _contactEmail = TextEditingController();
  final _contactPhone = TextEditingController();
  final _tuitionFee = TextEditingController();
  final _facilities = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();

  Curriculum? _curriculum;
  SchoolLevel? _schoolLevel;
  SchoolType? _schoolType;

  bool _fetchingLocation = false;
  bool _loading = false;

  String? _error;

  LatLng? _pin;

  static const _defaultCentre = LatLng(9.0331, 38.7501);

  @override
  void dispose() {
    _schoolName.dispose();
    _woreda.dispose();
    _streetName.dispose();
    _contactEmail.dispose();
    _contactPhone.dispose();
    _tuitionFee.dispose();
    _facilities.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _fetchingLocation = true);

    try {
      final loc = await LocationHelper.getCurrentPosition();

      if (loc != null) {
        final point = LatLng(loc.latitude, loc.longitude);

        setState(() {
          _pin = point;
          _latitude.text =
              point.latitude.toStringAsFixed(6);
          _longitude.text =
              point.longitude.toStringAsFixed(6);
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _fetchingLocation = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Validate curriculum is selected
      if (_curriculum == null) {
        setState(() => _error = 'Please select a curriculum');
        return;
      }

      // Parse tuition fee safely
      final tuitionFeeText = _tuitionFee.text.trim();
      final tuitionFee = num.tryParse(tuitionFeeText);
      if (tuitionFee == null) {
        setState(() => _error = 'Please enter a valid tuition fee');
        return;
      }

      final school =
          await ref.read(schoolRepositoryProvider).create(
                schoolName: _schoolName.text.trim(),
                subCity: _subCity,
                woreda: _woreda.text.trim().isEmpty ? null : _woreda.text.trim(),
                streetName: _streetName.text.trim().isEmpty ? null : _streetName.text.trim(),
                contactEmail:
                    _contactEmail.text.trim(),
                contactPhone:
                    _contactPhone.text.trim().isEmpty
                        ? null
                        : _contactPhone.text.trim(),
                curriculum: _curriculum!,
                schoolLevel: _schoolLevel,
                schoolType: _schoolType,
                tuitionFee: tuitionFee,
                facilities:
                    _facilities.text.trim().isEmpty
                        ? null
                        : _facilities.text.trim(),
                latitude: _latitude.text.trim().isEmpty ? null : double.parse(_latitude.text.trim()),
                longitude: _longitude.text.trim().isEmpty ? null : double.parse(_longitude.text.trim()),
              );

      if (!mounted) return;

      MessageHelper.showSuccess(context, SuccessMessages.schoolCreated);
      context.go('/admin/schools/${school.id}');
    } on ApiException catch (e) {
      // Show detailed error message if available
      String errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      if (e.details != null && e.details!.isNotEmpty) {
        final detailMessages = e.details!.map((d) {
          if (d is Map && d.containsKey('message')) {
            return '- ${d['message']}';
          }
          return '';
        }).where((msg) => msg.isNotEmpty).join('\n');
        if (detailMessages.isNotEmpty) {
          errorMessage = '$errorMessage\n\n$detailMessages';
        }
      }
      setState(() => _error = errorMessage);
    } catch (e) {
      setState(() => _error = ErrorHandler.getUserFriendlyMessage(e));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _updatePinFromTextFields() {
    final lat = double.tryParse(_latitude.text.trim());
    final lng = double.tryParse(_longitude.text.trim());

    if (lat != null && lng != null) {
      setState(() {
        _pin = LatLng(lat, lng);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveShell(
      title: 'Register your school',
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _form,
                 autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding:
                            const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme
                              .colorScheme.errorContainer,
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: theme.colorScheme
                                .onErrorContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _schoolName,
                      decoration:
                          const InputDecoration(
                        labelText: 'School name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null ||
                                  v.trim().isEmpty
                              ? 'Required'
                              : null,
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<SubCity>(  
  decoration: const InputDecoration(  
    labelText: 'Sub-city',  
    border: OutlineInputBorder(),  
  ),  
  value: _subCity,  
  items: SubCity.values.map((subCity) {  
    return DropdownMenuItem(value: subCity, child: Text(subCity.label));  
  }).toList(),  
  onChanged: (v) => setState(() => _subCity = v),  
),  
  
const SizedBox(height: 12),  
  
TextFormField(  
  controller: _woreda,  
  decoration: const InputDecoration(  
    labelText: 'Woreda',  
    border: OutlineInputBorder(),  
  ),  
  keyboardType: TextInputType.number,  
),  
  
const SizedBox(height: 12),  
  
TextFormField(  
  controller: _streetName,  
  decoration: const InputDecoration(  
    labelText: 'Street Name',  
    border: OutlineInputBorder(),  
  ),  
),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _contactEmail,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Contact email *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null ||
                            v.trim().isEmpty) {
                          return 'Required';
                        }

                        if (!v.contains('@')) {
                          return 'Invalid email';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _contactPhone,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Contact phone',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          TextInputType.phone,
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<
                        Curriculum>(
                      decoration:
                          const InputDecoration(
                        labelText: 'Curriculum *',
                        border: OutlineInputBorder(),
                        hintText: 'Select curriculum',
                      ),
                      value: _curriculum,
                      items: Curriculum.values
                          .map(
                            (c) =>
                                DropdownMenuItem(
                              value: c,
                              child:
                                  Text(c.label()),
                            ),
                          )
                          .toList(),
                      validator: (v) =>
                          v == null
                              ? 'Please select a curriculum'
                              : null,
                      onChanged: (v) =>
                          setState(
                        () => _curriculum = v,
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<
                        SchoolLevel>(
                      decoration:
                          const InputDecoration(
                        labelText:
                            'School level (optional)',
                        border: OutlineInputBorder(),
                      ),
                      value: _schoolLevel,
                      items: SchoolLevel.values
                          .map(
                            (l) =>
                                DropdownMenuItem(
                              value: l,
                              child:
                                  Text(l.label()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(
                        () => _schoolLevel = v,
                      ),
                    ),


                    const SizedBox(height: 12),  
  
DropdownButtonFormField<SchoolType>(  
  decoration: const InputDecoration(  
    labelText: 'School type (optional)',  
    border: OutlineInputBorder(),  
  ),  
  value: _schoolType,  
  items: SchoolType.values  
      .map(  
        (t) =>  
            DropdownMenuItem(  
          value: t,  
          child:  
              Text(t.label()),  
        ),  
      )  
      .toList(),  
  onChanged: (v) =>  
      setState(  
    () => _schoolType = v,  
  ),  
),  
  
const SizedBox(height: 12),

                    TextFormField(
                      controller: _tuitionFee,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Tuition fee *',
                        border: OutlineInputBorder(),
                        prefixText: 'ETB ',
                      ),
                      keyboardType:
                          TextInputType.number,
                      validator: (v) {
                        if (v == null ||
                            v.trim().isEmpty) {
                          return 'Required';
                        }

                        if (num.tryParse(
                                v.trim()) ==
                            null) {
                          return 'Invalid number';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _facilities,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Facilities (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 12),

                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Location (optional)',
                                style: theme
                                    .textTheme
                                    .titleSmall,
                              ),
                            ),
                            TextButton.icon(
                              onPressed:
                                  _fetchingLocation
                                      ? null
                                      : _fetchLocation,
                              icon: _fetchingLocation
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child:
                                          CircularProgressIndicator(
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

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller:
                                    _latitude,
                                decoration:
                                    const InputDecoration(
                                  labelText:
                                      'Latitude',
                                  border:
                                      OutlineInputBorder(),
                                ),
                                keyboardType:
                                    TextInputType
                                        .number,
                                onChanged: (_) =>
                                    _updatePinFromTextFields(),
                                validator: (v) {
                                  if (v != null &&
                                      v.trim()
                                          .isNotEmpty) {
                                    final lat =
                                        double.tryParse(
                                      v.trim(),
                                    );

                                    if (lat ==
                                        null) {
                                      return 'Invalid number';
                                    }

                                    if (lat < -90 ||
                                        lat > 90) {
                                      return 'Must be -90 to 90';
                                    }
                                  }

                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(
                                width: 12),

                            Expanded(
                              child: TextFormField(
                                controller:
                                    _longitude,
                                decoration:
                                    const InputDecoration(
                                  labelText:
                                      'Longitude',
                                  border:
                                      OutlineInputBorder(),
                                ),
                                keyboardType:
                                    TextInputType
                                        .number,
                                onChanged: (_) =>
                                    _updatePinFromTextFields(),
                                validator: (v) {
                                  if (v != null &&
                                      v.trim()
                                          .isNotEmpty) {
                                    final lng =
                                        double.tryParse(
                                      v.trim(),
                                    );

                                    if (lng ==
                                        null) {
                                      return 'Invalid number';
                                    }

                                    if (lng <
                                            -180 ||
                                        lng >
                                            180) {
                                      return 'Must be -180 to 180';
                                    }
                                  }

                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _MapPicker(
                          pin:
                              _pin ??
                                  _defaultCentre,
                          hasPin:
                              _pin != null,
                          onTap: (latLng) {
                            setState(() {
                              _pin = latLng;

                              _latitude.text =
                                  latLng.latitude
                                      .toStringAsFixed(
                                          6);

                              _longitude.text =
                                  latLng.longitude
                                      .toStringAsFixed(
                                          6);
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    FilledButton(
                      onPressed:
                          _loading
                              ? null
                              : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Register school',
                            ),
                    ),
                  ],
                ),
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
        width: double.infinity,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: pin,
            initialZoom: 12,
            onTap: (_, latLng) =>
                onTap(latLng),
            interactionOptions:
                const InteractionOptions(
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
                    alignment:
                        Alignment.topCenter,
                    child: Icon(
                      Icons.location_on,
                      size: 40,
                      color: Theme.of(context)
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
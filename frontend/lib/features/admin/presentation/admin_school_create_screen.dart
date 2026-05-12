import 'package:flutter/material.dart';  
import 'package:flutter_riverpod/flutter_riverpod.dart';  
import 'package:go_router/go_router.dart';  
  
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
  final _address = TextEditingController();  
  final _contactEmail = TextEditingController();  
  final _contactPhone = TextEditingController();  
  final _tuitionFee = TextEditingController();  
  final _facilities = TextEditingController();  
  final _latitude = TextEditingController();  
  final _longitude = TextEditingController();  
  
  Curriculum? _curriculum;  
  SchoolLevel? _schoolLevel;  
  
  bool _loading = false;  
  String? _error;  
  
  @override  
  void dispose() {  
    _schoolName.dispose();  
    _address.dispose();  
    _contactEmail.dispose();  
    _contactPhone.dispose();  
    _tuitionFee.dispose();  
    _facilities.dispose();  
    _latitude.dispose();  
    _longitude.dispose();  
    super.dispose();  
  }  
  
  Future<void> _submit() async {  
    if (!_form.currentState!.validate()) return;  
    setState(() {  
      _loading = true;  
      _error = null;  
    });  
    try {  
      final school = await ref.read(schoolRepositoryProvider).create(  
            schoolName: _schoolName.text.trim(),  
            address: _address.text.trim(),  
            contactEmail: _contactEmail.text.trim(),  
            contactPhone: _contactPhone.text.trim().isEmpty  
                ? null  
                : _contactPhone.text.trim(),  
            curriculum: _curriculum!,  
            schoolLevel: _schoolLevel,  
            tuitionFee: num.parse(_tuitionFee.text.trim()),  
            facilities: _facilities.text.trim().isEmpty  
                ? null  
                : _facilities.text.trim(),  
            latitude: _latitude.text.trim().isEmpty  
                ? null  
                : double.tryParse(_latitude.text.trim()),  
            longitude: _longitude.text.trim().isEmpty  
                ? null  
                : double.tryParse(_longitude.text.trim()),  
          );  
      if (!mounted) return;  
      context.go('/admin/schools/${school.id}');  
    } on ApiException catch (e) {  
      setState(() => _error = e.message);  
    } catch (e) {  
      setState(() => _error = e.toString());  
    } finally {  
      if (mounted) setState(() => _loading = false);  
    }  
  }  
  
  @override  
  Widget build(BuildContext context) {  
    final theme = Theme.of(context);  
    return ResponsiveShell(  
      title: 'Register your school',  
      child: _loading  
          ? const Center(child: CircularProgressIndicator())  
          : SingleChildScrollView(  
              padding: const EdgeInsets.all(16),  
              child: Form(  
                key: _form,  
                child: Column(  
                  crossAxisAlignment: CrossAxisAlignment.stretch,  
                  children: [  
                    if (_error != null) ...[  
                      Container(  
                        padding: const EdgeInsets.all(12),  
                        decoration: BoxDecoration(  
                          color: theme.colorScheme.errorContainer,  
                          borderRadius: BorderRadius.circular(8),  
                        ),  
                        child: Text(  
                          _error!,  
                          style: TextStyle(  
                              color: theme.colorScheme.onErrorContainer),  
                        ),  
                      ),  
                      const SizedBox(height: 16),  
                    ],  
                    TextFormField(  
                      controller: _schoolName,  
                      decoration: const InputDecoration(  
                        labelText: 'School name *',  
                        border: OutlineInputBorder(),  
                      ),  
                      validator: (v) =>  
                          v == null || v.trim().isEmpty ? 'Required' : null,  
                    ),  
                    const SizedBox(height: 12),  
                    TextFormField(  
                      controller: _address,  
                      decoration: const InputDecoration(  
                        labelText: 'Address *',  
                        border: OutlineInputBorder(),  
                      ),  
                      validator: (v) =>  
                          v == null || v.trim().isEmpty ? 'Required' : null,  
                    ),  
                    const SizedBox(height: 12),  
                    TextFormField(  
                      controller: _contactEmail,  
                      decoration: const InputDecoration(  
                        labelText: 'Contact email *',  
                        border: OutlineInputBorder(),  
                      ),  
                      keyboardType: TextInputType.emailAddress,  
                      validator: (v) {  
                        if (v == null || v.trim().isEmpty) return 'Required';  
                        if (!v.contains('@')) return 'Invalid email';  
                        return null;  
                      },  
                    ),  
                    const SizedBox(height: 12),  
                    TextFormField(  
                      controller: _contactPhone,  
                      decoration: const InputDecoration(  
                        labelText: 'Contact phone',  
                        border: OutlineInputBorder(),  
                      ),  
                      keyboardType: TextInputType.phone,  
                    ),  
                    const SizedBox(height: 12),  
                    DropdownButtonFormField<Curriculum>(  
                      decoration: const InputDecoration(  
                        labelText: 'Curriculum *',  
                        border: OutlineInputBorder(),  
                      ),  
                      value: _curriculum,  
                      items: Curriculum.values  
                          .map((c) => DropdownMenuItem(  
                                value: c,  
                                child: Text(c.label()),  
                              ))  
                          .toList(),  
                      validator: (v) => v == null ? 'Required' : null,  
                      onChanged: (v) => setState(() => _curriculum = v),  
                    ),  
                    const SizedBox(height: 12),  
                    DropdownButtonFormField<SchoolLevel>(  
                      decoration: const InputDecoration(  
                        labelText: 'School level (optional)',  
                        border: OutlineInputBorder(),  
                      ),  
                      value: _schoolLevel,  
                      items: SchoolLevel.values  
                          .map((l) => DropdownMenuItem(  
                                value: l,  
                                child: Text(l.label()),  
                              ))  
                          .toList(),  
                      onChanged: (v) => setState(() => _schoolLevel = v),  
                    ),  
                    const SizedBox(height: 12),  
                    TextFormField(  
                      controller: _tuitionFee,  
                      decoration: const InputDecoration(  
                        labelText: 'Tuition fee *',  
                        border: OutlineInputBorder(),  
                        prefixText: 'ETB ',  
                      ),  
                      keyboardType: TextInputType.number,  
                      validator: (v) {  
                        if (v == null || v.trim().isEmpty) return 'Required';  
                        if (num.tryParse(v.trim()) == null) return 'Invalid number';  
                        return null;  
                      },  
                    ),  
                    const SizedBox(height: 12),  
                    TextFormField(  
                      controller: _facilities,  
                      decoration: const InputDecoration(  
                        labelText: 'Facilities (optional)',  
                        border: OutlineInputBorder(),  
                      ),  
                      maxLines: 3,  
                    ),  
                    const SizedBox(height: 12),  
                    Row(  
                      children: [  
                        Expanded(  
                          child: TextFormField(  
                            controller: _latitude,  
                            decoration: const InputDecoration(  
                              labelText: 'Latitude (optional)',  
                              border: OutlineInputBorder(),  
                            ),  
                            keyboardType: TextInputType.number,  
                            validator: (v) {  
                              if (v == null || v.trim().isEmpty) return null;  
                              if (double.tryParse(v.trim()) == null) {  
                                return 'Invalid number';  
                              }  
                              final lat = double.parse(v.trim());  
                              if (lat < -90 || lat > 90) return 'Must be -90 to 90';  
                              return null;  
                            },  
                          ),  
                        ),  
                        const SizedBox(width: 12),  
                        Expanded(  
                          child: TextFormField(  
                            controller: _longitude,  
                            decoration: const InputDecoration(  
                              labelText: 'Longitude (optional)',  
                              border: OutlineInputBorder(),  
                            ),  
                            keyboardType: TextInputType.number,  
                            validator: (v) {  
                              if (v == null || v.trim().isEmpty) return null;  
                              if (double.tryParse(v.trim()) == null) {  
                                return 'Invalid number';  
                              }  
                              final lng = double.parse(v.trim());  
                              if (lng < -180 || lng > 180) {  
                                return 'Must be -180 to 180';  
                              }  
                              return null;  
                            },  
                          ),  
                        ),  
                      ],  
                    ),  
                    const SizedBox(height: 24),  
                    FilledButton(  
                      onPressed: _loading ? null : _submit,  
                      child: _loading  
                          ? const SizedBox(  
                              height: 20,  
                              width: 20,  
                              child: CircularProgressIndicator(strokeWidth: 2),  
                            )  
                          : const Text('Register school'),  
                    ),  
                  ],  
                ),  
              ),  
            ),  
    );  
  }  
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../../../core/location_helper.dart';
import '../data/preference_dtos.dart';
import '../data/preference_repository.dart';
import '../../schools/data/school_dtos.dart';

/// PARENT-only recommendation preferences screen. Mirrors the backend POST
/// /api/preferences body shape: budget min/max, curriculum, distance radius,
/// and (optional, paired) home pin.
///
/// Hydration: GET /api/preferences/me returns nulls when nothing is saved
/// yet — we render an empty form rather than an error.
class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  final _form = GlobalKey<FormState>();
  final _minBudget = TextEditingController();
  final _maxBudget = TextEditingController();
  final _distance = TextEditingController();

  PreferredCurriculum? _curriculum;
  SchoolLevel? _schoolLevel;
  SchoolType? _schoolType;
  // The recommender treats home pin as lat + lng coordinates.
  // The map below lets the user drop a pin; we keep the lat/lng here.
  LatLng? _pin;

  // Default initial map centre: Addis Ababa city centre. We only use this
  // until the parent either drops their first pin or loads a saved pin.
  static const _defaultCentre = LatLng(9.0331, 38.7501);

  bool _loading = true;
  bool _saving = false;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _minBudget.dispose();
    _maxBudget.dispose();
    _distance.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final prefs =
          await ref.read(preferenceRepositoryProvider).getMine();
      if (!mounted) return;
      _hydrate(prefs);
      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _hydrate(ParentPreferences p) {
    if (p.minBudget != null) _minBudget.text = _money(p.minBudget!);
    if (p.maxBudget != null) _maxBudget.text = _money(p.maxBudget!);
    if (p.distanceKm != null) _distance.text = p.distanceKm.toString();
    if (p.latitude != null && p.longitude != null) {
      _pin = LatLng(p.latitude!, p.longitude!);
    }
    _curriculum = p.curriculum;
    _schoolLevel = p.schoolLevel;
    _schoolType = p.schoolType;
  }

  // The backend stores tuition fees / budgets as Decimal(10,2). Render
  // whole numbers without trailing ".00" so the input box looks clean.
  String _money(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  String? _validateMoney(String? raw) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return null;
    final n = double.tryParse(t);
    if (n == null) return 'Enter a number';
    if (n < 0) return 'Must be ≥ 0';
    return null;
  }

  String? _validateBudgetRange() {
    final min = double.tryParse(_minBudget.text.trim());
    final max = double.tryParse(_maxBudget.text.trim());
    if (min != null && max != null && min > max) {
      return 'Min budget cannot exceed max budget';
    }
    return null;
  }

  String? _validateDistance(String? raw) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null) return 'Enter a whole number';
    if (n < 0) return 'Must be ≥ 0';
    if (n > 1000) return 'Max 1000 km';
    return null;
  }

Future<void> _useCurrentLocation() async {
  try {
    final position = await LocationHelper.getCurrentPosition();
      
    if (!mounted) return;
    setState(() {
      _pin = LatLng(position.latitude, position.longitude);
    });
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _error = e.toString();
    });
  }
}  

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final rangeError = _validateBudgetRange();
    if (rangeError != null) {
      setState(() => _error = rangeError);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _message = null;
    });
    try {
      final repo = ref.read(preferenceRepositoryProvider);
      final updated = await repo.save(
        minBudget: _parseDouble(_minBudget.text),
        maxBudget: _parseDouble(_maxBudget.text),
        curriculum: _curriculum,
        distanceKm: _parseInt(_distance.text),
        schoolLevel: _schoolLevel,
        schoolType: _schoolType,

        latitude: _pin?.latitude,
        longitude: _pin?.longitude,
      );
      if (!mounted) return;
      _hydrate(updated);
      setState(() {
        _saving = false;
        _message = 'Preferences saved.';
      });
      // Navigate back to home after saving
      if (mounted) context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  double? _parseDouble(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  int? _parseInt(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ResponsiveShell(
        title: 'Recommendation preferences',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ResponsiveShell(
      title: 'Recommendation preferences',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/'),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _form,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Your preferences',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Used to rank schools. All fields are optional.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),

            Text('Budget (per year, ETB)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16)),
            const SizedBox(height: 8),
            // Two short numeric inputs side-by-side on roomy screens; the
            // outer ResponsiveShell handles narrow widths so we don't need a
            // LayoutBuilder here.
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minBudget,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Min',
                      prefixText: 'ETB ',
                      isDense: true,
                    ),
                    validator: _validateMoney,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxBudget,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Max',
                      prefixText: 'ETB ',
                      isDense: true,
                    ),
                    validator: _validateMoney,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Text('Curriculum',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<PreferredCurriculum?>(
              value: _curriculum,
              decoration: const InputDecoration(
                labelText: 'Curriculum',
                helperText: 'Leave blank for no preference',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('No preference')),
                DropdownMenuItem(
                  value: PreferredCurriculum.local,
                  child: Text('Local (Ethiopian)'),
                ),
                DropdownMenuItem(
                  value: PreferredCurriculum.international,
                  child: Text('International'),
                ),
              ],
              onChanged: (v) => setState(() => _curriculum = v),
            ),

            const SizedBox(height: 16),
Text('School level',
    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16)),
const SizedBox(height: 8),
DropdownButtonFormField<SchoolLevel?>(  
  value: _schoolLevel,  
  decoration: const InputDecoration(  
    hintText: 'Any level',
    isDense: true,
  ),  
  items: SchoolLevel.values.map((level) {  
    return DropdownMenuItem(  
      value: level,  
      child: Text(level.label()),  
    );  
  }).toList(),  
  onChanged: (value) => setState(() => _schoolLevel = value),  
),

const SizedBox(height: 16),
Text('School type',
    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16)),  
const SizedBox(height: 8),  
DropdownButtonFormField<SchoolType?>(  
  value: _schoolType,  
  decoration: const InputDecoration(  
    hintText: 'Any type',
    isDense: true,
  ),  
  items: SchoolType.values.map((type) {  
    return DropdownMenuItem(  
      value: type,  
      child: Text(type.label()),  
    );  
  }).toList(),  
  onChanged: (value) => setState(() => _schoolType = value),  
),

            const SizedBox(height: 16),
            Text('Distance radius',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _distance,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'Max distance (km)',
                helperText: 'Schools beyond this distance are penalised.',
                suffixText: 'km',
                isDense: true,
              ),
              validator: _validateDistance,
            ),

            const SizedBox(height: 16),
            Text('Home location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              "Drop a pin where you live. We'll use it to score schools by proximity. (Optional)",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _useCurrentLocation,
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('Use my current location'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 8),
            _MapPicker(
              pin: _pin ?? _defaultCentre,
              hasPin: _pin != null,
              onTap: (latLng) => setState(() => _pin = latLng),
            ),
            if (_pin != null) ...[
              const SizedBox(height: 4),
              Text(
                'Pin: ${_pin!.latitude.toStringAsFixed(5)}, '
                '${_pin!.longitude.toStringAsFixed(5)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
            ],
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            LoadingButton(
              loading: _saving,
              onPressed: _save,
              child: const Text('Save preferences'),
            ),
          ],
        ),
      ),
    ),
    ),
  );
  }
}

/// Minimal tap-to-drop-a-pin map. We deliberately don't reuse the
/// school-detail map widget because that one is read-only and tracks a
/// remote-controlled marker; this one owns its marker and reports taps up.
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
        height: 200,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: pin,
            initialZoom: 12,
            onTap: (_, latLng) => onTap(latLng),
            interactionOptions: const InteractionOptions(
              // Re-enable everything except rotation (rotation makes pin
              // placement confusing and we don't show a compass).
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.school_rec.app',
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
                      color: Theme.of(context).colorScheme.primary,
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

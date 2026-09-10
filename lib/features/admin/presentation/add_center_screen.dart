import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../providers/center_provider.dart';
import '../../../core/services/location_service.dart';

class AddCenterScreen extends ConsumerStatefulWidget {
  final ExamCenter? existingCenter;

  const AddCenterScreen({super.key, this.existingCenter});

  @override
  ConsumerState<AddCenterScreen> createState() => _AddCenterScreenState();
}

class _AddCenterScreenState extends ConsumerState<AddCenterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _capacityController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _radiusController;

  bool _isFetchingGps = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingCenter?.name ?? '');
    _locationController = TextEditingController(text: widget.existingCenter?.location ?? '');
    _capacityController = TextEditingController(text: widget.existingCenter?.capacity.toString() ?? '');
    _latController = TextEditingController(text: widget.existingCenter?.latitude?.toString() ?? '');
    _lngController = TextEditingController(text: widget.existingCenter?.longitude?.toString() ?? '');
    _radiusController = TextEditingController(text: (widget.existingCenter?.allowedRadiusMeters ?? 200).toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentGps() async {
    final s = S.of(context)!;
    setState(() => _isFetchingGps = true);
    final res = await LocationService.getCurrentLocation();
    setState(() => _isFetchingGps = false);

    if (res.success && res.latitude != null && res.longitude != null) {
      _latController.text = res.latitude!.toStringAsFixed(6);
      _lngController.text = res.longitude!.toStringAsFixed(6);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.capturedGpsLocation), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.errorMessage ?? s.couldNotAcquireGps), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _saveCenter() {
    final s = S.of(context)!;
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final location = _locationController.text.trim();
      final capacity = int.tryParse(_capacityController.text.trim()) ?? 0;
      final lat = double.tryParse(_latController.text.trim());
      final lng = double.tryParse(_lngController.text.trim());
      final radius = int.tryParse(_radiusController.text.trim()) ?? 200;

      if (widget.existingCenter == null) {
        ref.read(centerProvider.notifier).addCenter(
              name,
              location,
              capacity,
              latitude: lat,
              longitude: lng,
              allowedRadiusMeters: radius,
            );
      } else {
        ref.read(centerProvider.notifier).updateCenter(
              widget.existingCenter!.id,
              name,
              location,
              capacity,
              latitude: lat,
              longitude: lng,
              allowedRadiusMeters: radius,
            );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.existingCenter == null ? s.centerAddedSuccess : s.centerUpdated)),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCenter != null;
    final s = S.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? s.editCenter : s.addCenter),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: s.centerName, prefixIcon: const Icon(Icons.business)),
                validator: (val) => val == null || val.isEmpty ? s.required : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: s.locationCity, prefixIcon: const Icon(Icons.location_on)),
                validator: (val) => val == null || val.isEmpty ? s.required : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: InputDecoration(labelText: s.capacity, prefixIcon: const Icon(Icons.groups)),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? s.required : null,
              ),
              const SizedBox(height: 20),

              // GEOFENCE CONFIGURATION SECTION
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF007A87).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF007A87).withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.radar, color: Color(0xFF007A87), size: 20),
                            const SizedBox(width: 6),
                            Text(
                              s.geofenceGpsVerification,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF007A87)),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _isFetchingGps ? null : _fetchCurrentGps,
                          icon: _isFetchingGps
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.my_location, size: 16),
                          label: Text(s.useCurrentGps, style: const TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            decoration: InputDecoration(
                              labelText: s.latitude,
                              hintText: 'e.g. 22.30389',
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lngController,
                            decoration: InputDecoration(
                              labelText: s.longitude,
                              hintText: 'e.g. 70.80216',
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _radiusController,
                      decoration: InputDecoration(
                        labelText: s.allowedArrivalRadius,
                        hintText: '200',
                        prefixIcon: const Icon(Icons.circle_outlined, size: 18),
                        isDense: true,
                        helperText: s.geofenceHelperText,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveCenter,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF007A87),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isEditing ? s.updateCenter : s.saveCenter, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

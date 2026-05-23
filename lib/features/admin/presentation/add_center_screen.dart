import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/center_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingCenter?.name ?? '');
    _locationController = TextEditingController(text: widget.existingCenter?.location ?? '');
    _capacityController = TextEditingController(text: widget.existingCenter?.capacity.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _saveCenter() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final location = _locationController.text.trim();
      final capacity = int.tryParse(_capacityController.text.trim()) ?? 0;

      if (widget.existingCenter == null) {
        ref.read(centerProvider.notifier).addCenter(name, location, capacity);
      } else {
        ref.read(centerProvider.notifier).updateCenter(widget.existingCenter!.id, name, location, capacity);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.existingCenter == null ? 'Center Added Successfully!' : 'Center Updated!')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCenter != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Center' : 'Add Center'),
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
                decoration: const InputDecoration(labelText: 'Center Name', prefixIcon: Icon(Icons.business)),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.location_on)),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: 'Capacity', prefixIcon: Icon(Icons.groups)),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveCenter,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text(isEditing ? 'Update Center' : 'Save Center', style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

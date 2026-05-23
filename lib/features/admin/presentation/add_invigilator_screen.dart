import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/invigilator_provider.dart';

class AddInvigilatorScreen extends ConsumerStatefulWidget {
  final Invigilator? existingInvigilator;

  const AddInvigilatorScreen({super.key, this.existingInvigilator});

  @override
  ConsumerState<AddInvigilatorScreen> createState() => _AddInvigilatorScreenState();
}

class _AddInvigilatorScreenState extends ConsumerState<AddInvigilatorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _resourceIdController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingInvigilator?.name ?? '');
    _mobileController = TextEditingController(text: widget.existingInvigilator?.mobile ?? '');
    _resourceIdController = TextEditingController(text: widget.existingInvigilator?.resourceId ?? '');
    _emailController = TextEditingController(text: widget.existingInvigilator?.email ?? '');
    _addressController = TextEditingController(text: widget.existingInvigilator?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _resourceIdController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveInvigilator() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final mobile = _mobileController.text.trim();
      final resourceId = _resourceIdController.text.trim();
      final email = _emailController.text.trim();
      final address = _addressController.text.trim();

      if (widget.existingInvigilator == null) {
        ref.read(invigilatorProvider.notifier).addInvigilator(name, mobile, resourceId, email, address);
      } else {
        ref.read(invigilatorProvider.notifier).updateInvigilator(widget.existingInvigilator!.id, name, mobile, resourceId, email, address);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.existingInvigilator == null ? 'Invigilator Added Successfully!' : 'Invigilator Updated!')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingInvigilator != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Invigilator' : 'Add Invigilator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Personal Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              Text(
                'Contact & Login Credentials',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: 'Mobile Number (Username)', prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _resourceIdController,
                decoration: const InputDecoration(labelText: 'Resource ID (Password)', prefixIcon: Icon(Icons.badge)),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.home)),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveInvigilator,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text(isEditing ? 'Update Invigilator' : 'Save Invigilator', style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

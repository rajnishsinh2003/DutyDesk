import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
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

  bool _isSaving = false;

  void _saveInvigilator() async {
    final s = S.of(context)!;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final name = _nameController.text.trim();
        final mobile = _mobileController.text.trim();
        final resourceId = _resourceIdController.text.trim();
        final email = _emailController.text.trim();
        final address = _addressController.text.trim();

        if (widget.existingInvigilator == null) {
          await ref.read(invigilatorProvider.notifier).addInvigilator(name, mobile, resourceId, email, address);
        } else {
          await ref.read(invigilatorProvider.notifier).updateInvigilator(widget.existingInvigilator!.id, name, mobile, resourceId, email, address);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.existingInvigilator == null ? s.invigilatorAddedSuccess : s.invigilatorUpdated)),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingInvigilator != null;
    final s = S.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin_dashboard/manage_invigilators');
            }
          },
        ),
        title: Text(isEditing ? s.editInvigilator : s.addInvigilator),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.personalDetails,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: s.fullName, prefixIcon: const Icon(Icons.person)),
                validator: (val) => val == null || val.isEmpty ? s.required : null,
              ),
              const SizedBox(height: 32),
              Text(
                s.contactAndCredentials,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mobileController,
                decoration: InputDecoration(labelText: s.mobileNumberUsername, prefixIcon: const Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.isEmpty ? s.required : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _resourceIdController,
                decoration: InputDecoration(labelText: s.resourceIdPassword, prefixIcon: const Icon(Icons.badge)),
                validator: (val) => val == null || val.isEmpty ? s.required : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: s.emailAddress, prefixIcon: const Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: s.address, prefixIcon: const Icon(Icons.home)),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveInvigilator,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF007A87),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : Text(isEditing ? s.updateInvigilator : s.saveInvigilator, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

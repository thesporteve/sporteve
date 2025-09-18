import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_auth_provider.dart';
import '../theme/admin_theme.dart';

class AdminForm extends StatefulWidget {
  final VoidCallback? onSaved;
  final Map<String, dynamic>? adminData;

  const AdminForm({
    super.key,
    this.onSaved,
    this.adminData,
  });

  @override
  State<AdminForm> createState() => _AdminFormState();
}

class _AdminFormState extends State<AdminForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'admin';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.adminData != null;
    
    if (_isEditMode && widget.adminData != null) {
      final admin = widget.adminData!;
      _usernameController.text = admin['username'] ?? '';
      _emailController.text = admin['email'] ?? '';
      _displayNameController.text = admin['displayName'] ?? '';
      _selectedRole = admin['role'] ?? 'admin';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
      bool success = false;

      if (_isEditMode) {
        // Update existing admin
        success = await authProvider.updateAdmin(
          adminId: widget.adminData!['id'],
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          role: _selectedRole,
          displayName: _displayNameController.text.trim(),
          password: _passwordController.text.trim().isEmpty ? null : _passwordController.text.trim(),
        );
      } else {
        // Create new admin
        success = await authProvider.createAdmin(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: _selectedRole,
          displayName: _displayNameController.text.trim(),
        );
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Admin ${_isEditMode ? 'updated' : 'created'} successfully'),
              backgroundColor: AdminTheme.successColor,
            ),
          );
        }
        if (widget.onSaved != null) {
          widget.onSaved!();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to ${_isEditMode ? 'update' : 'create'} admin. Please try again.'),
              backgroundColor: AdminTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${_isEditMode ? 'updating' : 'creating'} admin: ${e.toString()}'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Admin' : 'Add Admin'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveAdmin,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Display Name
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name *',
                  hintText: 'e.g., John Smith',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Display name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Username and Email
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username *',
                        hintText: 'john.smith',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value.trim())) {
                          return 'Username can only contain letters, numbers, dots, and underscores';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        hintText: 'john@sporteve.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Role
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                ),
                items: const [
                  DropdownMenuItem<String>(
                    value: 'admin',
                    child: Text('Admin'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'super_admin',
                    child: Text('Super Admin'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: _isEditMode ? 'New Password (leave empty to keep current)' : 'Password *',
                  hintText: _isEditMode ? 'Enter new password (optional)' : 'Enter strong password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  // In edit mode, password is optional
                  if (_isEditMode && (value == null || value.trim().isEmpty)) {
                    return null; // Password is optional in edit mode
                  }
                  // In create mode, password is required
                  if (!_isEditMode && (value == null || value.trim().isEmpty)) {
                    return 'Password is required';
                  }
                  // If password is provided, validate length
                  if (value != null && value.isNotEmpty && value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: _isEditMode ? 'Confirm New Password' : 'Confirm Password *',
                  hintText: _isEditMode ? 'Re-enter new password' : 'Re-enter password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  // Only validate if password field has content
                  if (_passwordController.text.trim().isNotEmpty) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please confirm password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                  } else if (_isEditMode) {
                    // In edit mode with no password, confirm password should also be empty
                    if (value != null && value.isNotEmpty) {
                      return 'Clear this field if not changing password';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Role description
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AdminTheme.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Role Permissions:',
                          style: AdminTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AdminTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Admin: Can manage news articles, tournaments, and athletes\n'
                      '• Super Admin: All admin permissions plus admin management',
                      style: AdminTheme.caption.copyWith(
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save button (mobile)
              if (MediaQuery.of(context).size.width <= 600)
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveAdmin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(_isEditMode ? 'Update Admin' : 'Create Admin'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

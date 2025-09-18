import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_auth_provider.dart';
import '../theme/admin_theme.dart';
import '../forms/admin_form.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  List<Map<String, dynamic>> _admins = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
      final admins = await authProvider.getAllAdmins();
      
      setState(() {
        _admins = admins;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load admins: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAdminStatus(String adminId, bool currentStatus) async {
    try {
      final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
      final success = await authProvider.updateAdminStatus(adminId, !currentStatus);
      
      if (success) {
        await _loadAdmins();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Admin ${!currentStatus ? 'activated' : 'deactivated'} successfully'),
              backgroundColor: AdminTheme.successColor,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update admin status'),
              backgroundColor: AdminTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating admin: ${e.toString()}'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    }
  }

  void _addAdmin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminForm(
          onSaved: () {
            Navigator.of(context).pop();
            _loadAdmins();
          },
        ),
      ),
    );
  }

  void _editAdmin(Map<String, dynamic> admin) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminForm(
          adminData: admin,
          onSaved: () {
            Navigator.of(context).pop();
            _loadAdmins();
          },
        ),
      ),
    );
  }

  Future<void> _deleteAdmin(String adminId, String adminName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Admin'),
        content: Text('Are you sure you want to delete admin "$adminName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
      final success = await authProvider.deleteAdmin(adminId);
      
      if (success) {
        await _loadAdmins();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin deleted successfully'),
              backgroundColor: AdminTheme.successColor,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete admin'),
              backgroundColor: AdminTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting admin: ${e.toString()}'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AdminAuthProvider>(context);
    
    // Only super admins can access this screen
    if (!authProvider.isSuperAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: AdminTheme.titleMedium.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Only Super Admins can access this section',
                style: AdminTheme.bodyMedium.copyWith(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAdmin,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Admin'),
        backgroundColor: AdminTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AdminTheme.errorColor),
            const SizedBox(height: 16),
            Text(_error!, style: AdminTheme.bodyLarge.copyWith(color: AdminTheme.errorColor), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadAdmins, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_admins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No admins found', style: AdminTheme.titleMedium.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Create your first admin account to get started', style: AdminTheme.bodyMedium.copyWith(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('Admin Management', style: AdminTheme.titleLarge),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AdminTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('${_admins.length} admins', style: AdminTheme.bodyMedium.copyWith(color: AdminTheme.primaryColor, fontWeight: FontWeight.w500)),
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAdmins, tooltip: 'Refresh'),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildAdminList()),
      ],
    );
  }

  Widget _buildAdminList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _admins.length,
      itemBuilder: (context, index) {
        final admin = _admins[index];
        final isActive = admin['isActive'] ?? true;
        final isCurrent = admin['id'] == Provider.of<AdminAuthProvider>(context).currentAdminId;
        
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isActive ? AdminTheme.primaryColor : Colors.grey,
              child: Text(
                admin['displayName']?.substring(0, 1).toUpperCase() ?? 'A',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(admin['displayName'] ?? 'Unknown'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${admin['username']} • ${admin['email']}'),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: admin['role'] == 'super_admin' ? AdminTheme.warningColor : AdminTheme.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        admin['role'] == 'super_admin' ? 'SUPER ADMIN' : 'ADMIN',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AdminTheme.successColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'CURRENT USER',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: SizedBox(
              width: isCurrent ? 80 : 160,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit button
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Edit Admin',
                    onPressed: () => _editAdmin(admin),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  // Delete button (only for non-current users)
                  if (!isCurrent)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: 'Delete Admin',
                      onPressed: () => _deleteAdmin(admin['id'], admin['displayName'] ?? 'Unknown'),
                      color: AdminTheme.errorColor,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  // Active/Inactive toggle (only for non-current users)
                  if (!isCurrent)
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isActive,
                        onChanged: (value) => _toggleAdminStatus(admin['id'], isActive),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

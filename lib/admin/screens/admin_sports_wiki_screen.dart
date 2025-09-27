import 'package:flutter/material.dart';
import '../../models/sport_wiki.dart';
import '../services/admin_sports_wiki_service.dart';
import '../services/sports_wiki_csv_service.dart';
import '../theme/admin_theme.dart';
import '../forms/sports_wiki_form.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class AdminSportsWikiScreen extends StatefulWidget {
  const AdminSportsWikiScreen({super.key});

  @override
  State<AdminSportsWikiScreen> createState() => _AdminSportsWikiScreenState();
}

class _AdminSportsWikiScreenState extends State<AdminSportsWikiScreen> {
  final AdminSportsWikiService _wikiService = AdminSportsWikiService.instance;
  List<SportWiki> _sportsWiki = [];
  List<SportWiki> _filteredSportsWiki = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedType = 'All';

  final List<String> _categories = ['All', 'Team Sport', 'Individual Sport', 'Mixed Sport'];
  final List<String> _types = ['All', 'Outdoor', 'Indoor', 'Water', 'Combat'];

  @override
  void initState() {
    super.initState();
    _loadSportsWiki();
  }

  Future<void> _loadSportsWiki() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sportsWiki = await _wikiService.getAllSportsWiki();
      setState(() {
        _sportsWiki = sportsWiki;
        _filteredSportsWiki = sportsWiki;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load sports wiki: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterSportsWiki() {
    setState(() {
      _filteredSportsWiki = _sportsWiki.where((sport) {
        final matchesSearch = _searchQuery.isEmpty ||
            sport.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            sport.description.toLowerCase().contains(_searchQuery.toLowerCase());
        
        final matchesCategory = _selectedCategory == 'All' || 
            sport.category == _selectedCategory;
            
        final matchesType = _selectedType == 'All' || 
            sport.type == _selectedType;
        
        return matchesSearch && matchesCategory && matchesType;
      }).toList();
    });
  }

  Future<void> _deleteSportsWiki(String id, String name) async {
    final confirmed = await _showDeleteDialog(context, name);
    if (!confirmed) return;

    try {
      await _wikiService.deleteSportsWikiEntry(id);
      _loadSportsWiki();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "$name" successfully'),
            backgroundColor: AdminTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete "$name": $e'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteDialog(BuildContext context, String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sports Wiki Entry'),
        content: Text('Are you sure you want to delete "$name"?\n\nThis action cannot be undone and will also delete all associated images.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AdminTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showAddEditForm(BuildContext context, {SportWiki? sportWiki}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: isMobile 
          ? const EdgeInsets.all(8) 
          : const EdgeInsets.all(40),
        child: Container(
          width: isMobile ? screenWidth - 16 : screenWidth * 0.9,
          height: isMobile ? screenHeight - 16 : screenHeight * 0.9,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AdminTheme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        sportWiki == null ? 'Add Sports Wiki Entry' : 'Edit ${sportWiki.name}',
                        style: AdminTheme.headlineMedium.copyWith(
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SportsWikiForm(
                    sportWiki: sportWiki,
                    onSaved: (savedSportWiki) {
                      Navigator.of(context).pop();
                      _loadSportsWiki();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            sportWiki == null 
                                ? 'Sports wiki entry created successfully' 
                                : 'Sports wiki entry updated successfully'
                          ),
                          backgroundColor: AdminTheme.successColor,
                        ),
                      );
                    },
                    onCancel: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search sports wiki...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _filterSportsWiki();
            },
          ),
          const SizedBox(height: 12),
          // Filters - responsive layout
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              
              if (isMobile) {
                // Mobile layout - stack vertically
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              isDense: true,
                            ),
                            items: _categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(
                                  category,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value!;
                              });
                              _filterSportsWiki();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              isDense: true,
                            ),
                            items: _types.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value!;
                              });
                              _filterSportsWiki();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Action buttons on separate rows for mobile
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddEditForm(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Sport'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showBulkImportOptions,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Bulk Upload'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AdminTheme.primaryColor,
                          side: BorderSide(color: AdminTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Desktop layout - horizontal
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                          _filterSportsWiki();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _types.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                          _filterSportsWiki();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditForm(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Sport'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _showBulkImportOptions,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Bulk Upload'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminTheme.primaryColor,
                        side: BorderSide(color: AdminTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSportsWikiCard(SportWiki sport) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
                image: sport.images?['hero'] != null
                    ? DecorationImage(
                        image: NetworkImage(sport.images!['hero']!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: sport.images?['hero'] == null
                  ? Icon(
                      Icons.sports,
                      size: 40,
                      color: Colors.grey[400],
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sport.name,
                          style: AdminTheme.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Category and type badges
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AdminTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          sport.category,
                          style: AdminTheme.bodySmall.copyWith(
                            color: AdminTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          sport.type,
                          style: AdminTheme.bodySmall.copyWith(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sport.description.length > 150
                        ? '${sport.description.substring(0, 150)}...'
                        : sport.description,
                    style: AdminTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (sport.olympicSport == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Olympic',
                            style: AdminTheme.bodySmall.copyWith(
                              color: Colors.amber[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        'Updated: ${DateFormat('MMM dd, yyyy').format(sport.lastUpdated ?? sport.createdAt)}',
                        style: AdminTheme.bodySmall.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                IconButton(
                  onPressed: () => _showAddEditForm(context, sportWiki: sport),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                  color: AdminTheme.primaryColor,
                ),
                IconButton(
                  onPressed: () => _deleteSportsWiki(sport.id, sport.name),
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                  color: AdminTheme.errorColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Bulk import methods
  void _showBulkImportOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header with drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Bulk Import Sports',
                style: AdminTheme.headlineMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      // Upload CSV option
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AdminTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.upload_file,
                            color: AdminTheme.primaryColor,
                          ),
                        ),
                        title: const Text('Upload CSV File'),
                        subtitle: const Text('Import sports from a CSV file'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.of(context).pop();
                          _uploadCsvFile();
                        },
                      ),
                      
                      const Divider(),
                      
                      // Download simple template
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.download,
                            color: Colors.blue,
                          ),
                        ),
                        title: const Text('Download Simple Template'),
                        subtitle: const Text('3 required columns (name, category, type)'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _downloadCsvTemplate(comprehensive: false),
                      ),
                      
                      const Divider(),
                      
                      // Download full template
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.download,
                            color: Colors.green,
                          ),
                        ),
                        title: const Text('Download Full Template'),
                        subtitle: const Text('9 columns with all available fields'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _downloadCsvTemplate(comprehensive: true),
                      ),
                      
                      const Divider(),
                      
                      // Download simple sample
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.file_download,
                            color: Colors.orange,
                          ),
                        ),
                        title: const Text('Download Simple Sample'),
                        subtitle: const Text('Sample data with required fields only'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _downloadCsvSample(comprehensive: false),
                      ),
                      
                      const Divider(),
                      
                      // Download full sample
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.file_download,
                            color: Colors.purple,
                          ),
                        ),
                        title: const Text('Download Full Sample'),
                        subtitle: const Text('Sample data with all fields populated'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _downloadCsvSample(comprehensive: true),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadCsvFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final csvContent = String.fromCharCodes(result.files.single.bytes!);
        await _processCsvFile(csvContent, result.files.single.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: ${e.toString()}'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _processCsvFile(String csvContent, String fileName) async {
    try {
      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Validate CSV format first
      final errors = SportsWikiCsvService.validateCsvFormat(csvContent);
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
      }

      if (errors.isNotEmpty) {
        if (mounted) {
          _showValidationErrorDialog(errors, fileName);
        }
        return;
      }

      // Parse CSV data
      final sportsList = await SportsWikiCsvService.parseCsvData(csvContent);
      
      if (mounted) {
        _showImportPreview(sportsList, fileName);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing CSV: ${e.toString()}'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showValidationErrorDialog(List<String> errors, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: AdminTheme.errorColor),
            const SizedBox(width: 8),
            const Text('CSV Validation Errors'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File: $fileName'),
              const SizedBox(height: 16),
              const Text(
                'Please fix the following errors and try again:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: errors.map((error) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: Colors.red)),
                          Expanded(child: Text(error)),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showImportPreview(List<SportWiki> sportsList, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import Preview - $fileName'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Text(
                'Found ${sportsList.length} sports to import:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: sportsList.length,
                  itemBuilder: (context, index) {
                    final sport = sportsList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AdminTheme.primaryColor.withOpacity(0.1),
                          child: Text(
                            sport.name.isNotEmpty ? sport.name[0].toUpperCase() : 'S',
                            style: TextStyle(
                              color: AdminTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(sport.name),
                        subtitle: Text('${sport.category} • ${sport.type}'),
                        trailing: sport.displayName != null 
                          ? Chip(
                              label: Text(sport.displayName!, style: const TextStyle(fontSize: 10)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            )
                          : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _importSports(sportsList),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _importSports(List<SportWiki> sportsList) async {
    try {
      // Close preview dialog
      Navigator.of(context).pop();
      
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Importing ${sportsList.length} sports...'),
            ],
          ),
        ),
      );

      int successCount = 0;
      int errorCount = 0;
      final List<String> errors = [];

      for (final sport in sportsList) {
        try {
          await _wikiService.addSportsWikiEntry(sport);
          successCount++;
        } catch (e) {
          errorCount++;
          errors.add('${sport.name}: ${e.toString()}');
        }
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        
        // Refresh the list
        await _loadSportsWiki();
        
        // Show result
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Import completed: $successCount successful, $errorCount failed',
            ),
            backgroundColor: errorCount > 0 ? Colors.orange : AdminTheme.successColor,
            duration: const Duration(seconds: 4),
          ),
        );

        if (errors.isNotEmpty) {
          _showImportErrorsDialog(errors);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: ${e.toString()}'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showImportErrorsDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Import Errors'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The following sports could not be imported:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: errors.map((error) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $error'),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _downloadCsvTemplate({required bool comprehensive}) {
    try {
      final csvContent = comprehensive 
        ? SportsWikiCsvService.getComprehensiveCsvTemplate()
        : SportsWikiCsvService.getCsvTemplate();
      
      final fileName = comprehensive 
        ? 'sports_wiki_full_template.csv'
        : 'sports_wiki_simple_template.csv';
      
      _downloadFile(csvContent, fileName);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${comprehensive ? "Full" : "Simple"} template downloaded: $fileName'),
          backgroundColor: AdminTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading template: ${e.toString()}'),
          backgroundColor: AdminTheme.errorColor,
        ),
      );
    }
  }

  void _downloadCsvSample({required bool comprehensive}) {
    try {
      final csvContent = comprehensive 
        ? SportsWikiCsvService.generateComprehensiveSampleCsv()
        : SportsWikiCsvService.generateSampleCsv();
      
      final fileName = comprehensive 
        ? 'sports_wiki_full_sample.csv'
        : 'sports_wiki_simple_sample.csv';
      
      _downloadFile(csvContent, fileName);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${comprehensive ? "Full" : "Simple"} sample downloaded: $fileName'),
          backgroundColor: AdminTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading sample: ${e.toString()}'),
          backgroundColor: AdminTheme.errorColor,
        ),
      );
    }
  }

  void _downloadFile(String content, String fileName) {
    // For web platform, this would trigger a download
    // Note: Actual implementation would depend on platform-specific code
    print('Would download: $fileName');
    print('Content: ${content.substring(0, content.length > 100 ? 100 : content.length)}...');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.backgroundColor,
      body: Column(
        children: [
          _buildFiltersBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading sports wiki...'),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AdminTheme.errorColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading sports wiki',
                              style: AdminTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: AdminTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadSportsWiki,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredSportsWiki.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.sports,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _sportsWiki.isEmpty 
                                      ? 'No sports wiki entries yet'
                                      : 'No entries match your search',
                                  style: AdminTheme.titleLarge.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _sportsWiki.isEmpty
                                      ? 'Create your first sports wiki entry'
                                      : 'Try adjusting your search or filters',
                                  style: AdminTheme.bodyMedium.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                ),
                                if (_sportsWiki.isEmpty) ...[
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => _showAddEditForm(context),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add First Sport'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AdminTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredSportsWiki.length,
                            itemBuilder: (context, index) {
                              return _buildSportsWikiCard(_filteredSportsWiki[index]);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

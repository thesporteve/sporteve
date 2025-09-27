import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/athlete.dart';
import '../services/admin_data_service.dart';
import '../services/csv_service.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_card_list.dart';
import '../forms/enhanced_athlete_form.dart';

class AdminAthletesScreen extends StatefulWidget {
  const AdminAthletesScreen({super.key});

  @override
  State<AdminAthletesScreen> createState() => _AdminAthletesScreenState();
}

class _AdminAthletesScreenState extends State<AdminAthletesScreen> {
  final AdminDataService _dataService = AdminDataService.instance;
  List<Athlete> _athletes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAthletes();
  }

  Future<void> _loadAthletes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final athletes = await _dataService.getAllAthletes();
      setState(() {
        _athletes = athletes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load athletes: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAthlete(String athleteId) async {
    final confirmed = await _showDeleteDialog(context);
    if (!confirmed) return;

    try {
      await _dataService.deleteAthlete(athleteId);
      await _loadAthletes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Athlete deleted successfully'),
            backgroundColor: AdminTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete athlete: ${e.toString()}'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Athlete'),
        content: const Text('Are you sure you want to delete this athlete? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _editAthlete(Athlete athlete) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EnhancedAthleteForm(
          athlete: athlete,
          onSaved: () {
            Navigator.of(context).pop();
            _loadAthletes();
          },
        ),
      ),
    );
  }

  void _addAthlete() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EnhancedAthleteForm(
          onSaved: () {
            Navigator.of(context).pop();
            _loadAthletes();
          },
        ),
      ),
    );
  }

  /// Show bulk import options
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
                'Bulk Import Athletes',
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
                      // CSV Upload option
                      ListTile(
                        leading: const Icon(Icons.upload_file, color: AdminTheme.primaryColor),
                        title: const Text('Upload CSV File'),
                        subtitle: const Text('Import athletes from CSV file'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          _importFromCsv();
                        },
                      ),
                      
                      const Divider(),
                      
                      // Download simple template option
                      ListTile(
                        leading: const Icon(Icons.download, color: AdminTheme.primaryColor),
                        title: const Text('Download Simple Template'),
                        subtitle: const Text('Required fields only (5 columns)'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          _downloadCsvTemplate(comprehensive: false);
                        },
                      ),
                      
                      const Divider(),
                      
                      // Download comprehensive template option
                      ListTile(
                        leading: const Icon(Icons.download_for_offline, color: AdminTheme.primaryColor),
                        title: const Text('Download Full Template'),
                        subtitle: const Text('All fields including optional (7 columns)'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          _downloadCsvTemplate(comprehensive: true);
                        },
                      ),
                      
                      const Divider(),
                      
                      // Download simple sample data option
                      ListTile(
                        leading: const Icon(Icons.file_download, color: AdminTheme.primaryColor),
                        title: const Text('Download Simple Sample'),
                        subtitle: const Text('Example data with required fields only'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          _downloadSampleCsv(comprehensive: false);
                        },
                      ),
                      
                      const Divider(),
                      
                      // Download comprehensive sample data option
                      ListTile(
                        leading: const Icon(Icons.file_download_done, color: AdminTheme.primaryColor),
                        title: const Text('Download Full Sample'),
                        subtitle: const Text('Example data with all fields'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          _downloadSampleCsv(comprehensive: true);
                        },
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

  /// Import athletes from CSV file
  Future<void> _importFromCsv() async {
    try {
      // Pick CSV file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Could not read file'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('📊 Parsing CSV file...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      // Parse CSV
      final csvService = CsvService.instance;
      final parseResult = await csvService.parseCsvFile(file.bytes!);

      // Hide loading
      ScaffoldMessenger.of(context).clearSnackBars();

      if (parseResult.hasErrors) {
        // Show errors
        _showCsvErrors(parseResult);
        return;
      }

      // Show preview and confirm import
      _showImportPreview(parseResult, file.name);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error importing CSV: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show CSV parsing errors
  void _showCsvErrors(CsvParseResult parseResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CSV Import Errors'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Found ${parseResult.errors.length} error(s):'),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: parseResult.errors.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '• ${parseResult.errors[index]}',
                        style: const TextStyle(color: Colors.red),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show import preview and confirm
  void _showImportPreview(CsvParseResult parseResult, String fileName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 800,
          height: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.preview, color: AdminTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Import Preview',
                    style: AdminTheme.headlineMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Stats
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('File: $fileName', style: const TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('Total Rows: ${parseResult.totalRows}'),
                          Text('Valid Rows: ${parseResult.validRows}'),
                          if (parseResult.hasWarnings)
                            Text('Warnings: ${parseResult.warnings.length}', 
                                 style: const TextStyle(color: Colors.orange)),
                        ],
                      ),
                    ),
                    Icon(
                      parseResult.isSuccess ? Icons.check_circle : Icons.warning,
                      color: parseResult.isSuccess ? Colors.green : Colors.orange,
                      size: 32,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Preview table
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: parseResult.athletes.length,
                    itemBuilder: (context, index) {
                      final athlete = parseResult.athletes[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(athlete.name),
                        subtitle: Text('${athlete.sport}${athlete.isParaAthlete ? ' (Para)' : ''}'),
                        trailing: athlete.dob != null 
                            ? Text('Age: ${athlete.age}')
                            : null,
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Actions
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: parseResult.isSuccess 
                        ? () => _confirmImport(parseResult)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Import ${parseResult.validRows} Athletes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Confirm and execute import
  Future<void> _confirmImport(CsvParseResult parseResult) async {
    Navigator.pop(context); // Close preview dialog

    try {
      // Show progress
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Importing ${parseResult.validRows} athletes...'),
            ],
          ),
        ),
      );

      // Execute bulk import
      final dataService = AdminDataService.instance;
      final result = await dataService.bulkImportAthletes(parseResult.athletes);

      // Close progress dialog
      Navigator.pop(context);

      // Show result
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            result['error_count'] == 0 
                ? '✅ Import Successful'
                : '⚠️ Import Completed with Errors',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Successfully imported: ${result['success_count']} athletes'),
              if (result['error_count'] > 0)
                Text('Errors: ${result['error_count']}'),
              if (result['errors'].isNotEmpty)
                ...List.generate(
                  (result['errors'] as List).length.clamp(0, 5),
                  (index) => Text('• ${result['errors'][index]}'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      // Refresh athlete list
      _loadAthletes();

    } catch (e) {
      // Close progress if open
      Navigator.of(context, rootNavigator: true).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Import failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Download CSV template (simple or comprehensive)
  void _downloadCsvTemplate({bool comprehensive = false}) {
    final csvService = CsvService.instance;
    final template = comprehensive 
        ? csvService.getComprehensiveCsvTemplate() 
        : csvService.getCsvTemplate();
    final title = comprehensive ? 'Full CSV Template (7 columns)' : 'Simple CSV Template (5 columns)';
    final subtitle = comprehensive 
        ? 'Includes optional fields: education, image_url'
        : 'Required fields only: name, sport, is_para_athlete, dob, place_of_birth';
    
    // For web, we'd trigger a download
    // For now, show in dialog for copying
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: SelectableText(
                  template,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Download sample CSV data (simple or comprehensive)
  void _downloadSampleCsv({bool comprehensive = false}) {
    final csvService = CsvService.instance;
    final sample = comprehensive 
        ? csvService.generateComprehensiveSampleCsv() 
        : csvService.generateSampleCsv();
    final title = comprehensive ? 'Full Sample CSV (7 columns)' : 'Simple Sample CSV (5 columns)';
    final subtitle = comprehensive 
        ? 'Example data with all fields including optional education & image_url'
        : 'Example data with required fields only - ready to import!';
    
    // For web, we'd trigger a download
    // For now, show in dialog for copying
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: SelectableText(
                  sample,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    return Scaffold(
      body: _buildBody(isDesktop),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bulk Import Button
          FloatingActionButton.extended(
            onPressed: _showBulkImportOptions,
            heroTag: "bulk_import",
            icon: const Icon(Icons.upload_file),
            label: const Text('Bulk Import'),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 8),
          // Add Single Athlete Button  
          FloatingActionButton.extended(
            onPressed: _addAthlete,
            heroTag: "add_athlete",
            icon: const Icon(Icons.add),
            label: const Text('Add Athlete'),
            backgroundColor: AdminTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDesktop) {
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
            ElevatedButton(onPressed: _loadAthletes, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_athletes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No athletes found', style: AdminTheme.titleMedium.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Create your first athlete profile to get started', style: AdminTheme.bodyMedium.copyWith(color: Colors.grey[500])),
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
              Text('Athletes', style: AdminTheme.titleLarge),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AdminTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('${_athletes.length} athletes', style: AdminTheme.bodyMedium.copyWith(color: AdminTheme.primaryColor, fontWeight: FontWeight.w500)),
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAthletes, tooltip: 'Refresh'),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: isDesktop ? _buildDesktopTable() : _buildMobileList()),
      ],
    );
  }

  Widget _buildDesktopTable() {
    final columns = [
      const DataColumn(label: Text('Name')),
      const DataColumn(label: Text('Sport')),
      const DataColumn(label: Text('Bio')),
      const DataColumn(label: Text('Actions')),
    ];

    final rows = _athletes.map((athlete) {
      return DataRow(
        cells: [
          DataCell(
            SizedBox(
              width: 200,
              child: Text(athlete.name, style: AdminTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AdminTheme.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(athlete.sport, style: const TextStyle(fontSize: 12)),
            ),
          ),
          DataCell(
            SizedBox(
              width: 300,
              child: Text(
                '${athlete.placeOfBirth.isNotEmpty ? athlete.placeOfBirth : 'Location not specified'}${athlete.age != null ? ' • Age ${athlete.age}' : ''}', 
                style: AdminTheme.bodyMedium, 
                maxLines: 2, 
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _editAthlete(athlete), tooltip: 'Edit'),
                IconButton(icon: const Icon(Icons.delete, size: 18), onPressed: () => _deleteAthlete(athlete.id), tooltip: 'Delete', color: AdminTheme.errorColor),
              ],
            ),
          ),
        ],
      );
    }).toList();

    return AdminDataTable(columns: columns, rows: rows);
  }

  Widget _buildMobileList() {
    return AdminCardList<Athlete>(
      items: _athletes,
      itemBuilder: (athlete) => _buildMobileAthleteCard(athlete),
    );
  }

  Widget _buildMobileAthleteCard(Athlete athlete) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(athlete.name, style: AdminTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AdminTheme.secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(athlete.sport, style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${athlete.placeOfBirth.isNotEmpty ? athlete.placeOfBirth : 'Location not specified'}${athlete.age != null ? ' • Age ${athlete.age}' : ''}',
              style: AdminTheme.bodyMedium.copyWith(color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (athlete.achievements.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '🏆 ${athlete.achievements.length} achievement${athlete.achievements.length > 1 ? 's' : ''}',
                style: AdminTheme.bodyMedium.copyWith(color: AdminTheme.primaryColor),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(icon: const Icon(Icons.edit, size: 16), label: const Text('Edit'), onPressed: () => _editAthlete(athlete)),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  onPressed: () => _deleteAthlete(athlete.id),
                  style: TextButton.styleFrom(foregroundColor: AdminTheme.errorColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

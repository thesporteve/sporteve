import 'package:flutter/material.dart';
import '../../models/athlete.dart';
import '../services/admin_data_service.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_card_list.dart';
import '../forms/athlete_form.dart';

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
        builder: (context) => AthleteForm(
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
        builder: (context) => AthleteForm(
          onSaved: () {
            Navigator.of(context).pop();
            _loadAthletes();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    return Scaffold(
      body: _buildBody(isDesktop),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAthlete,
        icon: const Icon(Icons.add),
        label: const Text('Add Athlete'),
        backgroundColor: AdminTheme.primaryColor,
        foregroundColor: Colors.white,
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
              child: Text(athlete.bio, style: AdminTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
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
            if (athlete.bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                athlete.bio,
                style: AdminTheme.bodyMedium.copyWith(color: Colors.grey[600]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
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

import 'package:flutter/material.dart';
import '../../models/tournament.dart';
import '../services/admin_data_service.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_card_list.dart';
import '../forms/tournament_form.dart';

class AdminTournamentsScreen extends StatefulWidget {
  const AdminTournamentsScreen({super.key});

  @override
  State<AdminTournamentsScreen> createState() => _AdminTournamentsScreenState();
}

class _AdminTournamentsScreenState extends State<AdminTournamentsScreen> {
  final AdminDataService _dataService = AdminDataService.instance;
  List<Tournament> _tournaments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tournaments = await _dataService.getAllTournaments();
      setState(() {
        _tournaments = tournaments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load tournaments: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTournament(String tournamentId) async {
    final confirmed = await _showDeleteDialog(context);
    if (!confirmed) return;

    try {
      await _dataService.deleteTournament(tournamentId);
      await _loadTournaments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tournament deleted successfully'),
            backgroundColor: AdminTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete tournament: ${e.toString()}'),
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
        title: const Text('Delete Tournament'),
        content: const Text('Are you sure you want to delete this tournament? This action cannot be undone.'),
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

  void _editTournament(Tournament tournament) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TournamentForm(
          tournament: tournament,
          onSaved: () {
            Navigator.of(context).pop();
            _loadTournaments();
          },
        ),
      ),
    );
  }

  void _addTournament() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TournamentForm(
          onSaved: () {
            Navigator.of(context).pop();
            _loadTournaments();
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
        onPressed: _addTournament,
        icon: const Icon(Icons.add),
        label: const Text('Add Tournament'),
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
            ElevatedButton(onPressed: _loadTournaments, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No tournaments found', style: AdminTheme.titleMedium.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Create your first tournament to get started', style: AdminTheme.bodyMedium.copyWith(color: Colors.grey[500])),
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
              Text('Tournaments', style: AdminTheme.titleLarge),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AdminTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('${_tournaments.length} tournaments', style: AdminTheme.bodyMedium.copyWith(color: AdminTheme.primaryColor, fontWeight: FontWeight.w500)),
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTournaments, tooltip: 'Refresh'),
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
      const DataColumn(label: Text('Location')),
      const DataColumn(label: Text('Dates')),
      const DataColumn(label: Text('Status')),
      const DataColumn(label: Text('Actions')),
    ];

    final rows = _tournaments.map((tournament) {
      return DataRow(
        cells: [
          DataCell(
            SizedBox(
              width: 200,
              child: Text(tournament.name, style: AdminTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AdminTheme.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(tournament.sportType, style: const TextStyle(fontSize: 12)),
            ),
          ),
          DataCell(Text(tournament.place)),
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(tournament.startDate, style: AdminTheme.bodyMedium),
                Text('to ${tournament.endDate}', style: AdminTheme.caption),
              ],
            ),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AdminTheme.getStatusColor(tournament.status.value).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminTheme.getStatusColor(tournament.status.value).withOpacity(0.3)),
              ),
              child: Text(
                tournament.status.displayName.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AdminTheme.getStatusColor(tournament.status.value),
                ),
              ),
            ),
          ),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _editTournament(tournament), tooltip: 'Edit'),
                IconButton(icon: const Icon(Icons.delete, size: 18), onPressed: () => _deleteTournament(tournament.id), tooltip: 'Delete', color: AdminTheme.errorColor),
              ],
            ),
          ),
        ],
      );
    }).toList();

    return AdminDataTable(columns: columns, rows: rows);
  }

  Widget _buildMobileList() {
    return AdminCardList<Tournament>(
      items: _tournaments,
      itemBuilder: (tournament) => _buildMobileTournamentCard(tournament),
    );
  }

  Widget _buildMobileTournamentCard(Tournament tournament) {
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
                      Text(tournament.name, style: AdminTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(tournament.place, style: AdminTheme.bodyMedium.copyWith(color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminTheme.getStatusColor(tournament.status.value).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminTheme.getStatusColor(tournament.status.value).withOpacity(0.3)),
                  ),
                  child: Text(
                    tournament.status.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.getStatusColor(tournament.status.value),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(tournament.sportType, style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 12),
                Text('${tournament.startDate} - ${tournament.endDate}', style: AdminTheme.caption),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(icon: const Icon(Icons.edit, size: 16), label: const Text('Edit'), onPressed: () => _editTournament(tournament)),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  onPressed: () => _deleteTournament(tournament.id),
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

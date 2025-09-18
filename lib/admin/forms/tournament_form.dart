import 'package:flutter/material.dart';
import '../../models/tournament.dart';
import '../services/admin_data_service.dart';
import '../theme/admin_theme.dart';

class TournamentForm extends StatefulWidget {
  final Tournament? tournament;
  final VoidCallback? onSaved;

  const TournamentForm({
    super.key,
    this.tournament,
    this.onSaved,
  });

  @override
  State<TournamentForm> createState() => _TournamentFormState();
}

class _TournamentFormState extends State<TournamentForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _placeController = TextEditingController();
  final _sportTypeController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _eventUrlController = TextEditingController();

  TournamentStatus _selectedStatus = TournamentStatus.upcoming;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.tournament != null) {
      _populateFields(widget.tournament!);
    }
  }

  void _populateFields(Tournament tournament) {
    _nameController.text = tournament.name;
    _placeController.text = tournament.place;
    _sportTypeController.text = tournament.sportType;
    _startDateController.text = tournament.startDate;
    _endDateController.text = tournament.endDate;
    _descriptionController.text = tournament.description;
    _eventUrlController.text = tournament.eventUrl ?? '';
    
    setState(() {
      _selectedStatus = tournament.status;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _placeController.dispose();
    _sportTypeController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _descriptionController.dispose();
    _eventUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveTournament() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final tournament = Tournament(
        id: widget.tournament?.id ?? '',
        name: _nameController.text.trim(),
        place: _placeController.text.trim(),
        sportType: _sportTypeController.text.trim(),
        startDate: _startDateController.text.trim(),
        endDate: _endDateController.text.trim(),
        status: _selectedStatus,
        description: _descriptionController.text.trim(),
        eventUrl: _eventUrlController.text.trim().isEmpty ? null : _eventUrlController.text.trim(),
      );

      final dataService = AdminDataService.instance;
      
      if (widget.tournament != null) {
        // Update existing tournament
        await dataService.updateTournament(widget.tournament!.id, tournament);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tournament updated successfully'),
              backgroundColor: AdminTheme.successColor,
            ),
          );
        }
      } else {
        // Add new tournament
        await dataService.addTournament(tournament);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tournament added successfully'),
              backgroundColor: AdminTheme.successColor,
            ),
          );
        }
      }

      if (widget.onSaved != null) {
        widget.onSaved!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save tournament: ${e.toString()}'),
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
        title: Text(widget.tournament != null ? 'Edit Tournament' : 'Add Tournament'),
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
              onPressed: _saveTournament,
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
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tournament Name *',
                  hintText: 'Enter tournament name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tournament name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sport Type and Place
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sportTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Sport Type *',
                        hintText: 'e.g., Football, Tennis',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Sport type is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _placeController,
                      decoration: const InputDecoration(
                        labelText: 'Location *',
                        hintText: 'Enter tournament location',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Location is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Start Date and End Date
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      decoration: const InputDecoration(
                        labelText: 'Start Date *',
                        hintText: 'YYYY-MM-DD',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Start date is required';
                        }
                        // Basic date format validation
                        final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                        if (!dateRegex.hasMatch(value.trim())) {
                          return 'Use YYYY-MM-DD format';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _endDateController,
                      decoration: const InputDecoration(
                        labelText: 'End Date *',
                        hintText: 'YYYY-MM-DD',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'End date is required';
                        }
                        // Basic date format validation
                        final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                        if (!dateRegex.hasMatch(value.trim())) {
                          return 'Use YYYY-MM-DD format';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status
              DropdownButtonFormField<TournamentStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                ),
                items: TournamentStatus.values.map((status) {
                  return DropdownMenuItem<TournamentStatus>(
                    value: status,
                    child: Text(status.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Enter tournament description',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Event URL
              TextFormField(
                controller: _eventUrlController,
                decoration: const InputDecoration(
                  labelText: 'Event URL',
                  hintText: 'https://...',
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final uri = Uri.tryParse(value.trim());
                    if (uri == null || !(uri.hasAbsolutePath)) {
                      return 'Enter a valid URL';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Save button (mobile)
              if (MediaQuery.of(context).size.width <= 600)
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveTournament,
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
                      : Text(widget.tournament != null ? 'Update Tournament' : 'Add Tournament'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

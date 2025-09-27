import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/athlete.dart';
import '../services/admin_data_service.dart';
import '../services/csv_service.dart';
import '../theme/admin_theme.dart';
import '../../services/sports_service.dart';
import '../../models/sport_wiki.dart';

class AthleteForm extends StatefulWidget {
  final Athlete? athlete;
  final VoidCallback? onSaved;

  const AthleteForm({
    super.key,
    this.athlete,
    this.onSaved,
  });

  @override
  State<AthleteForm> createState() => _AthleteFormState();
}

class _AthleteFormState extends State<AthleteForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Basic info controllers
  final _nameController = TextEditingController();
  final _sportController = TextEditingController();
  final _placeOfBirthController = TextEditingController();
  final _educationController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Complex data
  bool _isParaAthlete = false;
  DateTime? _dateOfBirth;
  List<Achievement> _achievements = [];
  List<String> _awards = [];
  List<String> _funFacts = [];

  bool _isLoading = false;

  // Dynamic sports management
  List<SportWiki> _availableSports = [];
  bool _sportsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSports();
    
    if (widget.athlete != null) {
      _populateFields(widget.athlete!);
    }
  }

  Future<void> _loadSports() async {
    try {
      final sports = await SportsService().getActiveSports();
      if (mounted) {
        setState(() {
          _availableSports = sports;
          _sportsLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading sports: $e');
      if (mounted) {
        setState(() {
          _sportsLoading = false;
        });
      }
    }
  }

  void _populateFields(Athlete athlete) {
    _nameController.text = athlete.name;
    _sportController.text = athlete.sport;
    _placeOfBirthController.text = athlete.placeOfBirth;
    _educationController.text = athlete.education;
    _imageUrlController.text = athlete.imageUrl ?? '';
    _descriptionController.text = athlete.description;
    
    _isParaAthlete = athlete.isParaAthlete;
    _dateOfBirth = athlete.dob;
    _achievements = List.from(athlete.achievements);
    _awards = List.from(athlete.awards);
    _funFacts = List.from(athlete.funFacts);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sportController.dispose();
    _placeOfBirthController.dispose();
    _educationController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveAthlete() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final athlete = Athlete(
        id: widget.athlete?.id ?? '',
        name: _nameController.text.trim(),
        sport: _sportController.text.trim(),
        isParaAthlete: _isParaAthlete,
        dob: _dateOfBirth,
        placeOfBirth: _placeOfBirthController.text.trim(),
        education: _educationController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        description: _descriptionController.text.trim(),
        achievements: _achievements,
        awards: _awards,
        funFacts: _funFacts,
        lastUpdated: DateTime.now(),
      );

      final dataService = AdminDataService.instance;
      
      if (widget.athlete != null) {
        // Update existing athlete
        await dataService.updateAthlete(widget.athlete!.id, athlete);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Athlete updated successfully'),
              backgroundColor: AdminTheme.successColor,
            ),
          );
        }
      } else {
        // Add new athlete
        final athleteId = await dataService.addAthlete(athlete);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Athlete added successfully'),
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
            content: Text('Failed to save athlete: ${e.toString()}'),
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

  /// Date picker for date of birth
  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
    );
    
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  /// Add new achievement
  void _addAchievement() {
    showDialog(
      context: context,
      builder: (context) => _AchievementDialog(
        onSaved: (achievement) {
          setState(() {
            _achievements.add(achievement);
          });
        },
      ),
    );
  }

  /// Edit existing achievement
  void _editAchievement(int index) {
    showDialog(
      context: context,
      builder: (context) => _AchievementDialog(
        achievement: _achievements[index],
        onSaved: (achievement) {
          setState(() {
            _achievements[index] = achievement;
          });
        },
      ),
    );
  }

  /// Remove achievement
  void _removeAchievement(int index) {
    setState(() {
      _achievements.removeAt(index);
    });
  }

  /// Add new award
  void _addAward() {
    _showStringInputDialog(
      title: 'Add Award',
      hint: 'Enter award name',
      onSaved: (award) {
        setState(() {
          _awards.add(award);
        });
      },
    );
  }

  /// Add new fun fact
  void _addFunFact() {
    _showStringInputDialog(
      title: 'Add Fun Fact',
      hint: 'Enter fun fact',
      onSaved: (fact) {
        setState(() {
          _funFacts.add(fact);
        });
      },
    );
  }

  /// Generic string input dialog
  void _showStringInputDialog({
    required String title,
    required String hint,
    required Function(String) onSaved,
    String initialValue = '',
  }) {
    final controller = TextEditingController(text: initialValue);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          maxLines: null,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                onSaved(value);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.athlete != null ? 'Edit Athlete' : 'Add Athlete'),
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
              onPressed: _saveAthlete,
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
                  labelText: 'Athlete Name *',
                  hintText: 'Enter athlete name',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Athlete name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sport
              _sportsLoading
                  ? const LinearProgressIndicator()
                  : Autocomplete<SportWiki>(
                      initialValue: TextEditingValue(text: _sportController.text),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty || _availableSports.isEmpty) {
                          return const Iterable<SportWiki>.empty();
                        }
                        return _availableSports.where((sport) {
                          final searchText = textEditingValue.text.toLowerCase();
                          final sportName = sport.name.toLowerCase();
                          final displayName = (sport.displayName ?? sport.name).toLowerCase();
                          return sportName.contains(searchText) || displayName.contains(searchText);
                        });
                      },
                      displayStringForOption: (SportWiki sport) => sport.displayName ?? sport.name,
                      onSelected: (SportWiki selection) {
                        _sportController.text = selection.displayName ?? selection.name;
                      },
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Sport *',
                      hintText: 'Enter sport (e.g., Football, Tennis)',
                      suffixIcon: _availableSports.isNotEmpty 
                          ? PopupMenuButton<SportWiki>(
                              icon: const Icon(Icons.arrow_drop_down),
                              itemBuilder: (context) {
                                return _availableSports.take(10).map((sport) {
                                  final displayName = sport.displayName ?? sport.name;
                                  return PopupMenuItem<SportWiki>(
                                    value: sport,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          SportsService.getSportIconFromWiki(sport),
                                          size: 16,
                                          color: SportsService.getSportColor(sport),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            displayName,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList();
                              },
                              onSelected: (sport) {
                                final displayName = sport.displayName ?? sport.name;
                                textEditingController.text = displayName;
                                _sportController.text = displayName;
                              },
                            )
                          : null,
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Sport is required';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _sportController.text = value;
                    },
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              title: Text(option),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Description/Biography
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter general summary/biography of the athlete',
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  // Description is optional, so no validation needed
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Helper text
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
                          Icons.lightbulb_outline,
                          color: AdminTheme.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tips for a good athlete profile:',
                          style: AdminTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AdminTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Include major achievements and titles\n'
                      '• Mention career highlights and records\n'
                      '• Add current team/affiliation if applicable\n'
                      '• Keep information current and factual',
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
                  onPressed: _isLoading ? null : _saveAthlete,
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
                      : Text(widget.athlete != null ? 'Update Athlete' : 'Add Athlete'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

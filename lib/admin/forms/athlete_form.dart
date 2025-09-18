import 'package:flutter/material.dart';
import '../../models/athlete.dart';
import '../services/admin_data_service.dart';
import '../theme/admin_theme.dart';

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
  final _nameController = TextEditingController();
  final _sportController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = false;

  // Popular sports for suggestions
  final List<String> _popularSports = [
    'Football',
    'Basketball',
    'Tennis',
    'Cricket',
    'Baseball',
    'Soccer',
    'Golf',
    'Swimming',
    'Athletics',
    'Boxing',
    'Wrestling',
    'Volleyball',
    'Badminton',
    'Table Tennis',
    'Hockey',
    'Rugby',
  ];

  @override
  void initState() {
    super.initState();
    
    if (widget.athlete != null) {
      _populateFields(widget.athlete!);
    }
  }

  void _populateFields(Athlete athlete) {
    _nameController.text = athlete.name;
    _sportController.text = athlete.sport;
    _bioController.text = athlete.bio;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sportController.dispose();
    _bioController.dispose();
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
        bio: _bioController.text.trim(),
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
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _sportController.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return _popularSports.where((sport) => 
                    sport.toLowerCase().contains(textEditingValue.text.toLowerCase())
                  );
                },
                onSelected: (String selection) {
                  _sportController.text = selection;
                },
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Sport *',
                      hintText: 'Enter sport (e.g., Football, Tennis)',
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        itemBuilder: (context) {
                          return _popularSports.map((sport) {
                            return PopupMenuItem<String>(
                              value: sport,
                              child: Text(sport),
                            );
                          }).toList();
                        },
                        onSelected: (sport) {
                          textEditingController.text = sport;
                          _sportController.text = sport;
                        },
                      ),
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

              // Bio
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Biography *',
                  hintText: 'Enter athlete biography and achievements',
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Biography is required';
                  }
                  if (value.trim().length < 20) {
                    return 'Biography should be at least 20 characters long';
                  }
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

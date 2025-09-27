import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/athlete.dart';
import '../services/admin_data_service.dart';
import '../services/csv_service.dart';
import '../services/ai_enhancement_service.dart';
import '../theme/admin_theme.dart';
import '../../services/sports_service.dart';
import '../../models/sport_wiki.dart';

class EnhancedAthleteForm extends StatefulWidget {
  final Athlete? athlete;
  final VoidCallback? onSaved;

  const EnhancedAthleteForm({
    super.key,
    this.athlete,
    this.onSaved,
  });

  @override
  State<EnhancedAthleteForm> createState() => _EnhancedAthleteFormState();
}

class _EnhancedAthleteFormState extends State<EnhancedAthleteForm> {
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

  // AI Enhancement state
  bool _isEnhancing = false;
  AiEnhancementResult? _aiResult;
  Map<String, dynamic> _aiGeneratedData = {};
  Set<String> _reviewedFields = {}; // Track which AI fields admin has reviewed

  // Popular sports from CSV service
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
      final sportsService = SportsService();
      final sports = await sportsService.getActiveSports();
      
      if (mounted) {
        setState(() {
          _availableSports = sports;
          _sportsLoading = false;
        });
      }
    } catch (e) {
      print('Error loading sports: $e');
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
              content: Text('✅ Athlete updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Add new athlete
        await dataService.addAthlete(athlete);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Athlete added successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      // Call the onSaved callback
      if (widget.onSaved != null) {
        widget.onSaved!();
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving athlete: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 4),
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
      builder: (context) => AchievementDialog(
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
      builder: (context) => AchievementDialog(
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: AdminTheme.headlineMedium.copyWith(
          color: AdminTheme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAchievementsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_achievements.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(Icons.emoji_events_outlined, 
                     size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('No achievements added yet', 
                     style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          )
        else
          ...List.generate(_achievements.length, (index) {
            final achievement = _achievements[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AdminTheme.primaryColor,
                  child: Text(
                    achievement.year.toString().substring(2),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                title: Text(achievement.title),
                subtitle: Text('${achievement.year}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _editAchievement(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () => _removeAchievement(index),
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            );
          }),
        
        const SizedBox(height: 8),
        
        ElevatedButton.icon(
          onPressed: _addAchievement,
          icon: const Icon(Icons.add),
          label: const Text('Add Achievement'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStringsList({
    required List<String> items,
    required String emptyMessage,
    required VoidCallback onAdd,
    required Function(int) onEdit,
    required Function(int) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(Icons.list_outlined, 
                     size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(emptyMessage, 
                     style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          )
        else
          ...List.generate(items.length, (index) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AdminTheme.primaryColor,
                  radius: 16,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                title: Text(items[index]),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => onEdit(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () => onRemove(index),
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            );
          }),
        
        const SizedBox(height: 8),
        
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: Text(emptyMessage.contains('award') ? 'Add Award' : 'Add Fun Fact'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Enhance athlete profile using AI
  Future<void> _enhanceWithAI() async {
    // Validate required fields first
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please enter athlete name first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_sportController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please enter sport first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isEnhancing = true;
      _aiResult = null;
      _reviewedFields.clear();
    });

    try {
      // Prepare current data
      final currentData = AiEnhancementService.instance.athleteToCurrentData(
        Athlete(
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
        ),
      );

      // Call AI enhancement service
      final result = await AiEnhancementService.instance.enhanceAthleteProfile(
        athleteName: _nameController.text.trim(),
        sport: _sportController.text.trim(),
        currentData: currentData,
      );

      setState(() {
        _aiResult = result;
        _aiGeneratedData = Map<String, dynamic>.from(result.enhancedData.fields);
      });

      if (result.success && result.enhancedData.athleteFound) {
        // Apply AI data to form
        _applyAIDataToForm(result);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ AI Enhancement Complete! ${result.enhancedData.confidence}% confidence',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.enhancedData.athleteFound 
                ? '⚠️ ${result.message}' 
                : '❌ No information found for this athlete',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }

    } catch (e) {
      print('❌ AI Enhancement error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ AI Enhancement failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _isEnhancing = false;
      });
    }
  }

  /// Apply AI-generated data to form fields
  void _applyAIDataToForm(AiEnhancementResult result) {
    final fields = result.enhancedData.fields;

    fields.forEach((fieldName, value) {
      switch (fieldName) {
        case 'dob':
          if (value is String && value.isNotEmpty) {
            try {
              _dateOfBirth = DateTime.parse(value);
            } catch (e) {
              print('Error parsing DOB: $value');
            }
          }
          break;

        case 'placeOfBirth':
          if (value is String && _placeOfBirthController.text.trim().isEmpty) {
            _placeOfBirthController.text = value;
          }
          break;

        case 'education':
          if (value is String && _educationController.text.trim().isEmpty) {
            _educationController.text = value;
          }
          break;

        case 'description':
          if (value is String && _descriptionController.text.trim().isEmpty) {
            _descriptionController.text = value;
          }
          break;

        case 'isParaAthlete':
          if (value is bool) {
            _isParaAthlete = value;
          }
          break;

        case 'achievements':
          if (value is List && _achievements.isEmpty) {
            _achievements = (value as List)
                .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          break;

        case 'awards':
          if (value is List && _awards.isEmpty) {
            _awards = List<String>.from(value);
          }
          break;

        case 'funFacts':
          if (value is List && _funFacts.isEmpty) {
            _funFacts = List<String>.from(value);
          }
          break;
      }
    });
  }

  /// Build AI Enhancement button
  Widget _buildAIEnhancementButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton.icon(
        onPressed: _isEnhancing ? null : _enhanceWithAI,
        icon: _isEnhancing 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(
          _isEnhancing 
              ? 'Enhancing with AI...' 
              : '✨ Enhance with AI',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isEnhancing ? Colors.grey : Colors.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Build AI Enhancement status card
  Widget _buildAIStatusCard() {
    if (_aiResult == null) return const SizedBox.shrink();

    final data = _aiResult!.enhancedData;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: data.athleteFound ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: data.athleteFound ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                data.athleteFound ? Icons.check_circle : Icons.info,
                color: data.athleteFound ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Enhancement Results',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: data.athleteFound ? Colors.green[800] : Colors.orange[800],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(data.confidence),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${data.confidence}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          if (data.athleteFound) ...[
            Text(
              'Enhanced ${data.fields.length} field(s) • ${data.confidenceDescription}',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 14,
              ),
            ),
            if (data.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                data.notes,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            
            if (_aiResult!.usage != null) ...[
              const SizedBox(height: 8),
              Text(
                'Tokens used: ${_aiResult!.usage!.totalTokens} (~\$${_aiResult!.usage!.estimatedCost.toStringAsFixed(4)})',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ] else ...[
            Text(
              data.notes.isNotEmpty ? data.notes : 'No reliable information found',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Get confidence color based on percentage
  Color _getConfidenceColor(int confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.orange;
    return Colors.red;
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
              // Basic Information Section
              _buildSectionHeader('Basic Information'),
              
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

              // Sport with dynamic autocomplete
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
                            hintText: 'Enter or select sport',
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
                    ),
              const SizedBox(height: 16),

              // Para Athlete checkbox
              CheckboxListTile(
                title: const Text('Para Athlete'),
                subtitle: const Text('Check if this athlete competes in Paralympic sports'),
                value: _isParaAthlete,
                onChanged: (value) {
                  setState(() {
                    _isParaAthlete = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),

              // Date of Birth
              InkWell(
                onTap: _selectDateOfBirth,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    hintText: 'Select date of birth',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _dateOfBirth == null 
                        ? 'Select date of birth'
                        : DateFormat('MMM dd, yyyy').format(_dateOfBirth!),
                    style: TextStyle(
                      color: _dateOfBirth == null 
                          ? Theme.of(context).hintColor 
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Place of Birth
              TextFormField(
                controller: _placeOfBirthController,
                decoration: const InputDecoration(
                  labelText: 'Place of Birth',
                  hintText: 'Enter birthplace (e.g., Delhi, India)',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Education
              TextFormField(
                controller: _educationController,
                decoration: const InputDecoration(
                  labelText: 'Education',
                  hintText: 'Enter educational background',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Image URL
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'Enter profile image URL',
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final uri = Uri.tryParse(value.trim());
                    if (uri == null || !uri.hasScheme) {
                      return 'Please enter a valid URL';
                    }
                  }
                  return null;
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
              
              // AI Enhancement Section
              _buildAIEnhancementButton(),
              _buildAIStatusCard(),
              
              const SizedBox(height: 16),

              // Achievements Section
              _buildSectionHeader('Achievements'),
              _buildAchievementsList(),
              
              const SizedBox(height: 24),

              // Awards Section
              _buildSectionHeader('Awards'),
              _buildStringsList(
                items: _awards,
                emptyMessage: 'No awards added yet',
                onAdd: _addAward,
                onEdit: (index) => _showStringInputDialog(
                  title: 'Edit Award',
                  hint: 'Enter award name',
                  initialValue: _awards[index],
                  onSaved: (value) {
                    setState(() {
                      _awards[index] = value;
                    });
                  },
                ),
                onRemove: (index) {
                  setState(() {
                    _awards.removeAt(index);
                  });
                },
              ),
              
              const SizedBox(height: 24),

              // Fun Facts Section
              _buildSectionHeader('Fun Facts'),
              _buildStringsList(
                items: _funFacts,
                emptyMessage: 'No fun facts added yet',
                onAdd: _addFunFact,
                onEdit: (index) => _showStringInputDialog(
                  title: 'Edit Fun Fact',
                  hint: 'Enter fun fact',
                  initialValue: _funFacts[index],
                  onSaved: (value) {
                    setState(() {
                      _funFacts[index] = value;
                    });
                  },
                ),
                onRemove: (index) {
                  setState(() {
                    _funFacts.removeAt(index);
                  });
                },
              ),

              const SizedBox(height: 32),

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
                          'Enhanced Athlete Profile Tips:',
                          style: AdminTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AdminTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Basic info can be bulk imported via CSV\n'
                      '• Achievements, awards, and fun facts enhance user engagement\n'
                      '• Profile images improve visual appeal\n'
                      '• Complete profiles increase discoverability',
                      style: AdminTheme.caption.copyWith(
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog for adding/editing achievements
class AchievementDialog extends StatefulWidget {
  final Achievement? achievement;
  final Function(Achievement) onSaved;

  const AchievementDialog({
    super.key,
    this.achievement,
    required this.onSaved,
  });

  @override
  State<AchievementDialog> createState() => _AchievementDialogState();
}

class _AchievementDialogState extends State<AchievementDialog> {
  final _titleController = TextEditingController();
  final _yearController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.achievement != null) {
      _titleController.text = widget.achievement!.title;
      _yearController.text = widget.achievement!.year.toString();
    } else {
      _yearController.text = DateTime.now().year.toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.achievement != null ? 'Edit Achievement' : 'Add Achievement'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Achievement Title *',
                hintText: 'e.g., Olympic Gold Medal',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: 'Year *',
                hintText: 'e.g., 2024',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Year is required';
                }
                final year = int.tryParse(value.trim());
                if (year == null) {
                  return 'Please enter a valid year';
                }
                if (year < 1900 || year > DateTime.now().year + 10) {
                  return 'Please enter a realistic year';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final achievement = Achievement(
                title: _titleController.text.trim(),
                year: int.parse(_yearController.text.trim()),
              );
              widget.onSaved(achievement);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

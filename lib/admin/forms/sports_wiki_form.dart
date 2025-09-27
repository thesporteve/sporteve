import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/sport_wiki.dart';
import '../services/admin_sports_wiki_service.dart';
import '../theme/admin_theme.dart';

class SportsWikiForm extends StatefulWidget {
  final SportWiki? sportWiki;
  final Function(SportWiki) onSaved;
  final VoidCallback onCancel;

  const SportsWikiForm({
    super.key,
    this.sportWiki,
    required this.onSaved,
    required this.onCancel,
  });

  @override
  State<SportsWikiForm> createState() => _SportsWikiFormState();
}

class _SportsWikiFormState extends State<SportsWikiForm> {
  final _formKey = GlobalKey<FormState>();
  final AdminSportsWikiService _wikiService = AdminSportsWikiService.instance;

  // Controllers for form fields
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _originController;
  late TextEditingController _governingBodyController;
  late TextEditingController _rulesSummaryController;
  late TextEditingController _playerCountController;
  late TextEditingController _seasonalPlayController;
  late TextEditingController _regionalPopularityController;
  late TextEditingController _iconicMomentsController;

  // Multi-line field controllers
  late TextEditingController _famousAthletesController;
  late TextEditingController _popularEventsController;
  late TextEditingController _equipmentNeededController;
  late TextEditingController _physicalDemandsController;
  late TextEditingController _funFactsController;
  late TextEditingController _tagsController;
  late TextEditingController _relatedSportsController;
  late TextEditingController _indianMilestonesController;
  
  // UI-specific field controllers
  late TextEditingController _displayNameController;
  late TextEditingController _iconNameController;
  late TextEditingController _primaryColorController;
  late TextEditingController _sortOrderController;

  // Dropdown values
  String _selectedCategory = 'Team Sport';
  String _selectedType = 'Outdoor';
  String _selectedDifficulty = 'Medium';
  bool _isOlympicSport = false;
  bool _isActive = true;

  // Image handling
  Map<String, String> _currentImages = {};
  Map<String, Uint8List?> _newImageData = {};
  Map<String, String> _newImageNames = {};

  bool _isLoading = false;
  bool _isSaving = false;

  final List<String> _categories = ['Team Sport', 'Individual Sport', 'Mixed Sport'];
  final List<String> _types = ['Outdoor', 'Indoor', 'Water', 'Combat'];
  final List<String> _difficulties = ['Beginner', 'Medium', 'Advanced'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _populateFormIfEditing();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _originController = TextEditingController();
    _governingBodyController = TextEditingController();
    _rulesSummaryController = TextEditingController();
    _playerCountController = TextEditingController();
    _seasonalPlayController = TextEditingController();
    _regionalPopularityController = TextEditingController();
    _iconicMomentsController = TextEditingController();
    _famousAthletesController = TextEditingController();
    _popularEventsController = TextEditingController();
    _equipmentNeededController = TextEditingController();
    _physicalDemandsController = TextEditingController();
    _funFactsController = TextEditingController();
    _tagsController = TextEditingController();
    _relatedSportsController = TextEditingController();
    _indianMilestonesController = TextEditingController();
    
    // UI-specific field controllers
    _displayNameController = TextEditingController();
    _iconNameController = TextEditingController();
    _primaryColorController = TextEditingController();
    _sortOrderController = TextEditingController();
  }

  void _populateFormIfEditing() {
    if (widget.sportWiki != null) {
      final sport = widget.sportWiki!;
      
      _nameController.text = sport.name;
      _descriptionController.text = sport.description;
      _originController.text = sport.origin ?? '';
      _governingBodyController.text = sport.governingBody ?? '';
      _rulesSummaryController.text = sport.rulesSummary ?? '';
      _playerCountController.text = sport.playerCount ?? '';
      _seasonalPlayController.text = sport.seasonalPlay ?? '';
      _regionalPopularityController.text = sport.regionalPopularity ?? '';
      _iconicMomentsController.text = sport.iconicMoments ?? '';

      _selectedCategory = sport.category;
      _selectedType = sport.type;
      _selectedDifficulty = sport.difficultyLevel ?? 'Medium';
      _isOlympicSport = sport.olympicSport ?? false;

      // Handle list fields
      _famousAthletesController.text = sport.famousAthletes?.join('\n') ?? '';
      _popularEventsController.text = sport.popularEvents?.join('\n') ?? '';
      _equipmentNeededController.text = sport.equipmentNeeded?.join('\n') ?? '';
      _physicalDemandsController.text = sport.physicalDemands?.join('\n') ?? '';
      _funFactsController.text = sport.funFacts?.join('\n') ?? '';
      _tagsController.text = sport.tags?.join(', ') ?? '';
      _relatedSportsController.text = sport.relatedSports?.join(', ') ?? '';
      _indianMilestonesController.text = sport.indianMilestones?.join('\n') ?? '';

      // UI-specific fields
      _displayNameController.text = sport.displayName ?? '';
      _iconNameController.text = sport.iconName ?? '';
      _primaryColorController.text = sport.primaryColor ?? '';
      _sortOrderController.text = sport.sortOrder.toString();
      _isActive = sport.isActive;

      // Handle existing images
      _currentImages = sport.images ?? {};
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _originController.dispose();
    _governingBodyController.dispose();
    _rulesSummaryController.dispose();
    _playerCountController.dispose();
    _seasonalPlayController.dispose();
    _regionalPopularityController.dispose();
    _iconicMomentsController.dispose();
    _famousAthletesController.dispose();
    _popularEventsController.dispose();
    _equipmentNeededController.dispose();
    _physicalDemandsController.dispose();
    _funFactsController.dispose();
    _tagsController.dispose();
    _relatedSportsController.dispose();
    _indianMilestonesController.dispose();
    
    // UI-specific field controllers
    _displayNameController.dispose();
    _iconNameController.dispose();
    _primaryColorController.dispose();
    _sortOrderController.dispose();
    
    super.dispose();
  }

  List<String> _parseListField(String text) {
    if (text.isEmpty) return [];
    return text.split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<String> _parseCommaField(String text) {
    if (text.isEmpty) return [];
    return text.split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _pickImage(String imageType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null) {
        final file = result.files.first;
        setState(() {
          _newImageData[imageType] = file.bytes;
          _newImageNames[imageType] = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _removeImage(String imageType) async {
    setState(() {
      _newImageData.remove(imageType);
      _newImageNames.remove(imageType);
      if (_currentImages.containsKey(imageType)) {
        // Mark for deletion
        _currentImages[imageType] = '';
      }
    });
  }

  Widget _buildImageUploadSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Images',
              style: AdminTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Upload images to make your sports wiki more engaging. All images are optional.',
              style: AdminTheme.bodyMedium.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            
            // Hero Image
            _buildImageUploadCard('hero', 'Hero Image', 'Main image representing the sport'),
            const SizedBox(height: 12),
            
            // Equipment Image
            _buildImageUploadCard('equipment', 'Equipment Image', 'Essential equipment and gear'),
            const SizedBox(height: 12),
            
            // Action Image
            _buildImageUploadCard('action', 'Action Shot', 'Sport in action or gameplay'),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadCard(String imageType, String title, String description) {
    final hasCurrentImage = _currentImages.containsKey(imageType) && 
                           _currentImages[imageType]!.isNotEmpty;
    final hasNewImage = _newImageData.containsKey(imageType);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AdminTheme.titleSmall),
                    Text(
                      description,
                      style: AdminTheme.bodySmall.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (hasNewImage || hasCurrentImage) ...[
                TextButton.icon(
                  onPressed: () => _removeImage(imageType),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(
                    foregroundColor: AdminTheme.errorColor,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              OutlinedButton.icon(
                onPressed: () => _pickImage(imageType),
                icon: const Icon(Icons.upload, size: 16),
                label: Text(hasNewImage || hasCurrentImage ? 'Replace' : 'Upload'),
              ),
            ],
          ),
          
          if (hasNewImage) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'New image selected: ${_newImageNames[imageType]}',
                      style: AdminTheme.bodySmall.copyWith(color: Colors.green[700]),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (hasCurrentImage) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.image, color: Colors.blue[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Current image uploaded',
                    style: AdminTheme.bodySmall.copyWith(color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveSportsWiki() async {
    if (!_formKey.currentState!.validate()) return;

    // Check name uniqueness for new entries
    if (widget.sportWiki == null) {
      final isUnique = await _wikiService.isNameUnique(_nameController.text);
      if (!isUnique) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('A sport with the name "${_nameController.text}" already exists'),
              backgroundColor: AdminTheme.errorColor,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Upload new images
      Map<String, String> finalImages = Map.from(_currentImages);
      
      for (final entry in _newImageData.entries) {
        if (entry.value != null) {
          final imageUrl = await _wikiService.uploadImage(
            sportName: _nameController.text,
            imageType: entry.key,
            imageData: entry.value!,
            fileName: _newImageNames[entry.key] ?? 'image.jpg',
          );
          
          if (imageUrl != null) {
            finalImages[entry.key] = imageUrl;
          }
        }
      }

      // Remove empty image entries
      finalImages.removeWhere((key, value) => value.isEmpty);

      // Create sport wiki object
      final sportWiki = SportWiki(
        id: widget.sportWiki?.id ?? '',
        name: _nameController.text.trim(),
        category: _selectedCategory,
        type: _selectedType,
        description: _descriptionController.text.trim(),
        origin: _originController.text.trim().isEmpty ? null : _originController.text.trim(),
        governingBody: _governingBodyController.text.trim().isEmpty ? null : _governingBodyController.text.trim(),
        olympicSport: _isOlympicSport,
        rulesSummary: _rulesSummaryController.text.trim().isEmpty ? null : _rulesSummaryController.text.trim(),
        playerCount: _playerCountController.text.trim().isEmpty ? null : _playerCountController.text.trim(),
        difficultyLevel: _selectedDifficulty,
        seasonalPlay: _seasonalPlayController.text.trim().isEmpty ? null : _seasonalPlayController.text.trim(),
        famousAthletes: _parseListField(_famousAthletesController.text),
        popularEvents: _parseListField(_popularEventsController.text),
        equipmentNeeded: _parseListField(_equipmentNeededController.text),
        physicalDemands: _parseListField(_physicalDemandsController.text),
        funFacts: _parseListField(_funFactsController.text),
        tags: _parseCommaField(_tagsController.text),
        relatedSports: _parseCommaField(_relatedSportsController.text),
        images: finalImages.isEmpty ? null : finalImages,
        indianMilestones: _parseListField(_indianMilestonesController.text),
        regionalPopularity: _regionalPopularityController.text.trim().isEmpty ? null : _regionalPopularityController.text.trim(),
        iconicMoments: _iconicMomentsController.text.trim().isEmpty ? null : _iconicMomentsController.text.trim(),
        // UI-specific fields
        displayName: _displayNameController.text.trim().isEmpty ? null : _displayNameController.text.trim(),
        iconName: _iconNameController.text.trim().isEmpty ? null : _iconNameController.text.trim(),
        primaryColor: _primaryColorController.text.trim().isEmpty ? null : _primaryColorController.text.trim(),
        isActive: _isActive,
        sortOrder: int.tryParse(_sortOrderController.text.trim()) ?? 1000,
        createdAt: widget.sportWiki?.createdAt ?? DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      // Save to database
      if (widget.sportWiki == null) {
        await _wikiService.addSportsWikiEntry(sportWiki);
      } else {
        await _wikiService.updateSportsWikiEntry(widget.sportWiki!.id, sportWiki);
      }

      widget.onSaved(sportWiki);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save sports wiki: $e'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool required = false,
    int maxLines = 1,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: required ? '$label *' : label,
            hintText: hint,
            helperText: helperText,
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '$label is required';
                  }
                  return null;
                }
              : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: AdminTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildFormField(
                      label: 'Sport Name',
                      controller: _nameController,
                      hint: 'e.g., Cricket, Football, Tennis',
                            required: true,
                          ),
                          
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  decoration: const InputDecoration(
                                    labelText: 'Category *',
                                    border: OutlineInputBorder(),
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
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedType,
                                  decoration: const InputDecoration(
                                    labelText: 'Type *',
                                    border: OutlineInputBorder(),
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
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          _buildFormField(
                            label: 'Description',
                            controller: _descriptionController,
                            hint: 'Brief description of the sport...',
                            required: true,
                            maxLines: 4,
                            helperText: 'A compelling description that introduces the sport to users',
                          ),
                          
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedDifficulty,
                                  decoration: const InputDecoration(
                                    labelText: 'Difficulty Level',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _difficulties.map((difficulty) {
                                    return DropdownMenuItem(
                                      value: difficulty,
                                      child: Text(difficulty),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedDifficulty = value!;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CheckboxListTile(
                                  title: const Text('Olympic Sport'),
                                  value: _isOlympicSport,
                                  onChanged: (value) {
                                    setState(() {
                                      _isOlympicSport = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // UI Configuration Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UI Configuration',
                            style: AdminTheme.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _displayNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Display Name',
                                    hintText: 'e.g., Football (if different from name)',
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _iconNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Icon Name',
                                    hintText: 'e.g., sports_soccer, sports_cricket',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _primaryColorController,
                                  decoration: const InputDecoration(
                                    labelText: 'Primary Color',
                                    hintText: 'e.g., #4CAF50',
                                  ),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
                                        return 'Enter valid hex color (e.g., #4CAF50)';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _sortOrderController,
                                  decoration: const InputDecoration(
                                    labelText: 'Sort Order',
                                    hintText: 'e.g., 100 (lower = higher priority)',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      if (int.tryParse(value) == null) {
                                        return 'Enter a valid number';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          CheckboxListTile(
                            title: const Text('Active'),
                            subtitle: const Text('Show in dropdowns and forms'),
                            value: _isActive,
                            onChanged: (value) {
                              setState(() {
                                _isActive = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Detailed Information Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detailed Information',
                            style: AdminTheme.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildFormField(
                            label: 'Origin',
                            controller: _originController,
                            hint: 'e.g., England, 16th century',
                          ),
                          
                          _buildFormField(
                            label: 'Governing Body',
                            controller: _governingBodyController,
                            hint: 'e.g., International Cricket Council (ICC)',
                          ),
                          
                          _buildFormField(
                            label: 'Player Count',
                            controller: _playerCountController,
                            hint: 'e.g., 11 per team, Individual',
                          ),
                          
                          _buildFormField(
                            label: 'Seasonal Play',
                            controller: _seasonalPlayController,
                            hint: 'e.g., Year-round, Summer, Winter',
                          ),
                          
                          _buildFormField(
                            label: 'Rules Summary',
                            controller: _rulesSummaryController,
                            hint: 'Brief overview of basic rules...',
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lists Information Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lists & Details',
                            style: AdminTheme.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildFormField(
                            label: 'Famous Athletes',
                            controller: _famousAthletesController,
                            hint: 'One athlete per line...',
                            maxLines: 4,
                            helperText: 'Enter each athlete name on a new line',
                          ),
                          
                          _buildFormField(
                            label: 'Popular Events',
                            controller: _popularEventsController,
                            hint: 'One event per line...',
                            maxLines: 4,
                            helperText: 'Major tournaments, championships, etc.',
                          ),
                          
                          _buildFormField(
                            label: 'Equipment Needed',
                            controller: _equipmentNeededController,
                            hint: 'One item per line...',
                            maxLines: 3,
                            helperText: 'Essential equipment and gear',
                          ),
                          
                          _buildFormField(
                            label: 'Physical Demands',
                            controller: _physicalDemandsController,
                            hint: 'One demand per line...',
                            maxLines: 3,
                            helperText: 'Key physical requirements',
                          ),
                          
                          _buildFormField(
                            label: 'Fun Facts',
                            controller: _funFactsController,
                            hint: 'One fact per line...',
                            maxLines: 5,
                            helperText: 'Interesting trivia about the sport',
                          ),
                          
                          _buildFormField(
                            label: 'Tags',
                            controller: _tagsController,
                            hint: 'tag1, tag2, tag3...',
                            helperText: 'Comma-separated keywords for search',
                          ),
                          
                          _buildFormField(
                            label: 'Related Sports',
                            controller: _relatedSportsController,
                            hint: 'sport1, sport2, sport3...',
                            helperText: 'Comma-separated similar or related sports',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Indian Context Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Indian Context',
                            style: AdminTheme.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildFormField(
                            label: 'Indian Milestones',
                            controller: _indianMilestonesController,
                            hint: 'One milestone per line...',
                            maxLines: 4,
                            helperText: 'Key achievements in Indian sports history',
                          ),
                          
                          _buildFormField(
                            label: 'Regional Popularity',
                            controller: _regionalPopularityController,
                            hint: 'e.g., Popular in Maharashtra, Tamil Nadu...',
                            maxLines: 2,
                          ),
                          
                          _buildFormField(
                            label: 'Iconic Moments',
                            controller: _iconicMomentsController,
                            hint: 'Memorable moments in Indian context...',
                            maxLines: 3,
                            helperText: 'Historic moments that defined the sport in India',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Image Upload Section
                  _buildImageUploadSection(),
            
            // Action buttons
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveSportsWiki,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Saving...'),
                            ],
                          )
                        : Text(widget.sportWiki == null ? 'Create Sport' : 'Update Sport'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

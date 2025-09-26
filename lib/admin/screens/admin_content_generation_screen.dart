import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/content_feed.dart';
import '../../models/content_generation_request.dart';
import '../services/admin_content_service.dart';
import '../services/admin_sports_wiki_service.dart';
import '../providers/admin_auth_provider.dart';
import '../theme/admin_theme.dart';
import 'package:intl/intl.dart';

class AdminContentGenerationScreen extends StatefulWidget {
  const AdminContentGenerationScreen({super.key});

  @override
  State<AdminContentGenerationScreen> createState() => _AdminContentGenerationScreenState();
}

class _AdminContentGenerationScreenState extends State<AdminContentGenerationScreen> {
  final AdminContentService _contentService = AdminContentService.instance;
  final AdminSportsWikiService _sportsWikiService = AdminSportsWikiService.instance;
  
  List<String> _availableSports = [];
  List<ContentGenerationRequest> _activeRequests = [];
  List<ContentGenerationRequest> _recentRequests = [];
  bool _isLoading = true;
  String? _error;

  // Form state
  String _selectedContentType = 'bulk_trivia';
  String _selectedSport = '';
  int _quantity = 1;
  String _selectedDifficulty = 'medium';
  String _selectedAgeGroup = '8-16';
  String _selectedSourceType = 'mixed';
  
  // Manual content creation form state
  String _manualContentType = 'single_parent_tip';
  String _manualSport = '';
  final TextEditingController _manualTitleController = TextEditingController();
  final TextEditingController _manualContentController = TextEditingController();
  final TextEditingController _manualBenefitsController = TextEditingController();
  final TextEditingController _manualAgeGroupController = TextEditingController();
  final TextEditingController _manualCategoryController = TextEditingController();
  final TextEditingController _manualDetailsController = TextEditingController();
  bool _isManualSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load available sports from sports wiki
      final sportsWiki = await _sportsWikiService.getAllSportsWiki();
      final sportNames = sportsWiki.map((wiki) => wiki.name).toList();
      
      // Load active and recent generation requests
      final activeRequests = await _contentService.getActiveGenerationRequests();
      final allRequests = await _contentService.getAllGenerationRequests();
      final recentRequests = allRequests.take(10).toList();

      setState(() {
        _availableSports = sportNames;
        if (_availableSports.isNotEmpty) {
          _selectedSport = _availableSports.first;
          _manualSport = _availableSports.first;
        }
        _activeRequests = activeRequests;
        _recentRequests = recentRequests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateContent(BuildContext context) async {
    if (_selectedSport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a sport'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Starting content generation...'),
            ],
          ),
        ),
      );

      final request = await _contentService.requestContentGeneration(
        requestType: GenerationRequestType.fromString(_selectedContentType),
        sportCategory: _selectedSport,
        quantity: _quantity,
        requestedBy: authProvider.currentAdmin ?? 'unknown',
        adminEmail: authProvider.email,
        difficultyLevel: DifficultyLevel.fromString(_selectedDifficulty),
        ageGroup: _selectedAgeGroup,
        sourceType: _selectedSourceType,
      );

      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Content generation started! Request ID: ${request.id}'),
          backgroundColor: AdminTheme.successColor,
          action: SnackBarAction(
            label: 'View Progress',
            onPressed: () {
              // Scroll to active requests section
              _scrollToActiveRequests();
            },
          ),
        ),
      );

      _loadInitialData(); // Refresh data

    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start generation: $e'),
          backgroundColor: AdminTheme.errorColor,
        ),
      );
    }
  }

  void _scrollToActiveRequests() {
    // Implementation for scrolling to active requests section
    // For now, just refresh the data
    _loadInitialData();
  }

  Future<void> _cancelRequest(String requestId) async {
    try {
      await _contentService.cancelGenerationRequest(requestId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generation request cancelled'),
          backgroundColor: AdminTheme.successColor,
        ),
      );
      
      _loadInitialData(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel request: $e'),
          backgroundColor: AdminTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _deleteRequest(String requestId) async {
    try {
      await _contentService.deleteGenerationRequest(requestId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generation request deleted'),
          backgroundColor: AdminTheme.successColor,
        ),
      );
      
      _loadInitialData(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete request: $e'),
          backgroundColor: AdminTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _cleanupStuckRequests() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cleanup Stuck Requests'),
        content: const Text(
          'This will mark all pending or processing requests older than 1 hour as failed. Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.errorColor),
            child: const Text('Cleanup'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final cleanedCount = await _contentService.cleanupStuckRequests();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cleaned up $cleanedCount stuck requests'),
          backgroundColor: AdminTheme.successColor,
        ),
      );
      
      _loadInitialData(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cleanup requests: $e'),
          backgroundColor: AdminTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _submitManualContent() async {
    if (_manualSport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a sport'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);

    try {
      setState(() {
        _isManualSubmitting = true;
      });

      // Create the content based on the type
      Map<String, dynamic> contentData = {};
      
      if (_manualContentType == 'single_parent_tip') {
        if (_manualTitleController.text.trim().isEmpty || _manualContentController.text.trim().isEmpty) {
          throw Exception('Title and content are required for Health Tips');
        }
        
        final benefits = _manualBenefitsController.text.trim().isNotEmpty 
            ? _manualBenefitsController.text.split('\n').where((b) => b.trim().isNotEmpty).toList()
            : <String>[];
            
        contentData = {
          'title': _manualTitleController.text.trim(),
          'content': _manualContentController.text.trim(),
          'benefits': benefits,
          'age_group': _manualAgeGroupController.text.trim().isNotEmpty 
              ? _manualAgeGroupController.text.trim() 
              : '8-16',
        };
      } else if (_manualContentType == 'sport_facts') {
        if (_manualTitleController.text.trim().isEmpty || _manualDetailsController.text.trim().isEmpty) {
          throw Exception('Fact and details are required for Did You Know content');
        }
        
        contentData = {
          'fact': _manualTitleController.text.trim(),
          'details': _manualDetailsController.text.trim(),
          'category': _manualCategoryController.text.trim().isNotEmpty 
              ? _manualCategoryController.text.trim() 
              : 'General',
        };
      }

      // Create the content feed directly
      final contentFeed = ContentFeed(
        id: '', // Will be generated by Firestore
        type: _manualContentType == 'single_parent_tip' ? ContentType.parentTip : ContentType.didYouKnow,
        status: ContentStatus.generated, // Start as generated for review
        sportCategory: _manualSport,
        parentTipContent: _manualContentType == 'single_parent_tip' ? ParentTipContent.fromFirestore(contentData) : null,
        didYouKnowContent: _manualContentType == 'sport_facts' ? DidYouKnowContent.fromFirestore(contentData) : null,
        triviaContent: null,
        generationSource: 'manual_admin',
        sourceSportsWikiId: null,
        aiPromptUsed: 'Manual content creation by admin',
        createdAt: DateTime.now(),
        approvedAt: null,
        approvedBy: null,
        publishedAt: null,
        viewCount: 0,
        likeCount: 0,
      );

      // Save to Firestore
      await _contentService.createManualContent(contentFeed, authProvider.currentAdmin ?? 'unknown');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Manual ${_manualContentType == "single_parent_tip" ? "Health Tip" : "Did You Know"} created successfully!'),
          backgroundColor: AdminTheme.successColor,
        ),
      );

      // Clear the form
      _clearManualForm();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create content: $e'),
          backgroundColor: AdminTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isManualSubmitting = false;
      });
    }
  }

  void _clearManualForm() {
    _manualTitleController.clear();
    _manualContentController.clear();
    _manualBenefitsController.clear();
    _manualAgeGroupController.clear();
    _manualCategoryController.clear();
    _manualDetailsController.clear();
  }

  @override
  void dispose() {
    _manualTitleController.dispose();
    _manualContentController.dispose();
    _manualBenefitsController.dispose();
    _manualAgeGroupController.dispose();
    _manualCategoryController.dispose();
    _manualDetailsController.dispose();
    super.dispose();
  }

  Widget _buildManualContentSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.create,
                  color: AdminTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manual Content Creation',
                        style: AdminTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AdminTheme.primaryColor,
                        ),
                      ),
                      Text(
                        'Create custom health tips and facts for sports - perfect for unique content!',
                        style: AdminTheme.bodyMedium.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Content Type and Sport Selection
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _manualContentType,
                    decoration: const InputDecoration(
                      labelText: 'Content Type',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'single_parent_tip',
                        child: Text('Health Tip'),
                      ),
                      DropdownMenuItem(
                        value: 'sport_facts',
                        child: Text('Did You Know'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _manualContentType = value!;
                        _clearManualForm(); // Clear form when switching types
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _manualSport.isEmpty ? null : _manualSport,
                    decoration: const InputDecoration(
                      labelText: 'Sport',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    hint: const Text('Select sport'),
                    items: _availableSports.map((sport) {
                      return DropdownMenuItem(
                        value: sport,
                        child: Text(sport),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _manualSport = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Dynamic form based on content type
            if (_manualContentType == 'single_parent_tip') 
              _buildParentTipForm()
            else 
              _buildDidYouKnowForm(),
              
            const SizedBox(height: 20),
            
            // Submit Button
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isManualSubmitting || _manualSport.isEmpty 
                      ? null 
                      : _submitManualContent,
                  icon: _isManualSubmitting 
                      ? const SizedBox(
                          width: 16, 
                          height: 16, 
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(_isManualSubmitting 
                      ? 'Creating...' 
                      : 'Create ${_manualContentType == "single_parent_tip" ? "Health Tip" : "Did You Know"}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _clearManualForm,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Form'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentTipForm() {
    return Column(
      children: [
        // Title
        TextFormField(
          controller: _manualTitleController,
          decoration: const InputDecoration(
            labelText: 'Title *',
            hintText: 'e.g., "Building Confidence Through Team Sports"',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          maxLines: 1,
        ),
        const SizedBox(height: 12),
        
        // Content
        TextFormField(
          controller: _manualContentController,
          decoration: const InputDecoration(
            labelText: 'Content *',
            hintText: 'Write the main health tip content here...',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        
        // Benefits
        TextFormField(
          controller: _manualBenefitsController,
          decoration: const InputDecoration(
            labelText: 'Benefits (Optional)',
            hintText: 'List benefits, one per line:\nImproves teamwork\nBuilds social skills\nEnhances physical fitness',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        
        // Age Group
        TextFormField(
          controller: _manualAgeGroupController,
          decoration: const InputDecoration(
            labelText: 'Age Group (Optional)',
            hintText: 'e.g., "8-16" or "All ages"',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDidYouKnowForm() {
    return Column(
      children: [
        // Fact
        TextFormField(
          controller: _manualTitleController,
          decoration: const InputDecoration(
            labelText: 'Fact Statement *',
            hintText: 'e.g., "The fastest recorded tennis serve was 263.4 km/h"',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        
        // Details
        TextFormField(
          controller: _manualDetailsController,
          decoration: const InputDecoration(
            labelText: 'Detailed Explanation *',
            hintText: 'Provide more details and context about this fact...',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        
        // Category
        TextFormField(
          controller: _manualCategoryController,
          decoration: const InputDecoration(
            labelText: 'Category (Optional)',
            hintText: 'e.g., "Records", "History", "Equipment"',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickGenerationCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Make cards more compact - 4 in a row on desktop, 2 on mobile
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        final aspectRatio = constraints.maxWidth > 800 ? 1.2 : 0.9; // More compact
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: aspectRatio,
      children: [
        _buildQuickGenerationCard(
          icon: Icons.quiz,
          title: 'Quick Trivia',
          description: '1 trivia question\nMixed difficulty',
          onTap: () => _quickGenerate('bulk_trivia', 1),
        ),
        _buildQuickGenerationCard(
          icon: Icons.medical_services,
          title: 'Health Tips',
          description: '1 health tip\nSports-related',
          onTap: () => _quickGenerate('single_parent_tip', 1),
        ),
        _buildQuickGenerationCard(
          icon: Icons.lightbulb,
          title: 'Did You Know',
          description: '1 fascinating fact\nLesser-known trivia',
          onTap: () => _quickGenerate('sport_facts', 1),
        ),
        _buildQuickGenerationCard(
          icon: Icons.auto_awesome,
          title: 'Mixed Content',
          description: '1 random item\nSurprise content',
          onTap: () => _quickGenerate('mixed_content', 1),
        ),
      ],
    );
      },
    );
  }

  Widget _buildQuickGenerationCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _selectedSport.isEmpty ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: _selectedSport.isEmpty ? Colors.grey : AdminTheme.primaryColor,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: AdminTheme.titleMedium.copyWith(
                  color: _selectedSport.isEmpty ? Colors.grey : null,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  description,
                  style: AdminTheme.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _quickGenerate(String contentType, int quantity) async {
    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);

    try {
      await _contentService.requestContentGeneration(
        requestType: GenerationRequestType.fromString(contentType),
        sportCategory: _selectedSport,
        quantity: quantity,
        requestedBy: authProvider.currentAdmin ?? 'unknown',
        adminEmail: authProvider.email,
        difficultyLevel: DifficultyLevel.medium,
        sourceType: 'mixed',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$quantity ${contentType.replaceAll('_', ' ')} ${quantity == 1 ? 'item' : 'items'} being generated!'),
          backgroundColor: AdminTheme.successColor,
        ),
      );

      _loadInitialData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generation failed: $e'),
          backgroundColor: AdminTheme.errorColor,
        ),
      );
    }
  }

  Widget _buildCustomGenerationForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custom Content Generation',
              style: AdminTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Content Type
            DropdownButtonFormField<String>(
              initialValue: _selectedContentType,
              decoration: const InputDecoration(
                labelText: 'Content Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'bulk_trivia', child: Text('🧠 Bulk Trivia Questions')),
                DropdownMenuItem(value: 'single_parent_tip', child: Text('🏥 Health Tips')),
                DropdownMenuItem(value: 'sport_facts', child: Text('💡 Did You Know Facts')),
                DropdownMenuItem(value: 'mixed_content', child: Text('🎯 Mixed Content Pack')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedContentType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Sport Selection
            DropdownButtonFormField<String>(
              initialValue: _selectedSport.isEmpty ? null : _selectedSport,
              decoration: const InputDecoration(
                labelText: 'Sport Category',
                border: OutlineInputBorder(),
              ),
              items: _availableSports.map((sport) {
                return DropdownMenuItem(
                  value: sport,
                  child: Text(sport),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSport = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Quantity and Difficulty - responsive layout
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 350;
                
                if (isNarrow) {
                  return Column(
                    children: [
                      TextFormField(
                        initialValue: _quantity.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                          helperText: 'Number of items',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _quantity = int.tryParse(value) ?? 1;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDifficulty,
                        decoration: const InputDecoration(
                          labelText: 'Difficulty',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'easy', child: Text('Easy')),
                          DropdownMenuItem(value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'hard', child: Text('Hard')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedDifficulty = value!;
                          });
                        },
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _quantity.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(),
                            helperText: 'Number of items',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _quantity = int.tryParse(value) ?? 5;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedDifficulty,
                          decoration: const InputDecoration(
                            labelText: 'Difficulty',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'easy', child: Text('Easy')),
                            DropdownMenuItem(value: 'medium', child: Text('Medium')),
                            DropdownMenuItem(value: 'hard', child: Text('Hard')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedDifficulty = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Age Group and Source Type - responsive layout
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 400;
                
                if (isNarrow) {
                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedAgeGroup,
                        decoration: const InputDecoration(
                          labelText: 'Target Age Group',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: '6-10', child: Text('6-10 years')),
                          DropdownMenuItem(value: '8-16', child: Text('8-16 years')),
                          DropdownMenuItem(value: '12-18', child: Text('12-18 years')),
                          DropdownMenuItem(value: 'all', child: Text('All ages')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedAgeGroup = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSourceType,
                        decoration: const InputDecoration(
                          labelText: 'Content Source',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'sports_wiki', child: Text('Sports Wiki Only')),
                          DropdownMenuItem(value: 'online_research', child: Text('Online Research')),
                          DropdownMenuItem(value: 'mixed', child: Text('Mixed Sources')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSourceType = value!;
                          });
                        },
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedAgeGroup,
                          decoration: const InputDecoration(
                            labelText: 'Target Age Group',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: '6-10', child: Text('6-10 years')),
                            DropdownMenuItem(value: '8-16', child: Text('8-16 years')),
                            DropdownMenuItem(value: '12-18', child: Text('12-18 years')),
                            DropdownMenuItem(value: 'all', child: Text('All ages')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedAgeGroup = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedSourceType,
                          decoration: const InputDecoration(
                            labelText: 'Content Source',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'sports_wiki', child: Text('Sports Wiki Only')),
                            DropdownMenuItem(value: 'online_research', child: Text('Online Research')),
                            DropdownMenuItem(value: 'mixed', child: Text('Mixed Sources')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedSourceType = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            
            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedSport.isEmpty ? null : () => _generateContent(context),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate Content'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRequestsSection() {
    if (_activeRequests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pending_actions, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Active Generation Requests',
                    style: AdminTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                // Cleanup button for stuck requests
                if (_activeRequests.any((r) => r.status == GenerationStatus.pending || r.status == GenerationStatus.processing))
                  OutlinedButton.icon(
                    onPressed: _cleanupStuckRequests,
                    icon: const Icon(Icons.cleaning_services, size: 16),
                    label: const Text('Cleanup Stuck', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminTheme.errorColor,
                      side: BorderSide(color: AdminTheme.errorColor),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...(_activeRequests.map((request) => _buildRequestCard(request, isActive: true))),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRequestsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Recent Requests',
                  style: AdminTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_recentRequests.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'No recent requests',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...(_recentRequests.map((request) => _buildRequestCard(request, isActive: false))),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(ContentGenerationRequest request, {required bool isActive}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: isActive ? Colors.blue[50] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                request.status == GenerationStatus.completed 
                    ? Icons.check_circle 
                    : request.status == GenerationStatus.failed
                        ? Icons.error
                        : Icons.hourglass_empty,
                size: 16,
                color: request.status == GenerationStatus.completed 
                    ? Colors.green 
                    : request.status == GenerationStatus.failed
                        ? Colors.red
                        : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${request.requestType.displayName} - ${request.sportCategory}',
                  style: AdminTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                DateFormat('MMM dd, HH:mm').format(request.createdAt),
                style: AdminTheme.bodySmall.copyWith(color: Colors.grey[600]),
              ),
              
              // Action buttons for stuck requests
              if (request.status == GenerationStatus.pending || request.status == GenerationStatus.processing) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _cancelRequest(request.id),
                  icon: const Icon(Icons.cancel, size: 18),
                  color: Colors.red,
                  tooltip: 'Cancel Request',
                  visualDensity: VisualDensity.compact,
                ),
              ],
              
              // Delete button for failed requests
              if (request.status == GenerationStatus.failed) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _deleteRequest(request.id),
                  icon: const Icon(Icons.delete, size: 18),
                  color: Colors.red,
                  tooltip: 'Delete Request',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          
          if (isActive && request.status == GenerationStatus.processing) ...[
            LinearProgressIndicator(
              value: request.progressPercentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AdminTheme.primaryColor),
            ),
            const SizedBox(height: 4),
          ],
          
          Text(
            request.progressText,
            style: AdminTheme.bodySmall.copyWith(color: Colors.grey[700]),
          ),
          
          if (request.status == GenerationStatus.completed) ...[
            const SizedBox(height: 4),
            Text(
              'Generated ${request.generatedContentIds.length} items • Duration: ${request.duration.inSeconds}s',
              style: AdminTheme.bodySmall.copyWith(color: Colors.green[700]),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if user has super admin privileges
    final authProvider = Provider.of<AdminAuthProvider>(context);
    if (!authProvider.isSuperAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: AdminTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This feature is only available to super administrators.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Check if we need mobile AppBar (when accessed via navigation)
    final screenWidth = MediaQuery.of(context).size.width;
    final needsAppBar = screenWidth < 600;

    return Scaffold(
      backgroundColor: AdminTheme.backgroundColor,
      appBar: needsAppBar ? AppBar(
        title: const Text('AI Content Generation'),
        backgroundColor: AdminTheme.primaryColor,
        foregroundColor: Colors.white,
      ) : null,
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading content generation tools...'),
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
                        'Error loading generation tools',
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
                        onPressed: _loadInitialData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 28,
                            color: AdminTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Content Generation',
                                  style: AdminTheme.titleLarge,
                                ),
                                Text(
                                  'Generate trivia, parent tips, and did-you-know content using AI',
                                  style: AdminTheme.bodyMedium.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Manual Content Creation Section
                      _buildManualContentSection(),
                      const SizedBox(height: 32),
                      
                      // Quick Generation Cards
                      if (_availableSports.isNotEmpty) ...[
                        Text(
                          'Quick AI Generation',
                          style: AdminTheme.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'One-click AI content generation for when you need content fast',
                          style: AdminTheme.bodyMedium.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        
                        // Sport selector for quick generation
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.sports, color: AdminTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text('Selected Sport:', style: AdminTheme.bodyMedium),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButton<String>(
                                  value: _selectedSport.isEmpty ? null : _selectedSport,
                                  hint: const Text('Select a sport'),
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: _availableSports.map((sport) {
                                    return DropdownMenuItem(
                                      value: sport,
                                      child: Text(sport),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedSport = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildQuickGenerationCards(),
                        const SizedBox(height: 32),
                      ],
                      
                      // Custom Generation Form
                      _buildCustomGenerationForm(),
                      const SizedBox(height: 32),
                      
                      // Active Requests
                      _buildActiveRequestsSection(),
                      if (_activeRequests.isNotEmpty) const SizedBox(height: 16),
                      
                      // Recent Requests
                      _buildRecentRequestsSection(),
                    ],
                  ),
                ),
    );
  }
}

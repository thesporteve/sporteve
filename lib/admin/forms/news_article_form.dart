import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/news_article.dart';
import '../services/admin_data_service.dart';
// Removed admin_notification_service import - notifications now automatic via Cloud Functions
import '../providers/admin_auth_provider.dart';
import '../theme/admin_theme.dart';

class NewsArticleForm extends StatefulWidget {
  final NewsArticle? article;
  final VoidCallback? onSaved;

  const NewsArticleForm({
    super.key,
    this.article,
    this.onSaved,
  });

  @override
  State<NewsArticleForm> createState() => _NewsArticleFormState();
}

class _NewsArticleFormState extends State<NewsArticleForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();
  final _authorController = TextEditingController();
  final _sourceController = TextEditingController();
  final _sourceUrlController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _readTimeController = TextEditingController();

  String _selectedCategory = 'football';
  bool _isBreaking = false;
  bool _isLoading = false;
  String? _selectedTournamentId;
  String? _selectedAthleteId;

  Map<String, String> _tournaments = {};
  Map<String, String> _athletes = {};
  List<Map<String, dynamic>> _availableAuthors = [];

  final List<String> _categories = [
    'archery',
    'athletics',
    'badminton',
    'basketball',
    'boxing',
    'chess',
    'cricket',
    'discus_throw',
    'diving',
    'football',
    'golf',
    'hammer_throw',
    'handball',
    'high_jump',
    'hockey',
    'javelin_throw',
    'judo',
    'kabaddi',
    'karate',
    'kayaking',
    'kho_kho',
    'long_jump',
    'marathon',
    'pole_vault',
    'race_walking',
    'relay',
    'rowing',
    'rugby',
    'running',
    'sailing',
    'shooting',
    'shot_put',
    'skating',
    'skiing',
    'soccer',
    'soft_tennis',
    'sprint',
    'sepak_takraw',
    'swimming',
    'taekwondo',
    'tennis',
    'triple_jump',
    'volleyball',
    'weightlifting',
    'wrestling',
  ];

  // Helper method to convert category code to display name
  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'discus_throw':
        return 'Discus Throw';
      case 'hammer_throw':
        return 'Hammer Throw';
      case 'high_jump':
        return 'High Jump';
      case 'javelin_throw':
        return 'Javelin Throw';
      case 'long_jump':
        return 'Long Jump';
      case 'pole_vault':
        return 'Pole Vault';
      case 'race_walking':
        return 'Race Walking';
      case 'shot_put':
        return 'Shot Put';
      case 'triple_jump':
        return 'Triple Jump';
      case 'soft_tennis':
        return 'Soft Tennis';
      case 'sepak_takraw':
        return 'Sepak Takraw';
      case 'kho_kho':
        return 'Kho-Kho';
      default:
        // Convert other underscore categories to proper case
        return category.split('_')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadOptions();
    
    if (widget.article != null) {
      _populateFields(widget.article!);
    }
  }

  Future<void> _loadOptions() async {
    try {
      final dataService = AdminDataService.instance;
      final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
      
      final tournaments = await dataService.getTournamentOptions();
      final athletes = await dataService.getAthleteOptions();
      final authors = await authProvider.getActiveAdmins();
      
      if (mounted) {
        setState(() {
          _tournaments = tournaments;
          _athletes = athletes;
          _availableAuthors = authors;
        });
      }
    } catch (e) {
      print('Error loading options: $e');
    }
  }

  void _populateFields(NewsArticle article) {
    _titleController.text = article.title;
    _summaryController.text = article.summary;
    _contentController.text = article.content;
    _authorController.text = article.author;
    _sourceController.text = article.source;
    _sourceUrlController.text = article.sourceUrl ?? '';
    _imageUrlController.text = article.imageUrl ?? '';
    _readTimeController.text = article.readTime?.toString() ?? '';
    
    setState(() {
      _selectedCategory = article.category;
      // Breaking news feature disabled
      _isBreaking = false;
      _selectedTournamentId = article.tournamentId;
      _selectedAthleteId = article.athleteId;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _authorController.dispose();
    _sourceController.dispose();
    _sourceUrlController.dispose();
    _imageUrlController.dispose();
    _readTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveArticle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final article = NewsArticle(
        id: widget.article?.id ?? '',
        title: _titleController.text.trim(),
        summary: _summaryController.text.trim(),
        content: _summaryController.text.trim(), // Using description for both summary and content for first iteration
        author: _authorController.text.trim(),
        publishedAt: widget.article?.publishedAt ?? DateTime.now(),
        category: _selectedCategory,
        source: _sourceController.text.trim(),
        sourceUrl: _sourceUrlController.text.trim().isEmpty ? null : _sourceUrlController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        readTime: _readTimeController.text.trim().isEmpty ? null : int.tryParse(_readTimeController.text.trim()),
        isBreaking: _isBreaking,
        views: widget.article?.views ?? 0,
        relatedArticles: widget.article?.relatedArticles ?? [],
        tournamentId: _selectedTournamentId,
        athleteId: _selectedAthleteId,
      );

      final dataService = AdminDataService.instance;
      
      if (widget.article != null) {
        // Update existing article
        await dataService.updateNewsArticle(widget.article!.id, article);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Article updated successfully'),
              backgroundColor: AdminTheme.successColor,
            ),
          );
        }
      } else {
        // Add new article to staging
        await dataService.addNewsArticle(article, toStaging: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Article added to staging successfully'),
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
            content: Text('Failed to save article: ${e.toString()}'),
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

  // Test notification method removed - notifications now work automatically via article creation

  // Helper method to get a valid author value for the dropdown
  String? _getValidAuthorValue() {
    if (_authorController.text.isEmpty || _availableAuthors.isEmpty) {
      return null;
    }
    
    final currentAuthor = _authorController.text;
    
    // First, try to find exact match with display name
    final exactMatch = _availableAuthors.firstWhere(
      (admin) => admin['displayName'] == currentAuthor,
      orElse: () => {},
    );
    
    if (exactMatch.isNotEmpty) {
      return exactMatch['displayName'];
    }
    
    // Second, try to find match by partial name (e.g., "Karteek" matches "Karteek Joshi")
    final partialMatch = _availableAuthors.firstWhere(
      (admin) => (admin['displayName'] as String).toLowerCase().contains(currentAuthor.toLowerCase()) ||
                 (admin['username'] as String).toLowerCase() == currentAuthor.toLowerCase(),
      orElse: () => {},
    );
    
    if (partialMatch.isNotEmpty) {
      // Update the controller to use the full display name
      _authorController.text = partialMatch['displayName'];
      return partialMatch['displayName'];
    }
    
    // If no match found, return null to show placeholder
    // This handles legacy data gracefully
    return null;
  }
  
  // Get dropdown items including legacy author if not in current admin list
  List<DropdownMenuItem<String>> _getAuthorDropdownItems() {
    final items = _availableAuthors.map((author) {
      return DropdownMenuItem<String>(
        value: author['displayName'],
        child: Text('${author['displayName']} (${author['username']})'),
      );
    }).toList();
    
    // If current author doesn't match any admin, add it as a legacy option
    if (_authorController.text.isNotEmpty) {
      final currentAuthor = _authorController.text;
      final hasMatch = _availableAuthors.any((admin) => 
        admin['displayName'] == currentAuthor ||
        (admin['displayName'] as String).toLowerCase().contains(currentAuthor.toLowerCase()) ||
        (admin['username'] as String).toLowerCase() == currentAuthor.toLowerCase()
      );
      
      if (!hasMatch) {
        items.insert(0, DropdownMenuItem<String>(
          value: currentAuthor,
          child: Text('$currentAuthor (Legacy Author)'),
        ));
      }
    }
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article != null ? 'Edit Article' : 'Add Article'),
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
              onPressed: _saveArticle,
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
              // Title
              TextFormField(
                controller: _titleController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Article Title',
                  hintText: 'Enter a compelling title',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  if (value.trim().length < 10) {
                    return 'Title must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description (Shows on cards)
              TextFormField(
                controller: _summaryController,
                decoration: const InputDecoration(
                  labelText: 'Description (Shows on news cards)',
                  hintText: 'Brief description shown on article cards (min 100 chars)',
                ),
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  if (value.trim().length < 100) {
                    return 'Description must be at least 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Summary field hidden for first iteration - using Description only
              // TextFormField(
              //   controller: _contentController,
              //   decoration: const InputDecoration(
              //     labelText: 'Summary (Shows only on detail page)',
              //     hintText: 'Complete article content for detail page (min 50 chars)',
              //     alignLabelWithHint: true,
              //   ),
              //   maxLines: 5,
              //   validator: (value) {
              //     if (value == null || value.trim().isEmpty) {
              //       return 'Summary is required';
              //     }
              //     if (value.trim().length < 50) {
              //       return 'Summary must be at least 50 characters';
              //     }
              //     return null;
              //   },
              // ),
              // const SizedBox(height: 16),

              // Author and Category Row
              Row(
                children: [
                  Expanded(
                    child: _availableAuthors.isNotEmpty 
                        ? DropdownButtonFormField<String>(
                            value: _getValidAuthorValue() ?? (_authorController.text.isNotEmpty ? _authorController.text : null),
                            decoration: const InputDecoration(
                              labelText: 'Author *',
                              hintText: 'Select author',
                            ),
                            items: _getAuthorDropdownItems(),
                            onChanged: (value) {
                              setState(() {
                                _authorController.text = value ?? '';
                              });
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Author is required';
                              }
                              return null;
                            },
                          )
                        : TextFormField(
                            controller: _authorController,
                            decoration: const InputDecoration(
                              labelText: 'Author *',
                              hintText: 'Enter author name',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Author is required';
                              }
                              return null;
                            },
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(_getCategoryDisplayName(category)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Source and Source URL
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sourceController,
                      decoration: const InputDecoration(
                        labelText: 'Source',
                        hintText: 'News source (e.g., ESPN, CNN Sports)',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Source is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _sourceUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Source URL *',
                        hintText: 'https://twitter.com/user/status/123... or https://example.com/article',
                        helperText: 'Required - Link to the original source',
                      ),
                      validator: (value) {
                        // Source URL is now mandatory
                        if (value == null || value.trim().isEmpty) {
                          return 'Source URL is required';
                        }
                        if (Uri.tryParse(value.trim())?.hasAbsolutePath != true) {
                          return 'Please enter a valid URL';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Image URL and Read Time
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL (Optional)',
                        hintText: 'https://example.com/image.jpg',
                      ),
                      validator: (value) {
                        // Only validate if URL is provided
                        if (value != null && value.trim().isNotEmpty) {
                          if (Uri.tryParse(value.trim())?.hasAbsolutePath != true) {
                            return 'Please enter a valid URL';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _readTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Read Time (minutes)',
                        hintText: '5',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (int.tryParse(value.trim()) == null || int.parse(value.trim()) < 1) {
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

              // Tournament and Athlete dropdowns
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _selectedTournamentId,
                      decoration: const InputDecoration(
                        labelText: 'Tournament (Optional)',
                        hintText: 'Select a tournament',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('None'),
                        ),
                        ..._tournaments.entries.map((entry) {
                          return DropdownMenuItem<String?>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedTournamentId = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _selectedAthleteId,
                      decoration: const InputDecoration(
                        labelText: 'Athlete (Optional)',
                        hintText: 'Select an athlete',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('None'),
                        ),
                        ..._athletes.entries.map((entry) {
                          return DropdownMenuItem<String?>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedAthleteId = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notification Options card removed - notifications now work automatically via Cloud Functions
              
              const SizedBox(height: 24),

              // Save button (mobile)
              if (MediaQuery.of(context).size.width <= 600)
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveArticle,
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
                      : Text(widget.article != null ? 'Update Article' : 'Add to Staging'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

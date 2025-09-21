import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../models/news_article.dart';
import '../services/admin_data_service.dart';
import '../providers/admin_auth_provider.dart';
import '../theme/admin_theme.dart';

class NewsArticleImageForm extends StatefulWidget {
  final NewsArticle? article;
  final VoidCallback? onSaved;

  const NewsArticleImageForm({
    super.key,
    this.article,
    this.onSaved,
  });

  @override
  State<NewsArticleImageForm> createState() => _NewsArticleImageFormState();
}

class _NewsArticleImageFormState extends State<NewsArticleImageForm> {
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
  
  // Image upload related
  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _isUploadingImage = false;
  String? _uploadedImageUrl;

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
    'sepak_takraw',
    'shooting',
    'shot_put',
    'skating',
    'skiing',
    'soccer',
    'soft_tennis',
    'sprint',
    'swimming',
    'taekwondo',
    'tennis',
    'triple_jump',
    'volleyball',
    'weightlifting',
    'wrestling',
  ];

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
      _isBreaking = false;
      _selectedTournamentId = article.tournamentId;
      _selectedAthleteId = article.athleteId;
      _uploadedImageUrl = article.imageUrl;
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

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Check file size (limit to 5MB)
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size must be less than 5MB'),
                backgroundColor: AdminTheme.errorColor,
              ),
            );
          }
          return;
        }

        setState(() {
          _imageBytes = file.bytes;
          _imageFileName = file.name;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageBytes == null || _imageFileName == null) return null;

    try {
      setState(() => _isUploadingImage = true);

      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _imageFileName!.split('.').last;
      final fileName = 'news_images/${timestamp}_$_imageFileName';

      // Upload to Firebase Storage
      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putData(
        _imageBytes!,
        SettableMetadata(
          contentType: 'image/$extension',
          customMetadata: {
            'uploadedBy': Provider.of<AdminAuthProvider>(context, listen: false).currentAdmin ?? 'unknown',
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _uploadedImageUrl = downloadUrl;
        _imageUrlController.text = downloadUrl;
        _isUploadingImage = false;
      });

      return downloadUrl;
    } catch (e) {
      setState(() => _isUploadingImage = false);
      print('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _saveArticle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload image first if selected
      if (_imageBytes != null && _uploadedImageUrl == null) {
        final imageUrl = await _uploadImage();
        if (imageUrl == null) {
          setState(() => _isLoading = false);
          return; // Upload failed
        }
      }

      final article = NewsArticle(
        id: widget.article?.id ?? '',
        title: _titleController.text.trim(),
        summary: _summaryController.text.trim(),
        content: _contentController.text.trim(),
        author: _authorController.text.trim(),
        publishedAt: widget.article?.publishedAt ?? DateTime.now(),
        category: _selectedCategory,
        source: _sourceController.text.trim(),
        sourceUrl: _sourceUrlController.text.trim().isEmpty ? null : _sourceUrlController.text.trim(),
        imageUrl: _uploadedImageUrl ?? (_imageUrlController.text.trim().isNotEmpty ? _imageUrlController.text.trim() : null),
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
              content: Text('Article with image added to staging successfully'),
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
            content: Text('Error saving article: $e'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article != null ? 'Edit Article with Image' : 'Add Article with Image'),
        actions: [
          if (_isLoading || _isUploadingImage)
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
              // Image Upload Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.add_photo_alternate, color: AdminTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Article Image',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Image preview or upload area
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _buildImagePreview(),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Upload button
                      ElevatedButton.icon(
                        onPressed: _isUploadingImage ? null : _pickImage,
                        icon: _isUploadingImage 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file),
                        label: Text(_isUploadingImage ? 'Uploading...' : 'Choose Image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      Text(
                        'Supported: JPG, PNG, GIF (Max 5MB)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // All the existing form fields from the regular form
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
                    return 'Description must be at least 100 characters for better cards';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Full Content
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Full Article Content',
                  hintText: 'Complete article content (min 200 chars)',
                  alignLabelWithHint: true,
                ),
                maxLines: 20,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Content is required';
                  }
                  if (value.trim().length < 200) {
                    return 'Content must be at least 200 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Author and Category Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _authorController.text.isEmpty ? null : _authorController.text,
                      decoration: const InputDecoration(
                        labelText: 'Author',
                        hintText: 'Select author',
                      ),
                      items: [
                        for (final author in _availableAuthors)
                          DropdownMenuItem<String>(
                            value: author['displayName'],
                            child: Text('${author['displayName']} (${author['username']})'),
                          ),
                      ],
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
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Sport Category',
                        hintText: 'Select sport',
                      ),
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category
                              .split('_')
                              .map((word) => word[0].toUpperCase() + word.substring(1))
                              .join(' ')),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Source and Source URL Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sourceController,
                      decoration: const InputDecoration(
                        labelText: 'Source',
                        hintText: 'e.g., ESPN, Twitter, Official Website',
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

              // Tournament and Athlete Row (Optional)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedTournamentId,
                      decoration: const InputDecoration(
                        labelText: 'Tournament (Optional)',
                        hintText: 'Select tournament if applicable',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No tournament'),
                        ),
                        for (final entry in _tournaments.entries)
                          DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
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
                    child: DropdownButtonFormField<String>(
                      value: _selectedAthleteId,
                      decoration: const InputDecoration(
                        labelText: 'Athlete (Optional)',
                        hintText: 'Select athlete if applicable',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No athlete'),
                        ),
                        for (final entry in _athletes.entries)
                          DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
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

              // Read Time
              TextFormField(
                controller: _readTimeController,
                decoration: const InputDecoration(
                  labelText: 'Read Time (minutes)',
                  hintText: 'e.g., 3',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final readTime = int.tryParse(value.trim());
                    if (readTime == null || readTime <= 0) {
                      return 'Read time must be a positive number';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageBytes != null) {
      // Show selected image
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _imageBytes!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _imageBytes = null;
                    _imageFileName = null;
                    _uploadedImageUrl = null;
                    _imageUrlController.text = '';
                  });
                },
              ),
            ),
          ),
        ],
      );
    } else if (_uploadedImageUrl != null) {
      // Show uploaded image
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _uploadedImageUrl!,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 48, color: Colors.grey),
                  Text('Failed to load image'),
                ],
              ),
            );
          },
        ),
      );
    } else {
      // Show upload placeholder
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Click "Choose Image" to upload',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_article.dart';
import '../models/tournament.dart';
import '../models/athlete.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../services/tournament_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();
  final _authorController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _sourceController = TextEditingController();
  final _sourceUrlController = TextEditingController();
  
  String _selectedCategory = 'football';
  String? _selectedTournamentId;
  String? _selectedAthleteId;
  bool _isSubmitting = false;
  List<Tournament> _tournaments = [];
  List<Athlete> _athletes = [];
  bool _isLoadingTournaments = false;
  bool _isLoadingAthletes = false;

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
    'high_jump',
    'hockey',
    'javelin_throw',
    'judo',
    'kabaddi',
    'karate',
    'kayaking',
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
    _loadTournamentsAndAthletes();
  }

  Future<void> _loadTournamentsAndAthletes() async {
    setState(() {
      _isLoadingTournaments = true;
      _isLoadingAthletes = true;
    });

    try {
      print('Starting to load tournaments and athletes...');
      
      final tournaments = await TournamentService.instance.getAllTournaments();
      print('Loaded ${tournaments.length} tournaments');
      
      for (var tournament in tournaments) {
        print('Tournament: ${tournament.name} - Status: ${tournament.status.value}');
      }
      
      final athletes = await TournamentService.instance.getAllAthletes();
      print('Loaded ${athletes.length} athletes');
      
      for (var athlete in athletes) {
        print('Athlete: ${athlete.name} - Sport: ${athlete.sport}');
      }
      
      if (mounted) {
        setState(() {
          _tournaments = tournaments;
          _athletes = athletes;
          _isLoadingTournaments = false;
          _isLoadingAthletes = false;
        });
      }
    } catch (e) {
      print('Error loading tournaments/athletes: $e');
      print('Error details: ${e.runtimeType}');
      if (mounted) {
        setState(() {
          _isLoadingTournaments = false;
          _isLoadingAthletes = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _authorController.dispose();
    _imageUrlController.dispose();
    _sourceController.dispose();
    _sourceUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitArticle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get current user ID if authenticated (optional for testing)
      final currentUser = AuthService().currentFirebaseUser;
      final userId = currentUser?.uid ?? 'anonymous_${DateTime.now().millisecondsSinceEpoch}';

      // Create the news article for staging
      final article = <String, dynamic>{
        'title': _titleController.text.trim(),
        'summary': _summaryController.text.trim(), // Summary shows on news cards
        'content': _contentController.text.trim(),
        'author': _authorController.text.trim(),
        'category': _selectedCategory,
        'source': _sourceController.text.trim(),
        'sourceUrl': _sourceUrlController.text.trim(),
        'news_url': '', // Add empty news_url field for consistency
        'submitted_at': Timestamp.now(),
        'submitted_by': userId, // Use authenticated user ID or anonymous ID for testing
        'is_authenticated': currentUser != null, // Track if submission was authenticated
        'views': 0,
        'relatedArticles': <String>[],
        'tournamentId': _selectedTournamentId,
        'athleteId': _selectedAthleteId,
      };

      // Only add image_url if it's provided
      final imageUrl = _imageUrlController.text.trim();
      if (imageUrl.isNotEmpty) {
        article['image_url'] = imageUrl;
      }

      // Save to staging collection for curation
      final firestore = FirebaseService.instance.firestore;
      await firestore.collection('news_staging').add(article);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentUser != null 
                ? 'Article submitted for curation! It will be published after AI review.'
                : 'Article submitted for testing (unauthenticated). It will be published after AI review.'
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: Duration(seconds: 3),
          ),
        );

        // Clear form
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting article: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _summaryController.clear();
    _contentController.clear();
    _authorController.clear();
    _imageUrlController.clear();
    _sourceController.clear();
    _sourceUrlController.clear();
    _formKey.currentState?.reset(); // Reset form validation state
    setState(() {
      _selectedCategory = 'football';
      _selectedTournamentId = null;
      _selectedAthleteId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(),
            
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Article',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onBackground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Title
                      _buildTextField(
                        controller: _titleController,
                        label: 'Article Title',
                        hint: 'Enter a compelling title',
                        maxLines: 2,
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
                      _buildTextField(
                        controller: _summaryController,
                        label: 'Description (Shows on news cards)',
                        hint: 'Brief description shown on article cards (min 100 chars)',
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
                      
                      // Summary (Full article content - detail page only)
                      _buildTextField(
                        controller: _contentController,
                        label: 'Summary (Shows only on detail page)',
                        hint: 'Complete article content for detail page (min 50 chars)',
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Summary is required';
                          }
                          if (value.trim().length < 100) {
                            return 'Summary must be at least 50 characters';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Author
                      _buildTextField(
                        controller: _authorController,
                        label: 'Author',
                        hint: 'Article author name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Author is required';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Source
                      _buildTextField(
                        controller: _sourceController,
                        label: 'Source',
                        hint: 'News source (e.g., ESPN, CNN Sports)',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Source is required';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Source URL
                      _buildTextField(
                        controller: _sourceUrlController,
                        label: 'Source URL',
                        hint: 'https://twitter.com/user/status/123... or https://example.com/article',
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            if (Uri.tryParse(value.trim())?.hasAbsolutePath != true) {
                              return 'Please enter a valid URL';
                            }
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Image URL (Optional)
                      _buildTextField(
                        controller: _imageUrlController,
                        label: 'Image URL (Optional)',
                        hint: 'https://example.com/image.jpg',
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
                      
                      const SizedBox(height: 16),
                      
                      // Category Dropdown
                      _buildCategoryDropdown(),
                      
                      const SizedBox(height: 16),
                      
                      // Tournament Dropdown
                      _buildTournamentDropdown(),
                      
                      const SizedBox(height: 16),
                      
                      // Athlete Dropdown
                      _buildAthleteDropdown(),
                      
                      const SizedBox(height: 32),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitArticle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Submit for Review',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Clear Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : _clearForm,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                            side: BorderSide(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Clear Form',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
            onPressed: () => context.go('/home'),
          ),
          Expanded(
            child: Text(
              'Admin Panel',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onBackground),
            onSelected: (value) async {
              switch (value) {
                case 'add_sample_data':
                  await _addSampleData();
                  break;
                case 'clear_access':
                  await _clearAdminAccess(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(
                value: 'add_sample_data',
                child: Row(
                  children: [
                    Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Add Sample Data',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'clear_access',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 12),
                    Text(
                      'Clear Admin Access',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              dropdownColor: Theme.of(context).colorScheme.surface,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurface),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
              items: _categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value.toUpperCase(),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tournament (Optional)',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isLoadingTournaments
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _tournaments.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No tournaments available. Add some tournaments first.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedTournamentId,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurface),
                    hint: Text(
                      'Select a tournament',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedTournamentId = newValue;
                      });
                    },
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'None',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                        ),
                      ),
                      ..._tournaments.map<DropdownMenuItem<String?>>((Tournament tournament) {
                        return DropdownMenuItem<String?>(
                          value: tournament.id,
                          child: Text(
                            tournament.name,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAthleteDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Athlete (Optional)',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isLoadingAthletes
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _athletes.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No athletes available. Add some athletes first.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedAthleteId,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurface),
                    hint: Text(
                      'Select an athlete',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedAthleteId = newValue;
                      });
                    },
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'None',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                        ),
                      ),
                      ..._athletes.map<DropdownMenuItem<String?>>((Athlete athlete) {
                        return DropdownMenuItem<String?>(
                          value: athlete.id,
                          child: Text(
                            '${athlete.name} (${athlete.sport})',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _addSampleData() async {
    try {
      // Add sample tournaments
      await TournamentService.instance.addTournament(Tournament(
        id: '',
        name: 'Asian Games 2024',
        place: 'Hangzhou, China',
        sportType: 'all',
        startDate: '2024-09-23',
        endDate: '2024-10-08',
        status: TournamentStatus.live,
        description: 'The 19th Asian Games featuring multiple sports',
        eventUrl: 'https://www.asiangames.org',
      ));

      await TournamentService.instance.addTournament(Tournament(
        id: '',
        name: 'Cricket World Cup 2023',
        place: 'India',
        sportType: 'cricket',
        startDate: '2023-10-05',
        endDate: '2023-11-19',
        status: TournamentStatus.completed,
        description: 'ICC Cricket World Cup 2023',
        eventUrl: 'https://www.icc-cricket.com',
      ));

      // Add sample athletes
      await TournamentService.instance.addAthlete(Athlete(
        id: '',
        name: 'Neeraj Chopra',
        sport: 'javelin_throw',
        bio: 'Olympic gold medalist and world champion in javelin throw',
      ));

      await TournamentService.instance.addAthlete(Athlete(
        id: '',
        name: 'PV Sindhu',
        sport: 'badminton',
        bio: 'Olympic silver medalist and former world champion in badminton',
      ));

      await TournamentService.instance.addAthlete(Athlete(
        id: '',
        name: 'Virat Kohli',
        sport: 'cricket',
        bio: 'Former captain of Indian cricket team, batting superstar',
      ));

      // Reload data
      await _loadTournamentsAndAthletes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sample data added successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding sample data: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _clearAdminAccess(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_access_granted');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Admin access cleared. You will need to enter the code again next time.'),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Navigate back to home
      context.go('/home');
    }
  }
}

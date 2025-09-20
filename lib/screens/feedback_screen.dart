import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/feedback_service.dart';
import '../providers/settings_provider.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackService = FeedbackService();
  
  // Form controllers
  final _improvementController = TextEditingController();
  final _commentsController = TextEditingController();
  
  // Form values
  int _overallRating = 5;
  int _performanceRating = 5;
  int _contentRating = 5;
  String? _favoriteFeature;
  String? _mostUsedSports;
  String? _discoverySource;
  final Set<String> _desiredFeatures = {};
  
  bool _isSubmitting = false;

  // Options for dropdowns
  final List<String> _featureOptions = [
    'Breaking news alerts',
    'Sports categories',
    'Bookmark articles',
    'Share articles',
    'Search functionality',
    'Dark/Light theme',
    'User-friendly interface',
    'Fast loading',
    'Offline reading',
  ];

  final List<String> _sportsOptions = [
    'Cricket',
    'Football',
    'Basketball',
    'Tennis',
    'Hockey',
    'Swimming',
    'Athletics',
    'Boxing',
    'Wrestling',
    'Badminton',
    'Chess',
    'Mixed - I follow multiple sports',
  ];

  final List<String> _discoveryOptions = [
    'Google Play Store search',
    'Friend recommendation',
    'Social media',
    'Sports website/blog',
    'News article',
    'YouTube/Video platform',
    'Other sports app',
    'Just browsing apps',
  ];

  final List<String> _desiredFeatureOptions = [
    'Live scores',
    'Match schedules',
    'Player statistics',
    'Video highlights',
    'Fantasy sports integration',
    'Social features (comments, likes)',
    'Personalized news feed',
    'Push notification customization',
    'Offline mode',
    'Multiple languages',
    'Podcast integration',
    'Live streaming',
  ];

  @override
  void dispose() {
    _improvementController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Your Feedback'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Introduction
            _buildIntroSection(),
            const SizedBox(height: 24),
            
            // Overall Experience
            _buildOverallRatingSection(),
            const SizedBox(height: 24),
            
            // Favorite Feature
            _buildFavoriteFeatureSection(),
            const SizedBox(height: 24),
            
            // Sports Preferences
            _buildSportsPreferenceSection(),
            const SizedBox(height: 24),
            
            // App Performance
            _buildPerformanceRatingSection(),
            const SizedBox(height: 24),
            
            // Content Quality
            _buildContentRatingSection(),
            const SizedBox(height: 24),
            
            // Discovery Source
            _buildDiscoverySourceSection(),
            const SizedBox(height: 24),
            
            // Desired Features
            _buildDesiredFeaturesSection(),
            const SizedBox(height: 24),
            
            // Improvement Suggestions
            _buildImprovementSection(),
            const SizedBox(height: 24),
            
            // Additional Comments
            _buildAdditionalCommentsSection(),
            const SizedBox(height: 32),
            
            // Submit Button
            _buildSubmitButton(),
            const SizedBox(height: 16),
            
            // Thank you note
            _buildThankYouNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.feedback,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Help us improve SportEve!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your feedback is incredibly valuable to us. It takes just 2 minutes and helps us make SportEve even better for sports enthusiasts like you!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallRatingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⭐ How would you rate SportEve overall?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildStarRating(_overallRating, (rating) {
              setState(() {
                _overallRating = rating;
              });
            }),
            const SizedBox(height: 8),
            Text(
              _getRatingDescription(_overallRating),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteFeatureSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '❤️ What\'s your favorite feature?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _favoriteFeature,
              decoration: const InputDecoration(
                hintText: 'Choose your favorite feature',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              isExpanded: true,
              items: _featureOptions.map((feature) {
                return DropdownMenuItem(
                  value: feature, 
                  child: Text(
                    feature,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _favoriteFeature = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportsPreferenceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏆 Which sports do you follow most on SportEve?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _mostUsedSports,
              decoration: const InputDecoration(
                hintText: 'Select your primary sports interest',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              isExpanded: true,
              items: _sportsOptions.map((sport) {
                return DropdownMenuItem(
                  value: sport, 
                  child: Text(
                    sport,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _mostUsedSports = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceRatingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚡ How would you rate the app\'s performance?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading speed, responsiveness, etc.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            _buildStarRating(_performanceRating, (rating) {
              setState(() {
                _performanceRating = rating;
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildContentRatingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📰 How would you rate our content quality?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'News accuracy, relevance, variety, etc.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            _buildStarRating(_contentRating, (rating) {
              setState(() {
                _contentRating = rating;
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverySourceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔍 How did you discover SportEve?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _discoverySource,
              decoration: const InputDecoration(
                hintText: 'How did you find us?',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              isExpanded: true,
              items: _discoveryOptions.map((source) {
                return DropdownMenuItem(
                  value: source, 
                  child: Text(
                    source,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _discoverySource = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesiredFeaturesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✨ What features would you love to see?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select all that interest you',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _desiredFeatureOptions.map((feature) {
                final isSelected = _desiredFeatures.contains(feature);
                return FilterChip(
                  label: Text(
                    feature,
                    style: const TextStyle(fontSize: 12),
                  ),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _desiredFeatures.add(feature);
                      } else {
                        _desiredFeatures.remove(feature);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💡 What can we improve?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Any bugs, issues, or suggestions for improvement?',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _improvementController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Share your thoughts on how we can make SportEve better...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalCommentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💬 Anything else you\'d like to share?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We love hearing from our users!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _commentsController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any additional thoughts, compliments, or suggestions...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        child: _isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Flexible(child: Text('Submitting...')),
                ],
              )
            : const Text(
                'Submit Feedback',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildThankYouNote() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.favorite,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Thank you for helping us improve SportEve! Your feedback directly shapes our future updates.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(int rating, Function(int) onRatingChanged) {
    return Row(
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () => onRatingChanged(index + 1),
          child: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
        );
      }),
    );
  }

  String _getRatingDescription(int rating) {
    switch (rating) {
      case 1:
        return 'Poor - Needs significant improvement';
      case 2:
        return 'Fair - Some issues to address';
      case 3:
        return 'Good - Meets basic expectations';
      case 4:
        return 'Very Good - Exceeds expectations';
      case 5:
        return 'Excellent - Outstanding experience!';
      default:
        return '';
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await _feedbackService.submitFeedback(
        overallRating: _overallRating,
        favoriteFeature: _favoriteFeature,
        mostUsedSports: _mostUsedSports,
        discoverySource: _discoverySource,
        appPerformanceRating: _performanceRating,
        contentQualityRating: _contentRating,
        desiredFeatures: _desiredFeatures.toList(),
        improvementSuggestions: _improvementController.text.trim().isNotEmpty
            ? _improvementController.text.trim()
            : null,
        additionalComments: _commentsController.text.trim().isNotEmpty
            ? _commentsController.text.trim()
            : null,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Thank you! Your feedback has been submitted successfully.'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to submit feedback. Please try again.'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
}

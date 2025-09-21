import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_feedback.dart';
import '../../services/feedback_service.dart';
import '../theme/admin_theme.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  final FeedbackService _feedbackService = FeedbackService();
  List<UserFeedback> _feedbacks = [];
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final feedbacks = await _feedbackService.getAllFeedback();
      final analytics = await _feedbackService.getFeedbackAnalytics();
      
      setState(() {
        _feedbacks = feedbacks;
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load feedback: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Feedback'),
        backgroundColor: AdminTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeedback,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
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
              _error!,
              style: AdminTheme.bodyLarge.copyWith(
                color: AdminTheme.errorColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFeedback,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_feedbacks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.feedback_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No feedback received yet',
              style: AdminTheme.titleMedium.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'User feedback will appear here',
              style: AdminTheme.bodyMedium.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Analytics Overview
          _buildAnalyticsSection(),
          
          const SizedBox(height: 24),
          
          // Feedback List
          _buildFeedbackList(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    if (_analytics.isEmpty) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Feedback Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AdminTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Statistics Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  'Total Feedback',
                  _analytics['totalFeedback']?.toString() ?? '0',
                  Icons.feedback,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Average Rating',
                  (_analytics['averageOverallRating']?.toStringAsFixed(1) ?? '0.0'),
                  Icons.star,
                  Colors.amber,
                ),
                _buildStatCard(
                  'App Performance',
                  (_analytics['averagePerformanceRating']?.toStringAsFixed(1) ?? '0.0'),
                  Icons.speed,
                  Colors.green,
                ),
                _buildStatCard(
                  'Content Quality',
                  (_analytics['averageContentRating']?.toStringAsFixed(1) ?? '0.0'),
                  Icons.article,
                  Colors.purple,
                ),
              ],
            ),
            
            // Top desired features
            if (_analytics['topDesiredFeatures'] != null) ...[
              const SizedBox(height: 20),
              const Text(
                'Most Requested Features',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_analytics['topDesiredFeatures'] as List)
                    .take(5)
                    .map<Widget>((feature) => Chip(
                      label: Text(
                        feature,
                        overflow: TextOverflow.ellipsis,
                      ),
                      backgroundColor: AdminTheme.primaryColor.withOpacity(0.1),
                      labelStyle: const TextStyle(
                        color: AdminTheme.primaryColor,
                        fontSize: 12,
                      ),
                    ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recent Feedback',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AdminTheme.primaryColor,
              ),
            ),
            const Spacer(),
            Text(
              '${_feedbacks.length} total',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Feedback cards
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _feedbacks.length,
          itemBuilder: (context, index) {
            return _buildFeedbackCard(_feedbacks[index]);
          },
        ),
      ],
    );
  }

  Widget _buildFeedbackCard(UserFeedback feedback) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getRatingColor(feedback.overallRating),
          child: Text(
            feedback.overallRating.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                feedback.userEmail.isNotEmpty ? feedback.userEmail : 'Anonymous User',
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildStarRating(feedback.overallRating),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submitted: ${DateFormat('MMM dd, yyyy at HH:mm').format(feedback.submittedAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'App v${feedback.appVersion} • ${feedback.deviceInfo}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ratings breakdown
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 400) {
                      // Stack vertically on very small screens
                      return Column(
                        children: [
                          _buildRatingRow('Performance', feedback.appPerformanceRating),
                          const SizedBox(height: 8),
                          _buildRatingRow('Content', feedback.contentQualityRating),
                        ],
                      );
                    } else {
                      // Side by side on larger screens
                      return Row(
                        children: [
                          Expanded(
                            child: _buildRatingRow('Performance', feedback.appPerformanceRating),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildRatingRow('Content', feedback.contentQualityRating),
                          ),
                        ],
                      );
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Favorite feature
                if (feedback.favoriteFeature != null && feedback.favoriteFeature!.isNotEmpty) ...[
                  _buildInfoRow('Favorite Feature', feedback.favoriteFeature!),
                  const SizedBox(height: 8),
                ],
                
                // Most used sports
                if (feedback.mostUsedSports != null && feedback.mostUsedSports!.isNotEmpty) ...[
                  _buildInfoRow('Most Used Sports', feedback.mostUsedSports!),
                  const SizedBox(height: 8),
                ],
                
                // Discovery source
                if (feedback.discoverySource != null && feedback.discoverySource!.isNotEmpty) ...[
                  _buildInfoRow('How they found us', feedback.discoverySource!),
                  const SizedBox(height: 8),
                ],
                
                // Desired features
                if (feedback.desiredFeatures.isNotEmpty) ...[
                  const Text(
                    'Desired Features:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: feedback.desiredFeatures.map((feature) => Chip(
                      label: Text(
                        feature,
                        overflow: TextOverflow.ellipsis,
                      ),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      labelStyle: const TextStyle(fontSize: 12),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Improvement suggestions
                if (feedback.improvementSuggestions != null && feedback.improvementSuggestions!.isNotEmpty) ...[
                  _buildInfoRow('Improvement Suggestions', feedback.improvementSuggestions!),
                  const SizedBox(height: 8),
                ],
                
                // Additional comments
                if (feedback.additionalComments != null && feedback.additionalComments!.isNotEmpty) ...[
                  _buildInfoRow('Additional Comments', feedback.additionalComments!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow(String label, int rating) {
    return Row(
      children: [
        Flexible(
          child: Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildStarRating(rating),
        const SizedBox(width: 4),
        Text('($rating/5)'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(value),
      ],
    );
  }

  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.deepOrange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

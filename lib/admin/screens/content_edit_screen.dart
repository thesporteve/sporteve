import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/content_feed.dart';
import '../services/admin_content_service.dart';
import '../providers/admin_auth_provider.dart';
import '../theme/admin_theme.dart';

class ContentEditScreen extends StatefulWidget {
  final ContentFeed content;
  final VoidCallback? onContentUpdated;

  const ContentEditScreen({
    super.key,
    required this.content,
    this.onContentUpdated,
  });

  @override
  State<ContentEditScreen> createState() => _ContentEditScreenState();
}

class _ContentEditScreenState extends State<ContentEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AdminContentService _contentService = AdminContentService.instance;
  
  bool _isLoading = false;

  // Controllers for different content types
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _explanationController = TextEditingController();
  final TextEditingController _factController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  
  // For trivia options
  List<TextEditingController> _optionControllers = [];
  String _correctAnswer = '';
  
  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final content = widget.content;
    
    switch (content.type) {
      case ContentType.trivia:
        final triviaContent = content.triviaContent;
        if (triviaContent != null) {
          _questionController.text = triviaContent.question;
          _explanationController.text = triviaContent.explanation;
          _correctAnswer = triviaContent.correctAnswer;
          
          // Initialize option controllers
          for (int i = 0; i < 4; i++) {
            final controller = TextEditingController();
            if (i < triviaContent.options.length) {
              controller.text = triviaContent.options[i];
            }
            _optionControllers.add(controller);
          }
        }
        break;
        
      case ContentType.parentTip:
        final parentTipContent = content.parentTipContent;
        if (parentTipContent != null) {
          _titleController.text = parentTipContent.title;
          _contentController.text = parentTipContent.content;
        }
        break;
        
      case ContentType.didYouKnow:
        final didYouKnowContent = content.didYouKnowContent;
        if (didYouKnowContent != null) {
          _factController.text = didYouKnowContent.fact;
          _detailsController.text = didYouKnowContent.details;
        }
        break;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _questionController.dispose();
    _explanationController.dispose();
    _factController.dispose();
    _detailsController.dispose();
    _contentController.dispose();
    
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
      Map<String, dynamic> updatedContent = {};

      // Build updated content based on type
      switch (widget.content.type) {
        case ContentType.trivia:
          updatedContent = {
            'question': _questionController.text.trim(),
            'options': _optionControllers.map((c) => c.text.trim()).toList(),
            'correct_answer': _correctAnswer,
            'explanation': _explanationController.text.trim(),
          };
          break;
          
        case ContentType.parentTip:
          final parentTipContent = widget.content.parentTipContent;
          updatedContent = {
            'title': _titleController.text.trim(),
            'content': _contentController.text.trim(),
            'benefits': parentTipContent?.benefits ?? [], // Keep existing benefits
            'age_group': parentTipContent?.ageGroup ?? '6-16',
          };
          break;
          
        case ContentType.didYouKnow:
          final didYouKnowContent = widget.content.didYouKnowContent;
          updatedContent = {
            'fact': _factController.text.trim(),
            'details': _detailsController.text.trim(),
            'category': didYouKnowContent?.category ?? 'general',
          };
          break;
      }

      await _contentService.updateContentFeedContent(
        widget.content.id,
        updatedContent,
        authProvider.currentAdmin ?? 'unknown',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content updated successfully!'),
            backgroundColor: AdminTheme.successColor,
          ),
        );
        
        if (widget.onContentUpdated != null) {
          widget.onContentUpdated!();
        }
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update content: $e'),
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

  Widget _buildTriviaForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question
        TextFormField(
          controller: _questionController,
          decoration: const InputDecoration(
            labelText: 'Question',
            border: OutlineInputBorder(),
            hintText: 'Enter the trivia question',
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Question is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Options
        Text('Answer Options:', style: AdminTheme.titleMedium),
        const SizedBox(height: 8),
        
        for (int i = 0; i < 4; i++) ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _optionControllers[i],
                  decoration: InputDecoration(
                    labelText: 'Option ${String.fromCharCode(65 + i)}',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Option is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Radio<String>(
                value: _optionControllers[i].text,
                groupValue: _correctAnswer,
                onChanged: (value) {
                  setState(() {
                    _correctAnswer = value ?? '';
                  });
                },
              ),
              const Text('Correct'),
            ],
          ),
          const SizedBox(height: 8),
        ],
        
        const SizedBox(height: 16),
        
        // Explanation
        TextFormField(
          controller: _explanationController,
          decoration: const InputDecoration(
            labelText: 'Explanation',
            border: OutlineInputBorder(),
            hintText: 'Explain why this answer is correct',
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Explanation is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildParentTipForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
            hintText: 'Enter the parent tip title',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Title is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Content
        TextFormField(
          controller: _contentController,
          decoration: const InputDecoration(
            labelText: 'Content',
            border: OutlineInputBorder(),
            hintText: 'Enter the detailed parent tip content',
            alignLabelWithHint: true,
          ),
          maxLines: 8,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Content is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDidYouKnowForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fact
        TextFormField(
          controller: _factController,
          decoration: const InputDecoration(
            labelText: 'Fact',
            border: OutlineInputBorder(),
            hintText: 'Enter the interesting fact',
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Fact is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Details
        TextFormField(
          controller: _detailsController,
          decoration: const InputDecoration(
            labelText: 'Details',
            border: OutlineInputBorder(),
            hintText: 'Enter detailed explanation with context',
            alignLabelWithHint: true,
          ),
          maxLines: 6,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Details are required';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.content.type.displayName}'),
        backgroundColor: AdminTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveChanges,
              child: const Text(
                'SAVE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Saving changes...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Content type header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AdminTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AdminTheme.primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            widget.content.type.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.content.type.displayName,
                                  style: AdminTheme.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AdminTheme.primaryColor,
                                  ),
                                ),
                                Text(
                                  widget.content.sportCategory.toUpperCase(),
                                  style: AdminTheme.bodySmall.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Form based on content type
                    if (widget.content.type == ContentType.trivia)
                      _buildTriviaForm()
                    else if (widget.content.type == ContentType.parentTip)
                      _buildParentTipForm()
                    else if (widget.content.type == ContentType.didYouKnow)
                      _buildDidYouKnowForm(),
                    
                    const SizedBox(height: 32),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminTheme.primaryColor,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

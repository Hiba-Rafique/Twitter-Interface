import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/enhanced_post_service.dart';
import '../services/storage_service.dart';

/// Create Post Widget with enhanced UI and functionality
/// Supports both compact (in-feed) and full-screen modes
class CreatePostWidget extends StatefulWidget {
  final String userId;
  final String companyId;
  final bool isWeb;
  final bool compact;

  const CreatePostWidget({
    Key? key,
    required this.userId,
    required this.companyId,
    this.isWeb = false,
    this.compact = false,
  }) : super(key: key);

  @override
  State<CreatePostWidget> createState() => _CreatePostWidgetState();
}

class _CreatePostWidgetState extends State<CreatePostWidget> {
  final TextEditingController _postController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final FocusNode _focusNode = FocusNode();
  
  List<Uint8List> _selectedImages = [];
  bool _isPosting = false;
  bool _isExpanded = false;

  @override
  void dispose() {
    _postController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile>? images = await _imagePicker.pickMultiImage();
    if (images != null) {
      for (final image in images) {
        final bytes = await image.readAsBytes();
        if (mounted) {
          setState(() {
            _selectedImages.add(bytes);
          });
        }
      }
    }
  }

  Future<void> _createPost() async {
    final content = _postController.text.trim();
    if (content.isEmpty && _selectedImages.isEmpty) {
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      List<String> imageUrls = [];
      
      // Upload images if any. If an upload fails, skip that image but continue.
      int failedUploads = 0;
      for (int i = 0; i < _selectedImages.length; i++) {
        final result = await StorageService.instance.uploadFile(
          _selectedImages[i],
          'post_image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          folder: 'posts',
          contentType: 'image/jpeg',
        );
        if (result.success && result.key.isNotEmpty) {
          imageUrls.add(result.key);
        } else {
          failedUploads++;
          debugPrint('[CreatePostWidget] Image upload failed: ${result.message}');
        }
      }

      // Create post
      await EnhancedPostService.instance.createPost(
        userId: widget.userId,
        companyId: widget.companyId,
        content: content,
        imageUrls: imageUrls,
        metadata: {
          'platform': widget.isWeb ? 'web' : 'mobile',
          'imageCount': imageUrls.length,
        },
      );

      // Reset form
      _postController.clear();
      if (mounted) {
        setState(() {
          _selectedImages.clear();
          _isExpanded = false;
          _isPosting = false;
        });
      }

      if (!widget.compact) {
        Navigator.pop(context);
      }

      if (failedUploads > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post created; $failedUploads image(s) failed to upload'),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post created successfully!'),
            backgroundColor: Colors.green[400],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating post: $e'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactCreatePost();
    } else {
      return _buildFullCreatePost();
    }
  }

  Widget _buildCompactCreatePost() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _toggleExpanded,
                  child: AbsorbPointer(
                    absorbing: !_isExpanded,
                    child: TextField(
                      controller: _postController,
                      focusNode: _focusNode,
                      maxLines: _isExpanded ? null : 1,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: _isExpanded ? "Share your thoughts..." : "What's happening?",
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                      ),
                      onTap: _toggleExpanded,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            if (_selectedImages.isNotEmpty) _buildImagePreview(),
            const SizedBox(height: 12),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildFullCreatePost() {
    return Container(
      padding: EdgeInsets.all(widget.isWeb ? 24 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          if (!widget.isWeb)
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          // Header
          Row(
            children: [
              Text(
                'Create Post',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _postController,
                  focusNode: _focusNode,
                  maxLines: null,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: "What's on your mind?",
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                  ),
                  autofocus: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Image preview
          if (_selectedImages.isNotEmpty) ...[
            _buildImagePreview(),
            const SizedBox(height: 16),
          ],
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          widget.userId.isEmpty ? 'U' : widget.userId[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceVariant,
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _selectedImages[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Media buttons
        Row(
          children: [
            _buildActionButton(
              Icons.image_outlined,
              'Photo',
              _pickImages,
            ),
            if (widget.isWeb) ...[
              _buildActionButton(
                Icons.gif_outlined,
                'GIF',
                () {},
              ),
              _buildActionButton(
                Icons.poll_outlined,
                'Poll',
                () {},
              ),
            ],
            _buildActionButton(
              Icons.emoji_emotions_outlined,
              'Emoji',
              () {},
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Post button
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: widget.compact ? _toggleExpanded : () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: (_postController.text.trim().isEmpty && _selectedImages.isEmpty) || _isPosting
                  ? null
                  : _createPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isPosting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              if (!widget.compact) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

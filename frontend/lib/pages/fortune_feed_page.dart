import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/storage_service.dart';

/// Fortune 500 Style Company Feed Page
/// Professional, clean, enterprise-grade design inspired by Fortune 500 companies
class FortuneFeedPage extends StatefulWidget {
  final String userId;
  final String companyId;

  const FortuneFeedPage({
    Key? key,
    required this.userId,
    required this.companyId,
  }) : super(key: key);

  @override
  State<FortuneFeedPage> createState() => _FortuneFeedPageState();
}

class _FortuneFeedPageState extends State<FortuneFeedPage>
    with TickerProviderStateMixin {
  final PostService _postService = PostService.instance;
  final StorageService _storageService = StorageService.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _postController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();

  List<Uint8List> _selectedImages = [];
  bool _isPosting = false;
  bool _showCreatePost = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _storageService.setBaseUrl('http://localhost:3000');
    }
    _storageService.setCompanyId(widget.companyId);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final showFab = _scrollController.offset > 200;
      if (showFab == _showCreatePost) return;

      _showCreatePost = showFab;
      if (showFab) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _postController.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    _fabAnimationController.dispose();
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
    if (_postController.text.trim().isEmpty && _selectedImages.isEmpty) {
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      List<String> imageUrls = [];
      
      // Upload images if any
      for (int i = 0; i < _selectedImages.length; i++) {
        final result = await _storageService.uploadFile(
          _selectedImages[i],
          'post_image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          folder: 'posts',
          contentType: 'image/jpeg',
        );
        if (result.success && result.key.isNotEmpty) {
          imageUrls.add(result.key);
        }
      }

      // Create post
      await _postService.createPost(
        userId: widget.userId,
        companyId: widget.companyId,
        content: _postController.text.trim(),
        imageUrls: imageUrls,
      );

      // Reset form
      _postController.clear();
      if (mounted) {
        setState(() {
          _selectedImages.clear();
          _showCreatePost = false;
          _isPosting = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post published successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating post: $e'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _showCommentsDialog(PostModel post) {
    showDialog(
      context: context,
      builder: (context) => CommentsDialog(
        post: post,
        currentUserId: widget.userId,
      ),
    );
  }

  void _showShareDialog(PostModel post) {
    showDialog(
      context: context,
      builder: (context) => ShareDialog(post: post),
    );
  }

  String _getDisplayName(String userId) {
    if (userId.length <= 8) return 'User $userId';
    return 'User ${userId.substring(0, 8)}';
  }

  String _getHandle(String userId) {
    if (userId.length <= 6) return '@$userId';
    return '@${userId.substring(0, 6)}';
  }

  String _getAvatarChar(String userId) {
    if (userId.isEmpty) return 'U';
    return userId[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: _buildBody(),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF0066CC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.work,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Company Feed',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        IconButton(
          onPressed: () {
            // Handle notifications
          },
          icon: const Icon(Icons.notifications_outlined),
          color: const Color(0xFF6B7280),
        ),
        IconButton(
          onPressed: () {
            // Handle search
          },
          icon: const Icon(Icons.search),
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Create post section
        _buildCreatePostSection(),
        // Posts feed
        Expanded(
          child: _buildPostsFeed(),
        ),
      ],
    );
  }

  Widget _buildCreatePostSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF0066CC),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getAvatarChar(widget.userId),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Input field
              Expanded(
                child: TextField(
                  controller: _postController,
                  maxLines: null,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Share an update with your team…',
                    hintStyle: TextStyle(color: Color(0xFF6B7280)),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Selected images
          if (_selectedImages.isNotEmpty) ...[
            Container(
              height: 100,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8, top: 8),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.memory(
                            _selectedImages[index],
                            width: 98,
                            height: 98,
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
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFF6B7280),
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
            ),
          ],
          const SizedBox(height: 10),
          // Action buttons
          Row(
            children: [
              // Media button
              TextButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Photo'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0066CC),
                ),
              ),
              const SizedBox(width: 16),
              // Emoji button
              TextButton.icon(
                onPressed: () {
                  // Handle emoji
                },
                icon: const Icon(Icons.emoji_emotions_outlined),
                label: const Text('Emoji'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0066CC),
                ),
              ),
              const Spacer(),
              // Post button
              ElevatedButton(
                onPressed: (_postController.text.trim().isEmpty && _selectedImages.isEmpty) || _isPosting
                    ? null
                    : _createPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isPosting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
      ),
    );
  }

  Widget _buildPostsFeed() {
    return StreamBuilder<List<PostModel>>(
      stream: _postService.getCompanyPosts(widget.companyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0066CC)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error loading posts',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066CC).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.feed_outlined,
                    size: 40,
                    color: Color(0xFF0066CC),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No posts yet',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Be the first to share something with your team!',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showCreatePost = true;
                    });
                  },
                  icon: const Icon(Icons.create),
                  label: const Text('Create First Post'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066CC),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            key: const PageStorageKey<String>('fortune_feed_list'),
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return FortunePostCard(
                post: post,
                currentUserId: widget.userId,
                onComment: () => _showCommentsDialog(post),
                onShare: () => _showShareDialog(post),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: _scrollToTop,
            backgroundColor: const Color(0xFF0066CC),
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.keyboard_arrow_up),
            label: const Text('To Top'),
          ),
        );
      },
    );
  }
}

/// Fortune 500 Style Post Card
/// Clean, professional design with enterprise-grade styling
class FortunePostCard extends StatefulWidget {
  final PostModel post;
  final String currentUserId;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const FortunePostCard({
    Key? key,
    required this.post,
    required this.currentUserId,
    this.onComment,
    this.onShare,
  }) : super(key: key);

  @override
  State<FortunePostCard> createState() => _FortunePostCardState();
}

class _FortunePostCardState extends State<FortunePostCard> {
  bool _isLiked = false;
  bool _isLiking = false;

  String _resolveImageUrl(String value) {
    if (value.trim().isEmpty) return '';

    final v = value.trim();
    if (v.startsWith('http://') || v.startsWith('https://')) {
      return v;
    }

    return StorageService.instance.getPublicUrl(v);
  }

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.likes.any((like) => like.userId == widget.currentUserId);
  }

  Future<void> _toggleLike() async {
    if (_isLiking) return;

    setState(() {
      _isLiking = true;
    });

    try {
      await PostService.instance.toggleLike(
        postId: widget.post.id!,
        userId: widget.currentUserId,
      );

      setState(() {
        _isLiked = !_isLiked;
        _isLiking = false;
      });
    } catch (e) {
      setState(() {
        _isLiking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error toggling like: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  void _showLikesDialog() {
    showDialog(
      context: context,
      builder: (context) => LikesDialog(post: widget.post),
    );
  }

  String _getDisplayName(String userId) {
    if (userId.length <= 8) return 'User $userId';
    return 'User ${userId.substring(0, 8)}';
  }

  String _getHandle(String userId) {
    if (userId.length <= 6) return '@$userId';
    return '@${userId.substring(0, 6)}';
  }

  String _getAvatarChar(String userId) {
    if (userId.isEmpty) return 'U';
    return userId[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066CC),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getAvatarChar(widget.post.userId),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDisplayName(widget.post.userId),
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getHandle(widget.post.userId),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(widget.post.createdAt),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // More options
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Color(0xFF6B7280)),
                  onSelected: (value) {
                    // Handle menu options
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Content
            if (widget.post.content.isNotEmpty)
              Text(
                widget.post.content,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            // Images
            if (widget.post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildImageGrid(),
            ],
            const SizedBox(height: 16),
            // Actions
            Row(
              children: [
                _buildActionButton(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  label: widget.post.likeCount.toString(),
                  onTap: _toggleLike,
                  isActive: _isLiked,
                  isLoading: _isLiking,
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: widget.post.commentCount.toString(),
                  onTap: widget.onComment,
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: widget.onShare,
                  showCount: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    final imageUrls = widget.post.imageUrls;
    if (imageUrls.length == 1) {
      final resolved = _resolveImageUrl(imageUrls[0]);
      if (resolved.isEmpty) return const SizedBox.shrink();
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: resolved,
          fit: BoxFit.cover,
          height: 300,
          width: double.infinity,
          placeholder: (context, url) => Container(
            height: 300,
            color: const Color(0xFFF3F4F6),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF0066CC)),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 300,
            color: const Color(0xFFF3F4F6),
            child: const Center(
              child: Icon(Icons.error_outline, color: Color(0xFF6B7280)),
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: imageUrls.length == 2 ? 2 : 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        final resolved = _resolveImageUrl(imageUrls[index]);
        if (resolved.isEmpty) return const SizedBox.shrink();
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: resolved,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: const Color(0xFFF3F4F6),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF0066CC)),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: const Color(0xFFF3F4F6),
              child: const Center(
                child: Icon(Icons.error_outline, color: Color(0xFF6B7280)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isActive = false,
    bool isLoading = false,
    bool showCount = true,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF0066CC) : const Color(0xFF6B7280),
              size: 18,
            ),
            if (showCount) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? const Color(0xFF0066CC) : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (isLoading) ...[
              const SizedBox(width: 6),
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0066CC)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Comments Dialog
/// Clean, professional dialog for viewing and adding comments
class CommentsDialog extends StatefulWidget {
  final PostModel post;
  final String currentUserId;

  const CommentsDialog({
    Key? key,
    required this.post,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<CommentsDialog> createState() => _CommentsDialogState();
}

class _CommentsDialogState extends State<CommentsDialog> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await PostService.instance.addComment(
        postId: widget.post.id!,
        userId: widget.currentUserId,
        content: _commentController.text.trim(),
      );
      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding comment: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Comments',
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE5E7EB)),
            // Comments list
            Expanded(
              child: ListView.builder(
                itemCount: widget.post.comments.length,
                itemBuilder: (context, index) {
                  final comment = widget.post.comments[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0066CC),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              comment.userId[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Comment content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User ${comment.userId.substring(0, 8)}',
                                style: const TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment.content,
                                style: const TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Comment input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Color(0xFF1A1A1A)),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF0066CC)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send, color: Color(0xFF0066CC)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Likes Dialog
/// Shows list of users who liked a post
class LikesDialog extends StatelessWidget {
  final PostModel post;

  const LikesDialog({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.5,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Likes',
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE5E7EB)),
            // Likes list
            Expanded(
              child: post.likes.isEmpty
                  ? const Center(
                      child: Text(
                        'No likes yet',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: post.likes.length,
                      itemBuilder: (context, index) {
                        final like = post.likes[index];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFF0066CC),
                            child: Text(
                              like.userId[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          title: Text(
                            'User ${like.userId.substring(0, 8)}',
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            timeago.format(like.createdAt),
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            // Close button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Share Dialog
/// Placeholder for share functionality
class ShareDialog extends StatelessWidget {
  final PostModel post;

  const ShareDialog({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.4,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Share Post',
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Content
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066CC).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.share_outlined,
                      size: 40,
                      color: Color(0xFF0066CC),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Share functionality coming soon!',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This will allow sharing posts to other platforms',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Close button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

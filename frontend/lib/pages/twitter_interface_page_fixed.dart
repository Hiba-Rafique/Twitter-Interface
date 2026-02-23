import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/storage_service.dart';
import 'comments_dialog.dart';

class TwitterInterfacePageFixed extends StatefulWidget {
  final String userId;
  final String companyId;

  const TwitterInterfacePageFixed({
    Key? key,
    required this.userId,
    required this.companyId,
  }) : super(key: key);

  @override
  State<TwitterInterfacePageFixed> createState() => _TwitterInterfacePageFixedState();
}

class _TwitterInterfacePageFixedState extends State<TwitterInterfacePageFixed> {
  final PostService _postService = PostService.instance;
  final StorageService _storageService = StorageService.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _postController = TextEditingController();

  List<Uint8List> _selectedImages = [];
  bool _isPosting = false;

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
  void initState() {
    super.initState();
    _storageService.setCompanyId(widget.companyId);
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile>? images = await _imagePicker.pickMultiImage();
    if (images != null) {
      for (final image in images) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImages.add(bytes);
        });
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
        imageUrls.add(result.key);
      }

      // Create post
      await _postService.createPost(
        userId: widget.userId,
        companyId: widget.companyId,
        content: _postController.text.trim(),
        imageUrls: imageUrls,
      );

      // Clear form
      _postController.clear();
      setState(() {
        _selectedImages.clear();
        _isPosting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post created successfully!')),
      );
    } catch (e) {
      setState(() {
        _isPosting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: Text(
          'Company Feed',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFFE2E8F0)),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Color(0xFFE2E8F0)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Create Post Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _getAvatarChar(widget.userId),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Post Input
                    Expanded(
                      child: TextField(
                        controller: _postController,
                        maxLines: null,
                        style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          hintText: "What's happening?",
                          hintStyle: TextStyle(color: Color(0xFF64748B)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Selected Images
                if (_selectedImages.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    height: 100,
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
                            color: const Color(0xFF334155),
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
                                      color: const Color(0xFF1E293B),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Color(0xFFE2E8F0),
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
                const SizedBox(height: 12),
                // Action Buttons
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildActionButton(Icons.image_outlined, 'Photo', _pickImages),
                          _buildActionButton(Icons.gif_outlined, 'GIF', () {}),
                          _buildActionButton(Icons.poll_outlined, 'Poll', () {}),
                          _buildActionButton(Icons.emoji_emotions_outlined, 'Emoji', () {}),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ElevatedButton(
                          onPressed: (_postController.text.trim().isEmpty && _selectedImages.isEmpty) || _isPosting
                              ? null
                              : _createPost,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Posts Feed
          Expanded(
            child: StreamBuilder<List<PostModel>>(
              stream: _postService.getCompanyPosts(widget.companyId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                final posts = snapshot.data ?? [];

                if (posts.isEmpty) {
                  return const Center(
                    child: Text(
                      'No posts yet. Be the first to post!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return PostCard(
                      post: post,
                      currentUserId: widget.userId,
                      onLike: () => _toggleLike(post.id!),
                      onComment: () => _showCommentsDialog(post),
                      onShare: () => _showShareDialog(post),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
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
                color: const Color(0xFF3B82F6),
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleLike(String postId) async {
    try {
      await _postService.toggleLike(
        postId: postId,
        userId: widget.userId,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling like: $e')),
      );
    }
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
}

class PostCard extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const PostCard({
    Key? key,
    required this.post,
    required this.currentUserId,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  }) : super(key: key);

  bool get isLiked => post.likes.any((like) => like.userId == currentUserId);

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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getAvatarChar(post.userId),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getDisplayName(post.userId),
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getHandle(post.userId),
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '· ${timeago.format(post.createdAt)}',
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Content
            if (post.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  post.content,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ),
            // Images
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildImageGrid(post.imageUrls),
            ],
            const SizedBox(height: 16),
            // Actions
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Like
                  GestureDetector(
                    onTap: onLike,
                    onLongPress: () => _showLikesDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isLiked ? const Color(0xFF1E40AF).withOpacity(0.1) : Colors.transparent,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : const Color(0xFF64748B),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            post.likeCount.toString(),
                            style: TextStyle(
                              color: isLiked ? Colors.red : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Comment
                  GestureDetector(
                    onTap: onComment,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.comment_outlined,
                            color: Color(0xFF64748B),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            post.commentCount.toString(),
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Share
                  GestureDetector(
                    onTap: onShare,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.share_outlined,
                            color: Color(0xFF64748B),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Share',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(List<String> imageUrls) {
    if (imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: 'https://storage.buildersolve.com/${imageUrls[0]}',
          fit: BoxFit.cover,
          height: 200,
          width: double.infinity,
          placeholder: (context, url) => Container(
            height: 200,
            color: Colors.grey[800],
            child: const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            color: Colors.grey[800],
            child: const Icon(Icons.error, color: Colors.grey),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: 'https://storage.buildersolve.com/${imageUrls[index]}',
            fit: BoxFit.cover,
            height: 150,
            placeholder: (context, url) => Container(
              height: 150,
              color: Colors.grey[800],
              child: const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 150,
              color: Colors.grey[800],
              child: const Icon(Icons.error, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  void _showLikesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LikesDialog(post: post),
    );
  }
}

class LikesDialog extends StatelessWidget {
  final PostModel post;

  const LikesDialog({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.4,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Likes',
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFFE2E8F0)),
                ),
              ],
            ),
            const Divider(color: Color(0xFF334155)),
            Expanded(
              child: ListView.builder(
                itemCount: post.likes.length,
                itemBuilder: (context, index) {
                  final like = post.likes[index];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF3B82F6),
                      child: Text(
                        like.userId[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                    title: Text(
                      'User ${like.userId.substring(0, 8)}',
                      style: const TextStyle(color: Color(0xFFE2E8F0)),
                    ),
                    subtitle: Text(
                      'Liked ${timeago.format(like.createdAt)}',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShareDialog extends StatelessWidget {
  final PostModel post;

  const ShareDialog({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.4,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Share Post',
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFFE2E8F0)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Icon(
              Icons.share_outlined,
              size: 64,
              color: Color(0xFF64748B),
            ),
            const SizedBox(height: 16),
            const Text(
              'Share functionality coming soon!',
              style: const TextStyle(color: Color(0xFFE2E8F0)),
            ),
            const SizedBox(height: 8),
            const Text(
              'This will allow sharing posts to other platforms',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

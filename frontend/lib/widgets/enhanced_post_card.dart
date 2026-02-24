import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/enhanced_post_model.dart';
import '../services/enhanced_post_service.dart';
import '../services/storage_service.dart';

/// Enhanced Post Card with hover effects and responsive design
/// Production-ready widget with proper state management
class EnhancedPostCard extends StatefulWidget {
  final EnhancedPostModel post;
  final String currentUserId;
  final String companyId;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final bool isWeb;

  const EnhancedPostCard({
    Key? key,
    required this.post,
    required this.currentUserId,
    required this.companyId,
    this.onComment,
    this.onShare,
    this.isWeb = false,
  }) : super(key: key);

  @override
  State<EnhancedPostCard> createState() => _EnhancedPostCardState();
}

class _EnhancedPostCardState extends State<EnhancedPostCard>
    with TickerProviderStateMixin {
  bool _isLiked = false;
  bool _isLiking = false;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _likeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.elasticOut,
    ));

    // Listen to like status
    EnhancedPostService.instance
        .isPostLiked(widget.post.id, widget.currentUserId, widget.companyId)
        .listen((isLiked) {
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
        });
      }
    });
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_isLiking) return;

    setState(() {
      _isLiking = true;
    });

    try {
      final newLikeStatus = await EnhancedPostService.instance.toggleLike(
        postId: widget.post.id,
        userId: widget.currentUserId,
        companyId: widget.companyId,
      );

      if (newLikeStatus) {
        _likeAnimationController.forward().then((_) {
          _likeAnimationController.reverse();
        });
      }

      setState(() {
        _isLiked = newLikeStatus;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error toggling like: $e'),
          backgroundColor: Colors.red[400],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLiking = false;
        });
      }
    }
  }

  void _showLikesDialog() {
    showDialog(
      context: context,
      builder: (context) => LikesDialog(
        postId: widget.post.id,
        companyId: widget.companyId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: widget.isWeb ? 24.0 : 16.0,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {}, // Handle post tap if needed
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildContent(),
                  if (widget.post.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildImageGrid(),
                  ],
                  const SizedBox(height: 16),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfo(),
              const SizedBox(height: 4),
              _buildTimestamp(),
            ],
          ),
        ),
        _buildMoreOptions(),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: widget.isWeb ? 48 : 40,
      height: widget.isWeb ? 48 : 40,
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
          _getAvatarChar(widget.post.userId),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: widget.isWeb ? 18 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Row(
      children: [
        Text(
          _getDisplayName(widget.post.userId),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: widget.isWeb ? 16 : 15,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _getHandle(widget.post.userId),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: widget.isWeb ? 14 : 13,
          ),
        ),
      ],
    );
  }

  Widget _buildTimestamp() {
    return Text(
      '· ${timeago.format(widget.post.createdAt)}',
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        fontSize: widget.isWeb ? 13 : 12,
      ),
    );
  }

  Widget _buildMoreOptions() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      onSelected: (value) {
        // Handle menu options
        switch (value) {
          case 'edit':
            // Handle edit
            break;
          case 'delete':
            // Handle delete
            break;
          case 'report':
            // Handle report
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 16),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag, size: 16),
              SizedBox(width: 8),
              Text('Report'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (widget.post.content.isEmpty) return const SizedBox.shrink();

    return Text(
      widget.post.content,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: widget.isWeb ? 17 : 16,
        height: 1.4,
      ),
    );
  }

  Widget _buildImageGrid() {
    final imageUrls = widget.post.imageUrls;
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    if (imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: StorageService.instance.getPublicUrl(imageUrls[0]),
          fit: BoxFit.cover,
          height: widget.isWeb ? 300 : 200,
          width: double.infinity,
          placeholder: (context, url) => Container(
            height: widget.isWeb ? 300 : 200,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: widget.isWeb ? 300 : 200,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
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
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
            imageUrl: StorageService.instance.getPublicUrl(imageUrls[index]),
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildLikeButton(),
        _buildCommentButton(),
        _buildShareButton(),
      ],
    );
  }

  Widget _buildLikeButton() {
    return _AnimatedActionButton(
      onTap: _toggleLike,
      onLongPress: _showLikesDialog,
      isActive: _isLiked,
      isLoading: _isLiking,
      icon: _isLiked ? Icons.favorite : Icons.favorite_border,
      activeIcon: Icons.favorite,
      count: widget.post.likeCount,
      activeColor: Colors.red,
      animation: _likeAnimation,
    );
  }

  Widget _buildCommentButton() {
    return _AnimatedActionButton(
      onTap: widget.onComment,
      isActive: false,
      icon: Icons.comment_outlined,
      count: widget.post.commentCount,
    );
  }

  Widget _buildShareButton() {
    return _AnimatedActionButton(
      onTap: widget.onShare,
      isActive: false,
      icon: Icons.share_outlined,
      count: widget.post.shareCount,
      showCount: false,
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
}

/// Animated action button with hover effects
class _AnimatedActionButton extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isActive;
  final bool isLoading;
  final IconData icon;
  final IconData? activeIcon;
  final int count;
  final Color? activeColor;
  final Animation<double>? animation;
  final bool showCount;

  const _AnimatedActionButton({
    Key? key,
    this.onTap,
    this.onLongPress,
    required this.isActive,
    this.isLoading = false,
    required this.icon,
    this.activeIcon,
    required this.count,
    this.activeColor,
    this.animation,
    this.showCount = true,
  }) : super(key: key);

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: (widget.activeColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleAnimation, _colorAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: widget.isActive
                      ? (widget.activeColor ?? Colors.red).withOpacity(0.1)
                      : _colorAnimation.value,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: widget.animation ?? const AlwaysStoppedAnimation(1.0),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: widget.animation?.value ?? 1.0,
                          child: widget.isLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      widget.isActive
                                          ? (widget.activeColor ?? Colors.red)
                                          : Theme.of(context).primaryColor,
                                    ),
                                  ),
                                )
                              : Icon(
                                  widget.isActive
                                      ? (widget.activeIcon ?? widget.icon)
                                      : widget.icon,
                                  color: widget.isActive
                                      ? (widget.activeColor ?? Colors.red)
                                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  size: 18,
                                ),
                        );
                      },
                    ),
                    if (widget.showCount && widget.count > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        widget.count.toString(),
                        style: TextStyle(
                          color: widget.isActive
                              ? (widget.activeColor ?? Colors.red)
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Likes dialog for showing users who liked a post
class LikesDialog extends StatelessWidget {
  final String postId;
  final String companyId;

  const LikesDialog({
    Key? key,
    required this.postId,
    required this.companyId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Likes',
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
            const Divider(),
            Expanded(
              child: StreamBuilder<List<PostLike>>(
                stream: EnhancedPostService.instance.getPostLikes(postId, companyId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading likes',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    );
                  }

                  final likes = snapshot.data ?? [];

                  if (likes.isEmpty) {
                    return Center(
                      child: Text(
                        'No likes yet',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: likes.length,
                    itemBuilder: (context, index) {
                      final like = likes[index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).primaryColor,
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
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          'Liked ${timeago.format(like.createdAt)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      );
                    },
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

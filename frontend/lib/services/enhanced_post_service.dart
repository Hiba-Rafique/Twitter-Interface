import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enhanced_post_model.dart';

/// Enhanced Post Service with production-ready features
/// Uses transactions, subcollections, and proper error handling
class EnhancedPostService {
  EnhancedPostService._private();
  static final EnhancedPostService instance = EnhancedPostService._private();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get posts collection reference for a specific company
  CollectionReference<Map<String, dynamic>> _getPostsCollection(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('posts');
  }

  /// Get likes subcollection for a post
  CollectionReference<Map<String, dynamic>> _getLikesCollection(
    String companyId,
    String postId,
  ) {
    return _getPostsCollection(companyId).doc(postId).collection('likes');
  }

  /// Get comments subcollection for a post
  CollectionReference<Map<String, dynamic>> _getCommentsCollection(
    String companyId,
    String postId,
  ) {
    return _getPostsCollection(companyId).doc(postId).collection('comments');
  }

  /// Get comment likes subcollection
  CollectionReference<Map<String, dynamic>> _getCommentLikesCollection(
    String companyId,
    String postId,
    String commentId,
  ) {
    return _getCommentsCollection(companyId, postId)
        .doc(commentId)
        .collection('likes');
  }

  /// Create a new post with proper company scoping
  Future<String> createPost({
    required String userId,
    required String companyId,
    required String content,
    List<String> imageUrls = const [],
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final postRef = _getPostsCollection(companyId).doc();
      final post = EnhancedPostModel(
        id: postRef.id,
        userId: userId,
        companyId: companyId,
        content: content,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        metadata: metadata,
      );

      await postRef.set(post.toFirestore());
      return postRef.id;
    } catch (e) {
      throw PostServiceException('Failed to create post: $e');
    }
  }

  /// Get company posts with real-time updates
  /// Uses compound query for company scoping and performance
  Stream<List<EnhancedPostModel>> getCompanyPosts(String companyId) {
    return _getPostsCollection(companyId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(50) // Pagination for performance
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EnhancedPostModel.fromFirestore(doc))
            .toList());
  }

  /// Get posts by specific user within company
  Stream<List<EnhancedPostModel>> getUserPosts(
    String userId,
    String companyId,
  ) {
    return _getPostsCollection(companyId)
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EnhancedPostModel.fromFirestore(doc))
            .toList());
  }

  /// Toggle like with transaction to prevent race conditions
  Future<bool> toggleLike({
    required String postId,
    required String userId,
    required String companyId,
  }) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        final postRef = _getPostsCollection(companyId).doc(postId);
        final likeRef = _getLikesCollection(companyId, postId).doc(userId);

        // Get post document
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) {
          throw PostServiceException('Post not found');
        }

        // Check if like already exists
        final likeDoc = await transaction.get(likeRef);
        final isLiked = likeDoc.exists;

        if (isLiked) {
          // Remove like
          transaction.delete(likeRef);
          transaction.update(postRef, {
            'likeCount': FieldValue.increment(-1),
            'updatedAt': Timestamp.now(),
          });
          return false;
        } else {
          // Add like
          final like = PostLike(
            id: userId,
            userId: userId,
            createdAt: DateTime.now(),
          );
          transaction.set(likeRef, like.toFirestore());
          transaction.update(postRef, {
            'likeCount': FieldValue.increment(1),
            'updatedAt': Timestamp.now(),
          });
          return true;
        }
      });
    } catch (e) {
      throw PostServiceException('Failed to toggle like: $e');
    }
  }

  /// Check if current user liked the post
  Stream<bool> isPostLiked(String postId, String userId, String companyId) {
    return _getLikesCollection(companyId, postId)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Get users who liked the post (for long-press dialog)
  Stream<List<PostLike>> getPostLikes(String postId, String companyId) {
    return _getLikesCollection(companyId, postId)
        .orderBy('createdAt', descending: false)
        .limit(100) // Limit for performance
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostLike.fromFirestore(doc))
            .toList());
  }

  /// Add comment with proper error handling
  Future<String> addComment({
    required String postId,
    required String userId,
    required String companyId,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final commentRef = _getCommentsCollection(companyId, postId).doc();
      final comment = PostComment(
        id: commentRef.id,
        userId: userId,
        content: content,
        createdAt: DateTime.now(),
        metadata: metadata,
      );

      // Use transaction to update comment count
      await _firestore.runTransaction<void>((transaction) async {
        final postRef = _getPostsCollection(companyId).doc(postId);
        
        transaction.set(commentRef, comment.toFirestore());
        transaction.update(postRef, {
          'commentCount': FieldValue.increment(1),
          'updatedAt': Timestamp.now(),
        });
      });

      return commentRef.id;
    } catch (e) {
      throw PostServiceException('Failed to add comment: $e');
    }
  }

  /// Get comments for a post with real-time updates
  Stream<List<PostComment>> getComments(String postId, String companyId) {
    return _getCommentsCollection(companyId, postId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostComment.fromFirestore(doc))
            .toList());
  }

  /// Toggle comment like with transaction
  Future<bool> toggleCommentLike({
    required String postId,
    required String commentId,
    required String userId,
    required String companyId,
  }) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        final commentRef = _getCommentsCollection(companyId, postId).doc(commentId);
        final likeRef = _getCommentLikesCollection(companyId, postId, commentId)
            .doc(userId);

        // Get comment document
        final commentDoc = await transaction.get(commentRef);
        if (!commentDoc.exists) {
          throw PostServiceException('Comment not found');
        }

        // Check if like already exists
        final likeDoc = await transaction.get(likeRef);
        final isLiked = likeDoc.exists;

        if (isLiked) {
          // Remove like
          transaction.delete(likeRef);
          transaction.update(commentRef, {
            'likeCount': FieldValue.increment(-1),
            'updatedAt': Timestamp.now(),
          });
          return false;
        } else {
          // Add like
          final like = CommentLike(
            id: userId,
            userId: userId,
            createdAt: DateTime.now(),
          );
          transaction.set(likeRef, like.toFirestore());
          transaction.update(commentRef, {
            'likeCount': FieldValue.increment(1),
            'updatedAt': Timestamp.now(),
          });
          return true;
        }
      });
    } catch (e) {
      throw PostServiceException('Failed to toggle comment like: $e');
    }
  }

  /// Check if current user liked a comment
  Stream<bool> isCommentLiked(
    String postId,
    String commentId,
    String userId,
    String companyId,
  ) {
    return _getCommentLikesCollection(companyId, postId, commentId)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Get users who liked a comment
  Stream<List<CommentLike>> getCommentLikes(
    String postId,
    String commentId,
    String companyId,
  ) {
    return _getCommentLikesCollection(companyId, postId, commentId)
        .orderBy('createdAt', descending: false)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentLike.fromFirestore(doc))
            .toList());
  }

  /// Update post content
  Future<void> updatePost({
    required String postId,
    required String companyId,
    required String content,
    List<String>? imageUrls,
  }) async {
    try {
      await _getPostsCollection(companyId).doc(postId).update({
        'content': content,
        if (imageUrls != null) 'imageUrls': imageUrls,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw PostServiceException('Failed to update post: $e');
    }
  }

  /// Soft delete post
  Future<void> deletePost({
    required String postId,
    required String companyId,
  }) async {
    try {
      await _getPostsCollection(companyId).doc(postId).update({
        'isDeleted': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw PostServiceException('Failed to delete post: $e');
    }
  }

  /// Increment share count
  Future<void> incrementShareCount({
    required String postId,
    required String companyId,
  }) async {
    try {
      await _getPostsCollection(companyId).doc(postId).update({
        'shareCount': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw PostServiceException('Failed to increment share count: $e');
    }
  }

  /// Update comment content
  Future<void> updateComment({
    required String postId,
    required String commentId,
    required String companyId,
    required String content,
  }) async {
    try {
      await _getCommentsCollection(companyId, postId).doc(commentId).update({
        'content': content,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw PostServiceException('Failed to update comment: $e');
    }
  }

  /// Soft delete comment
  Future<void> deleteComment({
    required String postId,
    required String commentId,
    required String companyId,
  }) async {
    try {
      await _getCommentsCollection(companyId, postId).doc(commentId).update({
        'isDeleted': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw PostServiceException('Failed to delete comment: $e');
    }
  }
}

/// Custom exception for post service errors
class PostServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  PostServiceException(this.message, {this.code, this.originalError});

  @override
  String toString() {
    return 'PostServiceException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

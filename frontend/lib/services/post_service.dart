import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostService {
  PostService._private();
  static final PostService instance = PostService._private();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _postsCollection =>
      _firestore.collection('posts');

  /// Create a new post
  Future<String> createPost({
    required String userId,
    required String companyId,
    required String content,
    List<String> imageUrls = const [],
  }) async {
    try {
      final post = PostModel(
        userId: userId,
        companyId: companyId,
        content: content,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
      );

      final docRef = await _postsCollection.add(post.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  /// Get a post by ID
  Future<PostModel?> getPost(String postId) async {
    try {
      final docSnapshot = await _postsCollection.doc(postId).get();
      if (docSnapshot.exists) {
        return PostModel.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get post: $e');
    }
  }

  /// Get all posts for a company (sorted by creation date, newest first)
  Stream<List<PostModel>> getCompanyPosts(String companyId) {
    return _postsCollection
        .where('companyId', isEqualTo: companyId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList());
  }

  /// Get posts by a specific user
  Stream<List<PostModel>> getUserPosts(String userId, String companyId) {
    return _postsCollection
        .where('userId', isEqualTo: userId)
        .where('companyId', isEqualTo: companyId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList());
  }

  /// Update a post
  Future<void> updatePost({
    required String postId,
    required String content,
    List<String>? imageUrls,
  }) async {
    try {
      await _postsCollection.doc(postId).update({
        'content': content,
        if (imageUrls != null) 'imageUrls': imageUrls,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  /// Delete a post (soft delete)
  Future<void> deletePost(String postId) async {
    try {
      await _postsCollection.doc(postId).update({
        'isDeleted': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  /// Like or unlike a post
  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final postRef = _postsCollection.doc(postId);
        final postSnap = await transaction.get(postRef);
        if (!postSnap.exists) throw Exception('Post not found');

        final post = PostModel.fromFirestore(postSnap);
        final likes = List<Like>.from(post.likes);

        final existingLikeIndex = likes.indexWhere((like) => like.userId == userId);

        if (existingLikeIndex != -1) {
          // Remove like
          likes.removeAt(existingLikeIndex);
          transaction.update(postRef, {
            'likes': likes.map((l) => l.toJson()).toList(),
            'likeCount': FieldValue.increment(-1),
            'updatedAt': Timestamp.now(),
          });
        } else {
          // Add like
          likes.add(Like(userId: userId, createdAt: DateTime.now()));
          transaction.update(postRef, {
            'likes': likes.map((l) => l.toJson()).toList(),
            'likeCount': FieldValue.increment(1),
            'updatedAt': Timestamp.now(),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  /// Add a comment to a post
  Future<void> addComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    try {
      final comment = Comment(
        id: _firestore.collection('comments').doc().id,
        userId: userId,
        content: content,
        createdAt: DateTime.now(),
      );

      await _firestore.runTransaction((transaction) async {
        final postRef = _postsCollection.doc(postId);
        final postSnap = await transaction.get(postRef);
        if (!postSnap.exists) throw Exception('Post not found');

        transaction.update(postRef, {
          'comments': FieldValue.arrayUnion([comment.toJson()]),
          'commentCount': FieldValue.increment(1),
          'updatedAt': Timestamp.now(),
        });
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Update a comment
  Future<void> updateComment({
    required String postId,
    required String commentId,
    required String content,
  }) async {
    try {
      final postDoc = await _postsCollection.doc(postId).get();
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final post = PostModel.fromFirestore(postDoc);
      final comments = List<Comment>.from(post.comments);
      
      final commentIndex = comments.indexWhere((comment) => comment.id == commentId);
      if (commentIndex == -1) {
        throw Exception('Comment not found');
      }

      comments[commentIndex] = comments[commentIndex].copyWith(
        content: content,
        updatedAt: DateTime.now(),
      );

      await _postsCollection.doc(postId).update({
        'comments': comments.map((comment) => comment.toJson()).toList(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update comment: $e');
    }
  }

  /// Delete a comment (soft delete)
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    try {
      final postDoc = await _postsCollection.doc(postId).get();
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final post = PostModel.fromFirestore(postDoc);
      final comments = List<Comment>.from(post.comments);
      
      final commentIndex = comments.indexWhere((comment) => comment.id == commentId);
      if (commentIndex == -1) {
        throw Exception('Comment not found');
      }

      comments[commentIndex] = comments[commentIndex].copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
      );

      await _postsCollection.doc(postId).update({
        'comments': comments.map((comment) => comment.toJson()).toList(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  /// Like or unlike a comment
  Future<void> toggleCommentLike({
    required String postId,
    required String commentId,
    required String userId,
  }) async {
    try {
      final postDoc = await _postsCollection.doc(postId).get();
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final post = PostModel.fromFirestore(postDoc);
      final comments = List<Comment>.from(post.comments);
      
      final commentIndex = comments.indexWhere((comment) => comment.id == commentId);
      if (commentIndex == -1) {
        throw Exception('Comment not found');
      }

      final comment = comments[commentIndex];
      final likes = List<Like>.from(comment.likes);
      
      // Check if user already liked the comment
      final existingLikeIndex = likes.indexWhere((like) => like.userId == userId);
      
      if (existingLikeIndex != -1) {
        // Remove like
        likes.removeAt(existingLikeIndex);
      } else {
        // Add like
        likes.add(Like(
          userId: userId,
          createdAt: DateTime.now(),
        ));
      }

      comments[commentIndex] = comment.copyWith(likes: likes);

      await _postsCollection.doc(postId).update({
        'comments': comments.map((comment) => comment.toJson()).toList(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to toggle comment like: $e');
    }
  }

  /// Increment share count
  Future<void> incrementShareCount(String postId) async {
    try {
      await _postsCollection.doc(postId).update({
        'shareCount': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to increment share count: $e');
    }
  }

  /// Get users who liked a post
  Future<List<String>> getPostLikes(String postId) async {
    try {
      final post = await getPost(postId);
      if (post == null) {
        return [];
      }
      return post.likes.map((like) => like.userId).toList();
    } catch (e) {
      throw Exception('Failed to get post likes: $e');
    }
  }

  /// Get users who liked a comment
  Future<List<String>> getCommentLikes(String postId, String commentId) async {
    try {
      final post = await getPost(postId);
      if (post == null) {
        return [];
      }
      
      final comment = post.comments.firstWhere(
        (comment) => comment.id == commentId,
        orElse: () => throw Exception('Comment not found'),
      );
      
      return comment.likes.map((like) => like.userId).toList();
    } catch (e) {
      throw Exception('Failed to get comment likes: $e');
    }
  }
}

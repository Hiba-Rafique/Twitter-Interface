import 'package:cloud_firestore/cloud_firestore.dart';

/// Enhanced Post Model with production-ready structure
/// Uses subcollections for likes and comments for scalability
class EnhancedPostModel {
  final String id;
  final String userId;
  final String companyId;
  final String content;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isDeleted;
  final Map<String, dynamic>? metadata;

  const EnhancedPostModel({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.content,
    this.imageUrls = const [],
    required this.createdAt,
    this.updatedAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.isDeleted = false,
    this.metadata,
  });

  /// Create from Firestore document
  factory EnhancedPostModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return EnhancedPostModel(
      id: doc.id,
      userId: data['userId'] as String,
      companyId: data['companyId'] as String,
      content: data['content'] as String,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      shareCount: (data['shareCount'] as num?)?.toInt() ?? 0,
      isDeleted: data['isDeleted'] as bool? ?? false,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'companyId': companyId,
      'content': content,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'likeCount': likeCount,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'isDeleted': isDeleted,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Create copy with updated values
  EnhancedPostModel copyWith({
    String? id,
    String? userId,
    String? companyId,
    String? content,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    bool? isDeleted,
    Map<String, dynamic>? metadata,
  }) {
    return EnhancedPostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyId: companyId ?? this.companyId,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      isDeleted: isDeleted ?? this.isDeleted,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'EnhancedPostModel(id: $id, userId: $userId, companyId: $companyId, content: $content)';
  }
}

/// Like model for subcollection
class PostLike {
  final String id;
  final String userId;
  final DateTime createdAt;

  const PostLike({
    required this.id,
    required this.userId,
    required this.createdAt,
  });

  factory PostLike.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PostLike(
      id: doc.id,
      userId: data['userId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Enhanced Comment model for subcollection
class PostComment {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final bool isDeleted;
  final Map<String, dynamic>? metadata;

  const PostComment({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.likeCount = 0,
    this.isDeleted = false,
    this.metadata,
  });

  factory PostComment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PostComment(
      id: doc.id,
      userId: data['userId'] as String,
      content: data['content'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      isDeleted: data['isDeleted'] as bool? ?? false,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'likeCount': likeCount,
      'isDeleted': isDeleted,
      if (metadata != null) 'metadata': metadata,
    };
  }

  PostComment copyWith({
    String? id,
    String? userId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likeCount,
    bool? isDeleted,
    Map<String, dynamic>? metadata,
  }) {
    return PostComment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likeCount: likeCount ?? this.likeCount,
      isDeleted: isDeleted ?? this.isDeleted,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Comment Like model for subcollection
class CommentLike {
  final String id;
  final String userId;
  final DateTime createdAt;

  const CommentLike({
    required this.id,
    required this.userId,
    required this.createdAt,
  });

  factory CommentLike.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CommentLike(
      id: doc.id,
      userId: data['userId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String? id;
  final String userId;
  final String companyId;
  final String content;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<Like> likes;
  final List<Comment> comments;
  final int shareCount;
  final bool isDeleted;

  PostModel({
    this.id,
    required this.userId,
    required this.companyId,
    required this.content,
    this.imageUrls = const [],
    required this.createdAt,
    this.updatedAt,
    this.likes = const [],
    this.comments = const [],
    this.shareCount = 0,
    this.isDeleted = false,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      companyId: data['companyId'] ?? '',
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      likes: (data['likes'] as List?)
          ?.map((like) => Like.fromJson(like))
          .toList() ?? [],
      comments: (data['comments'] as List?)
          ?.map((comment) => Comment.fromJson(comment))
          .toList() ?? [],
      shareCount: data['shareCount'] ?? 0,
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'companyId': companyId,
      'content': content,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'likes': likes.map((like) => like.toJson()).toList(),
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'shareCount': shareCount,
      'isDeleted': isDeleted,
    };
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? companyId,
    String? content,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Like>? likes,
    List<Comment>? comments,
    int? shareCount,
    bool? isDeleted,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyId: companyId ?? this.companyId,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shareCount: shareCount ?? this.shareCount,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  int get likeCount => likes.length;
  int get commentCount => comments.length;
  bool get isLikedByCurrentUser => false; // Will be set based on current user
}

class Like {
  final String userId;
  final DateTime createdAt;

  Like({
    required this.userId,
    required this.createdAt,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      userId: json['userId'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class Comment {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<Like> likes;
  final bool isDeleted;

  Comment({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.likes = const [],
    this.isDeleted = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      content: json['content'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null 
          ? (json['updatedAt'] as Timestamp).toDate() 
          : null,
      likes: (json['likes'] as List?)
          ?.map((like) => Like.fromJson(like))
          .toList() ?? [],
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'likes': likes.map((like) => like.toJson()).toList(),
      'isDeleted': isDeleted,
    };
  }

  Comment copyWith({
    String? id,
    String? userId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Like>? likes,
    bool? isDeleted,
  }) {
    return Comment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  int get likeCount => likes.length;
}

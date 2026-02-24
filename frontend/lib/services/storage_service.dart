import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Storage Service that uses Node.js backend API
/// Replaces direct R2 access with API calls
class StorageService {
  StorageService._private();
  static final StorageService instance = StorageService._private();

  // ============================================================
  // API CONFIGURATION
  // ============================================================
  // Default backend URL (production). You can override this at runtime
  // with `setBaseUrl()` for local testing (e.g. http://localhost:3000).
  String _baseUrl = 'https://api.twitter-interface.com/api/storage';

  // Optional R2 direct info (used to build public URLs). Not required for uploads
  // because uploads go through the backend. If you have a public R2 setup,
  // set these with `setR2Config(accountId, bucket)` to construct public URLs.
  String? _r2AccountId;
  String? _r2Bucket;

  // ============================================================
  // INITIALIZATION STATE
  // ============================================================
  bool _initialized = false;
  String? _currentCompanyId;

  // ============================================================
  // PUBLIC METHODS
  // ============================================================

  /// Set the company ID for this service
  /// Call this before performing any storage operations
  void setCompanyId(String companyId) {
    _currentCompanyId = companyId;
    _initialized = false; // Reset initialization for new company
    debugPrint('[StorageService] Company ID set: $companyId');
  }

  /// Override backend base url at runtime (useful for local testing)
  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
    debugPrint('[StorageService] Base URL set: $_baseUrl');
  }

  /// Optionally set R2 account and bucket so `getPublicUrl()` can build
  /// an object URL (may not be publicly accessible depending on bucket policy).
  void setR2Config(String accountId, String bucket) {
    _r2AccountId = accountId;
    _r2Bucket = bucket;
    debugPrint('[StorageService] R2 config set: account=$_r2AccountId bucket=$_r2Bucket');
  }

  /// Initialize the service
  /// Call this after user login or when companyId becomes available
  Future<void> initialize() async {
    final companyId = _currentCompanyId; // Will be set from outside

    if (companyId == null) {
      debugPrint('[StorageService] No company ID available, skipping init');
      return;
    }

    // Skip if already initialized for this company
    if (_initialized && _currentCompanyId == companyId) {
      debugPrint('[StorageService] Already initialized for company: $companyId');
      return;
    }

    try {
      debugPrint('[StorageService] Initializing for company: $companyId');
      debugPrint('[StorageService] Current baseUrl: $_baseUrl');
      
      // Call backend initialize endpoint (optional - backend auto-initializes)
      final response = await http.post(
        Uri.parse('$_baseUrl/initialize'),
        headers: _getHeaders(companyId),
      );

      if (response.statusCode == 200) {
        _currentCompanyId = companyId;
        _initialized = true;
        debugPrint('[StorageService] ✅ Initialization complete');
      } else {
        throw StorageException(
          'Initialization failed: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      debugPrint('[StorageService] ❌ Initialization error: $e');
      // Don't rethrow: allow callers to continue even if backend init failed.
      // Uploads will still be attempted, and uploadFile() handles failures.
      _initialized = false;
      return;
    }
  }

  /// Upload a file
  /// [bytes] - File content as Uint8List
  /// [fileName] - Name of the file
  /// [folder] - Optional subfolder within company folder (e.g., "Daily Logs")
  Future<StorageResult> uploadFile(
    Uint8List bytes,
    String fileName, {
    String? folder,
    String? contentType,
  }) async {
    await _ensureInitialized();

    try {
      final uri = Uri.parse('$_baseUrl/upload');
      debugPrint('[StorageService] Upload URI: $uri');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll(_getHeaders(_currentCompanyId!));
      
      // Add file
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ));
      
      // Add folder if provided
      if (folder != null && folder.isNotEmpty) {
        request.fields['folder'] = folder;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StorageResult.fromJson(data);
      }

      throw StorageException(
        'Upload failed: ${response.statusCode}',
        response.body,
      );
    } catch (e) {
      debugPrint('[StorageService] Upload error: $e');
      // Return a non-throwing failure result so callers can still create posts
      return StorageResult(
        success: false,
        message: e.toString(),
        key: '',
        size: null,
        contentType: contentType,
      );
    }
  }

  /// Reset initialization (call on logout)
  void reset() {
    _initialized = false;
    _currentCompanyId = null;
    debugPrint('[StorageService] Reset complete');
  }

  // ============================================================
  // PRIVATE METHODS
  // ============================================================

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }

    // If initialization still failed, allow operations to continue as long as a
    // company ID is set. We only throw if no company ID is available because
    // headers are required by the backend.
    if (!_initialized && _currentCompanyId == null) {
      throw StorageException(
        'StorageService not initialized',
        'Company ID may not be available',
      );
    }
  }

  Map<String, String> _getHeaders(String companyId) {
    return {
      'x-company-id': companyId,
    };
  }

  /// Build a public URL for a stored object key when R2 account and bucket
  /// are configured. This may not be accessible publicly without a Worker
  /// or proper bucket settings; use it as a convenience for testing.
  String getPublicUrl(String key) {
    if (key.isEmpty) return '';

    // Prefer backend proxy for local development (avoids R2 CORS issues).
    final lowerBase = _baseUrl.toLowerCase();
    if (lowerBase.contains('localhost') || lowerBase.contains('127.0.0.1')) {
      return '$_baseUrl/files/$key';
    }

    // If baseUrl is set to a non-production host, prefer the backend proxy.
    if (_baseUrl.startsWith('http') && !_baseUrl.contains('api.twitter-interface.com')) {
      return '$_baseUrl/files/$key';
    }

    // Otherwise, prefer direct R2 URL when configured.
    if (_r2AccountId != null && _r2Bucket != null) {
      return 'https://${_r2AccountId}.r2.cloudflarestorage.com/${_r2Bucket}/$key';
    }

    // Final fallback: backend files route
    return '$_baseUrl/files/$key';
  }
}

// ============================================================
// DATA MODELS
// ============================================================

class StorageResult {
  final bool success;
  final String message;
  final String key;
  final int? size;
  final String? contentType;
  final int? deletedCount;

  StorageResult({
    required this.success,
    required this.message,
    required this.key,
    this.size,
    this.contentType,
    this.deletedCount,
  });

  factory StorageResult.fromJson(Map<String, dynamic> json) {
    return StorageResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      key: json['key'] ?? '',
      size: json['size'],
      contentType: json['contentType'],
      deletedCount: json['deletedCount'],
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'key': key,
        if (size != null) 'size': size,
        if (contentType != null) 'contentType': contentType,
        if (deletedCount != null) 'deletedCount': deletedCount,
      };
}

class StorageException implements Exception {
  final String message;
  final String? details;

  StorageException(this.message, [this.details]);

  @override
  String toString() =>
      'StorageException: $message${details != null ? ' - $details' : ''}';
}

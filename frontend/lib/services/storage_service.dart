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
  static const String _baseUrl = 'https://storage.buildersolve.com/api/storage';

  // ============================================================
  // INITIALIZATION STATE
  // ============================================================
  bool _initialized = false;
  String? _currentCompanyId;

  // ============================================================
  // PUBLIC METHODS
  // ============================================================

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
      rethrow;
    }
  }

  /// Set company ID and initialize
  void setCompanyId(String companyId) {
    _currentCompanyId = companyId;
    _initialized = false;
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
      rethrow;
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

    if (!_initialized) {
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

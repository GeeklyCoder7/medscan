import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';
import 'dart:typed_data';
import '../widgets/scan_button.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService(String apiKey) {
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
  }

  Future<String> analyzeMedicalScan({
    required File imageFile,
    required ScanType scanType,
  }) async {
    final imageBytes = await imageFile.readAsBytes();
    final prompt = _buildPrompt(scanType);

    final content = [
      Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
    ];

    // Use retry logic with exponential backoff
    return await _retryWithExponentialBackoff(() async {
      final response = await _model.generateContent(content);
      return response.text ?? 'No analysis available';
    });
  }

  // NEW METHOD: For custom prompts (like summary generation)
  Future<String> analyzeMedicalScanWithCustomPrompt({
    required Uint8List imageBytes,
    required String customPrompt,
  }) async {
    final content = [
      Content.multi([
        TextPart(customPrompt),
        DataPart('image/jpeg', imageBytes),
      ]),
    ];

    // Use retry logic with exponential backoff
    return await _retryWithExponentialBackoff(() async {
      final response = await _model.generateContent(content);
      return response.text ?? 'No summary available';
    });
  }

  /// Retry logic with exponential backoff for handling transient errors
  Future<String> _retryWithExponentialBackoff(
    Future<String> Function() operation, {
    int maxAttempts = 5,
    Duration initialDelay = const Duration(seconds: 2),
    Duration maxDelay = const Duration(seconds: 60),
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;

    while (true) {
      try {
        attempt++;
        print('Attempt $attempt of $maxAttempts...');

        return await operation();
      } catch (e) {
        final isRetryable = _isRetryableError(e);
        final hasAttemptsLeft = attempt < maxAttempts;

        if (!isRetryable || !hasAttemptsLeft) {
          // Non-retryable error or max attempts reached
          print('Failed after $attempt attempts: $e');
          rethrow;
        }

        // Log the retry
        print(
          'Attempt $attempt failed (${_getErrorType(e)}), retrying in ${currentDelay.inSeconds}s...',
        );

        // Wait before retrying
        await Future.delayed(currentDelay);

        // Exponential backoff: double the delay, but cap at maxDelay
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * 2).clamp(
            initialDelay.inMilliseconds,
            maxDelay.inMilliseconds,
          ),
        );
      }
    }
  }

  /// Check if an error is retryable (503, 429, 500, network issues)
  bool _isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Check for specific HTTP error codes
    if (errorString.contains('503') || errorString.contains('overloaded')) {
      return true; // Service unavailable / Model overloaded
    }
    if (errorString.contains('429') ||
        errorString.contains('resource_exhausted')) {
      return true; // Rate limit exceeded
    }
    if (errorString.contains('500') || errorString.contains('internal error')) {
      return true; // Internal server error
    }
    if (errorString.contains('timeout')) {
      return true; // Request timeout
    }

    // Check for network-related errors
    if (error is SocketException || error is HttpException) {
      return true;
    }

    return false;
  }

  /// Get human-readable error type for logging
  String _getErrorType(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('503') || errorString.contains('overloaded')) {
      return 'Model Overloaded';
    }
    if (errorString.contains('429')) {
      return 'Rate Limit';
    }
    if (errorString.contains('500')) {
      return 'Server Error';
    }
    if (errorString.contains('timeout')) {
      return 'Timeout';
    }

    return 'Unknown Error';
  }

  String _buildPrompt(ScanType scanType) {
    String scanName = scanType.toString().split('.').last.toUpperCase();

    return '''
You are a medical imaging assistant. Analyze this $scanName scan image and provide a detailed analysis in simple, layman-friendly language.

Please include:
1. Description of what is visible in the scan
2. Any notable findings or abnormalities
3. Potential conditions or diseases (if identifiable)
4. Areas that appear normal
5. Recommendations for further consultation

Important: Keep the language simple and easy to understand for non-medical professionals. Always remind users to consult with qualified healthcare professionals.
''';
  }
}

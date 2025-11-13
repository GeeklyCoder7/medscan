import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';
import '../widgets/scan_button.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService(String apiKey) {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',  // Updated to correct model name
      apiKey: apiKey,
    );
  }

  Future<String> analyzeMedicalScan({
    required File imageFile,
    required ScanType scanType,
  }) async {
    final imageBytes = await imageFile.readAsBytes();

    final prompt = _buildPrompt(scanType);

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ])
    ];

    final response = await _model.generateContent(content);
    return response.text ?? 'No analysis available';
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

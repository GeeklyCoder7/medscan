import 'dart:math';
import 'package:flutter/material.dart';
import 'package:medscan/config/api_config.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/create_pdf_service.dart';
import '../services/gemini_service.dart';
import '../widgets/scan_button.dart';

class AnalysisResultScreen extends StatefulWidget {
  final String analysis;
  final File scanImage;
  final ScanType scanType;
  const AnalysisResultScreen({
    super.key,
    required this.analysis,
    required this.scanImage,
    required this.scanType,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

enum TtsState { playing, stopped }

class _AnalysisResultScreenState extends State<AnalysisResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _typewriterController;
  String _displayedText = '';
  bool _isTypingComplete = false;
  bool _isGeneratingPdf = false;

  // TTS variables
  late FlutterTts flutterTts;
  TtsState ttsState = TtsState.stopped;

  // Summary variables
  bool _isGeneratingSummary = false;
  String? _cachedSummary;

  @override
  void initState() {
    super.initState();

    _typewriterController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.analysis.length * 20),
    );

    _startTypewriter();
    _initTts();
  }

  void _initTts() async {
    flutterTts = FlutterTts();

    try {
      await flutterTts.awaitSpeakCompletion(true);

      flutterTts.setStartHandler(() {
        if (mounted) {
          setState(() {
            ttsState = TtsState.playing;
          });
        }
      });

      flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            ttsState = TtsState.stopped;
          });
        }
      });

      flutterTts.setErrorHandler((msg) {
        if (mounted) {
          setState(() {
            ttsState = TtsState.stopped;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('TTS Error: $msg'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });

      flutterTts.setCancelHandler(() {
        if (mounted) {
          setState(() {
            ttsState = TtsState.stopped;
          });
        }
      });

      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);

      if (Platform.isAndroid) {
        await flutterTts.setEngine("com.google.android.tts");
      }

      print("TTS initialized successfully");
    } catch (e) {
      print("TTS initialization error: $e");
    }
  }

  String _cleanTextForSpeech(String text) {
    String cleanedText = text
        .replaceAll(RegExp(r'##\s*'), '')
        .replaceAll(RegExp(r'\*\*\*'), '')
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'\*'), '')
        .replaceAll(RegExp(r'#{1,6}\s*'), '');

    return cleanedText.trim();
  }

  Future<void> _speak() async {
    if (_displayedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No text to read'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    try {
      if (ttsState == TtsState.playing) {
        // Stop the speech
        await flutterTts.stop();
        if (mounted) {
          setState(() {
            ttsState = TtsState.stopped;
          });
        }
        print("TTS stopped");
      } else {
        // Start speaking
        String textToSpeak = _cleanTextForSpeech(_displayedText);
        var result = await flutterTts.speak(textToSpeak);

        if (result == 1) {
          print("TTS started successfully");
        } else {
          print("TTS failed to start - result: $result");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to start text-to-speech'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      print("TTS error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TTS Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _generateSummary() async {
    // If summary already exists, show it
    if (_cachedSummary != null) {
      _showSummaryDialog(_cachedSummary!);
      return;
    }

    setState(() {
      _isGeneratingSummary = true;
    });

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0D47A1).withOpacity(0.95),
                Color(0xFF1976D2).withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                'Generating Summary...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please wait',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final summaryPrompt = '''
Summarize the following medical scan analysis in 200-300 words using simple, easy-to-understand language that a non-medical person can comprehend. Focus on:
- What was found in the scan
- Whether findings are normal or concerning
- Key takeaways for the patient
- Any recommendations

Analysis to summarize:
${widget.analysis}

Provide a clear, concise summary in plain English without medical jargon.
''';

      // Get API key from your config
      final apiKey = ApiConfig.geminiApiKey;
      final geminiService = GeminiService(apiKey);

      final summary = await geminiService.analyzeMedicalScanWithCustomPrompt(
        imageBytes: await widget.scanImage.readAsBytes(),
        customPrompt: summaryPrompt,
      );

      setState(() {
        _cachedSummary = summary;
        _isGeneratingSummary = false;
      });

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSummaryDialog(summary);
      }
    } catch (e) {
      setState(() {
        _isGeneratingSummary = false;
      });

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate summary: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _showSummaryDialog(String summary) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D47A1).withOpacity(0.98),
                Color(0xFF1976D2).withOpacity(0.98),
                Color(0xFF42A5F5).withOpacity(0.98),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.summarize_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Summary',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Easy-to-understand overview',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content with formatted text
              Flexible(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.all(24),
                  child: RichText(
                    text: TextSpan(
                      children: _parseFormattedText(summary),
                    ),
                  ),
                ),
              ),
              // Footer
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.amber,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is a simplified overview. Read full report for details.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startTypewriter() {
    _typewriterController.addListener(() {
      final progress = _typewriterController.value;
      final targetLength = (widget.analysis.length * progress).round();

      if (mounted) {
        setState(() {
          _displayedText = widget.analysis.substring(0, targetLength);
          if (targetLength >= widget.analysis.length) {
            _isTypingComplete = true;
          }
        });
      }
    });

    _typewriterController.forward();
  }

  Future<void> _shareReport() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Generating PDF Report...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );

      final pdfFile = await PdfService.generateAnalysisReport(
        imageFile: widget.scanImage,
        analysis: widget.analysis,
        scanType: _getScanTypeName(),
      );

      if (mounted) {
        Navigator.pop(context);
      }

      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        subject: 'MedScan Analysis Report - ${_getScanTypeName()}',
        text: 'Here is my medical scan analysis report from MedScan AI.',
      );
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _typewriterController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Analysis Results',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.share_rounded, color: Colors.white),
            onPressed: _isGeneratingPdf ? null : _shareReport,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  _buildScanTypeBadge(),
                  SizedBox(height: 16),
                  _buildImageCard(),
                  SizedBox(height: 24),
                  _buildSectionTitle('AI Analysis Report'),
                  SizedBox(height: 16),
                  _buildAnalysisCard(),
                  SizedBox(height: 24),
                  _buildDisclaimerCard(),
                  SizedBox(height: 20),
                  _buildActionButtons(context),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanTypeBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getScanTypeGradient(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getScanTypeGradient()[0].withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getScanTypeIcon(), color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            _getScanTypeName(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              height: 280,
              width: double.infinity,
              color: Colors.black12,
              child: Image.file(widget.scanImage, fit: BoxFit.cover),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1)),
              child: Row(
                children: [
                  Icon(
                    Icons.image_rounded,
                    color: Colors.white.withOpacity(0.9),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Uploaded ${_getScanTypeName()} Image',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.5)),
                    ),
                    child: Text(
                      'Analyzed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          height: 24,
          width: 4,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 12),
        Icon(Icons.description_rounded, color: Colors.white, size: 22),
        SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Generated Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Powered by Gemini AI',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isTypingComplete)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              if (_isTypingComplete) ...[
                SizedBox(width: 8),
                _buildVoiceControls(),
              ],
            ],
          ),
          SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.3), thickness: 1),
          SizedBox(height: 16),
          RichText(
            text: TextSpan(
              children: [
                ..._parseFormattedText(_displayedText),
                if (!_isTypingComplete) WidgetSpan(child: _buildCursor()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Voice Control Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _speak,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ttsState == TtsState.playing
                    ? Colors.amber.withOpacity(0.3)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ttsState == TtsState.playing
                      ? Colors.amber
                      : Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                ttsState == TtsState.playing
                    ? Icons.stop_rounded
                    : Icons.volume_up_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        // Summary Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isGeneratingSummary ? null : _generateSummary,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _cachedSummary != null
                    ? Colors.green.withOpacity(0.3)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _cachedSummary != null
                      ? Colors.green
                      : Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.summarize_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCursor() {
    return AnimatedBuilder(
      animation: _typewriterController,
      builder: (context, child) {
        return Opacity(
          opacity: (sin(_typewriterController.value * 2 * pi * 3) + 1) / 2,
          child: Container(
            width: 8,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      },
    );
  }

  List<TextSpan> _parseFormattedText(String text) {
    final List<TextSpan> spans = [];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      if (line.startsWith('##')) {
        final headingText = line.replaceFirst(RegExp(r'^#+\s*'), '');
        spans.add(
          TextSpan(
            text: headingText + '\n',
            style: TextStyle(
              fontSize: 17,
              height: 1.8,
              color: Colors.white,
              letterSpacing: 0.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        continue;
      }

      int currentIndex = 0;
      final boldPattern = RegExp(r'\*\*\*?(.*?)\*\*\*?');

      for (final match in boldPattern.allMatches(line)) {
        if (match.start > currentIndex) {
          spans.add(
            TextSpan(
              text: line.substring(currentIndex, match.start),
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.white.withOpacity(0.95),
                letterSpacing: 0.3,
              ),
            ),
          );
        }

        spans.add(
          TextSpan(
            text: match.group(1),
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.white,
              letterSpacing: 0.3,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

        currentIndex = match.end;
      }

      if (currentIndex < line.length) {
        spans.add(
          TextSpan(
            text: line.substring(currentIndex),
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.white.withOpacity(0.95),
              letterSpacing: 0.3,
            ),
          ),
        );
      }

      if (i < lines.length - 1) {
        spans.add(
          TextSpan(
            text: '\n',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.white.withOpacity(0.95),
              letterSpacing: 0.3,
            ),
          ),
        );
      }
    }

    return spans;
  }

  Widget _buildDisclaimerCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade700.withOpacity(0.8),
            Colors.orange.shade600.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.orange.shade300.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.warning_rounded, color: Colors.white, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medical Disclaimer',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'For educational purposes only. Always consult qualified healthcare professionals for medical advice.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.95),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Home',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF2E7D32).withOpacity(0.4),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'New Scan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getScanTypeName() {
    switch (widget.scanType) {
      case ScanType.ct:
        return 'CT Scan';
      case ScanType.mri:
        return 'MRI Scan';
      case ScanType.xray:
        return 'X-Ray';
    }
  }

  IconData _getScanTypeIcon() {
    switch (widget.scanType) {
      case ScanType.ct:
        return Icons.medical_services_rounded;
      case ScanType.mri:
        return Icons.scanner_rounded;
      case ScanType.xray:
        return Icons.healing_rounded;
    }
  }

  List<Color> _getScanTypeGradient() {
    switch (widget.scanType) {
      case ScanType.ct:
        return [Color(0xFF6A1B9A), Color(0xFF8E24AA)];
      case ScanType.mri:
        return [Color(0xFF00838F), Color(0xFF00ACC1)];
      case ScanType.xray:
        return [Color(0xFFD84315), Color(0xFFFF5722)];
    }
  }
}

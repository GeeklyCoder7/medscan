import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:io';
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

class _AnalysisResultScreenState extends State<AnalysisResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _typewriterController;
  String _displayedText = '';
  bool _isTypingComplete = false;

  @override
  void initState() {
    super.initState();

    _typewriterController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.analysis.length * 20), // 20ms per character
    );

    _startTypewriter();
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

  @override
  void dispose() {
    _typewriterController.dispose();
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Share feature coming soon!'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
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
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF1976D2),
              Color(0xFF42A5F5),
            ],
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
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              height: 280,
              width: double.infinity,
              color: Colors.black12,
              child: Image.file(
                widget.scanImage,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
              ),
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
                      border: Border.all(
                        color: Colors.green.withOpacity(0.5),
                      ),
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
        Icon(
          Icons.description_rounded,
          color: Colors.white,
          size: 22,
        ),
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
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
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
            ],
          ),
          SizedBox(height: 16),
          Divider(
            color: Colors.white.withOpacity(0.3),
            thickness: 1,
          ),
          SizedBox(height: 16),
          RichText(
            text: TextSpan(
              children: [
                ..._parseFormattedText(_displayedText),
                if (!_isTypingComplete)
                  WidgetSpan(
                    child: _buildCursor(),
                  ),
              ],
            ),
          ),
        ],
      ),
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
            child: Icon(
              Icons.warning_rounded,
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

import 'package:flutter/material.dart';
import 'dart:io';
import '../widgets/scan_button.dart';

class AnalysisResultScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analysis Results'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(scanImage, fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Analysis Report',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                analysis,
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Disclaimer: This is for educational purposes only. Always consult qualified healthcare professionals.',
                      style: TextStyle(fontSize: 14),
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
}

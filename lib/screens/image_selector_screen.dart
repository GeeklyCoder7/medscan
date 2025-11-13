import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:medscan/screens/analysis_result_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:medscan/config/api_config.dart';
import '../services/gemini_service.dart';
import '../widgets/scan_button.dart';

class ImageSelectorScreen extends StatefulWidget {
  final ScanType scanType;

  const ImageSelectorScreen({super.key, required this.scanType});

  @override
  State<ImageSelectorScreen> createState() => _ImageSelectorScreenState();
}

class _ImageSelectorScreenState extends State<ImageSelectorScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select ${_getScanTypeName()} Image')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedImage != null) ...[
              Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.file(_selectedImage!, fit: BoxFit.cover),
              ),
              const SizedBox(height: 20),
            ] else ...[
              Icon(Icons.add_photo_alternate, size: 100, color: Colors.grey),
              const SizedBox(height: 20),
              Text(
                'No image selected',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 40),
            if (!_isAnalyzing) ...[
              ElevatedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: Icon(Icons.photo_library),
                label: Text('Pick from Gallery'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _pickImageFromCamera,
                icon: Icon(Icons.camera_alt),
                label: Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
              if (_selectedImage != null) ...[
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: _analyzeImage,
                  icon: Icon(Icons.analytics),
                  label: Text('Analyze Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
              ],
            ] else ...[
              CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text('Analyzing image...', style: TextStyle(fontSize: 16)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    // Request permission first
    PermissionStatus status;

    if (Platform.isAndroid) {
      // Check Android version
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        status = await Permission.photos.request();
      } else {
        status = await Permission.storage.request();
      }
    } else {
      status = await Permission.photos.request();
    }

    if (status.isGranted) {
      try {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );

        if (image != null) {
          setState(() {
            _selectedImage = File(image.path);
          });
        }
      } catch (e) {
        print('Error picking image: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    } else if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permission denied. Please grant storage access.'),
        ),
      );
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final geminiService = GeminiService(ApiConfig.geminiApiKey);

      final analysis = await geminiService.analyzeMedicalScan(
        imageFile: _selectedImage!,
        scanType: widget.scanType,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnalysisResultScreen(
              analysis: analysis,
              scanImage: _selectedImage!,
              scanType: widget.scanType,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  String _getScanTypeName() {
    switch (widget.scanType) {
      case ScanType.ct:
        return 'CT Scan';
      case ScanType.mri:
        return 'MRI';
      case ScanType.xray:
        return 'X-Ray';
      default:
        return 'Medical Scan';
    }
  }
}

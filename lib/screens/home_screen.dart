import 'package:flutter/material.dart';
import 'package:medscan/widgets/scan_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MedScan')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScanButton(
            title: 'CT Scan',
            scanType: ScanType.ct,
            icon: Icons.medical_services,
          ),
          ScanButton(
            title: 'MRI Scan',
            scanType: ScanType.mri,
            icon: Icons.scanner,
          ),
          ScanButton(
            title: 'X-Ray',
            scanType: ScanType.xray,
            icon: Icons.image,
          ),
        ],
      ),
    );
  }
}
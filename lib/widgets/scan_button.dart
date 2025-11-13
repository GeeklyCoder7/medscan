import 'package:flutter/material.dart';

import '../screens/image_selector_screen.dart';

enum ScanType { ct, mri, xray }

class ScanButton extends StatelessWidget {
  final String title;
  final ScanType scanType;
  final IconData icon;

  const ScanButton({
    Key? key,
    required this.title,
    required this.scanType,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageSelectorScreen(scanType: scanType),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _getButtonColor(),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getButtonColor() {
    switch (scanType) {
      case ScanType.ct:
        return Colors.blue;
      case ScanType.mri:
        return Colors.purple;
      case ScanType.xray:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

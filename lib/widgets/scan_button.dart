import 'package:flutter/material.dart';
import '../screens/image_selector_screen.dart';

enum ScanType { ct, mri, xray }

class ScanButton extends StatelessWidget {
  final String title;
  final String subtitle;  // Add subtitle parameter
  final ScanType scanType;
  final IconData icon;

  const ScanButton({
    super.key,
    required this.title,
    required this.subtitle,  // Make it required
    required this.scanType,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImageSelectorScreen(scanType: scanType),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getGradientColors(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _getButtonColor().withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, size: 35, color: Colors.white),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getButtonColor() {
    switch (scanType) {
      case ScanType.ct:
        return Color(0xFF6A1B9A);
      case ScanType.mri:
        return Color(0xFF00838F);
      case ScanType.xray:
        return Color(0xFFD84315);
    }
  }

  List<Color> _getGradientColors() {
    switch (scanType) {
      case ScanType.ct:
        return [Color(0xFF6A1B9A), Color(0xFF8E24AA)];
      case ScanType.mri:
        return [Color(0xFF00838F), Color(0xFF00ACC1)];
      case ScanType.xray:
        return [Color(0xFFD84315), Color(0xFFFF5722)];
    }
  }
}

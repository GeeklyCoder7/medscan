import 'dart:math';
import 'package:flutter/material.dart';
import 'package:medscan/widgets/scan_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'MedScan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
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
                  _buildHeroSection(),
                  SizedBox(height: 40),

                  Row(
                    children: [
                      Container(
                        height: 32,
                        width: 4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        Icons.dashboard_customize_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Select Scan Type',
                        style: TextStyle(
                          fontSize: 24,
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
                  ),

                  SizedBox(height: 20),

                  ScanButton(
                    title: 'CT Scan',
                    subtitle: 'Computed Tomography',
                    scanType: ScanType.ct,
                    icon: Icons.medical_services_rounded,
                  ),

                  SizedBox(height: 16),

                  ScanButton(
                    title: 'MRI Scan',
                    subtitle: 'Magnetic Resonance Imaging',
                    scanType: ScanType.mri,
                    icon: Icons.scanner_rounded,
                  ),

                  SizedBox(height: 16),

                  ScanButton(
                    title: 'X-Ray',
                    subtitle: 'Radiography Imaging',
                    scanType: ScanType.xray,
                    icon: Icons.healing_rounded,
                  ),

                  SizedBox(height: 30),
                  _buildInfoFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final offsetY = sin(_animationController.value * 2 * pi) * 5;

        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.health_and_safety_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI-Powered Analysis',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Instant medical scan insights',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Upload your medical scan images and receive detailed AI-powered analysis in seconds.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.95),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _buildSparkle(_animationController),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: _buildSparkle(
                  _animationController,
                  reverse: true,
                ),
              ),
              Positioned(
                top: 50,
                left: 30,
                child: _buildSparkle(
                  _animationController,
                  delay: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSparkle(AnimationController controller, {bool reverse = false, double delay = 0.0}) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double value = (controller.value + delay) % 1.0;
        if (reverse) value = 1.0 - value;

        return Opacity(
          opacity: (sin(value * 2 * pi) + 1) / 2,
          child: Transform.scale(
            scale: 0.5 + ((sin(value * 2 * pi) + 1) / 2) * 0.5,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.amber,
              size: 16,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoFooter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.white.withOpacity(0.9),
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'For educational purposes only. Consult healthcare professionals for medical advice.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

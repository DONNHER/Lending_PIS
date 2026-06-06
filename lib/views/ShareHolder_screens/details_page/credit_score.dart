import 'package:flutter/material.dart';
import 'dart:math' as math;

class CreditScoreScreen extends StatelessWidget {
  const CreditScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Credit Score",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // Credit Gauge Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 150,
                      width: 250,
                      child: CreditGauge(score: 720),
                    ),
                    const Text(
                      "720",
                      style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.black54, fontSize: 18),
                        children: [
                          TextSpan(text: "Your Score is "),
                          TextSpan(
                            text: "Good",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "What is Credit Score?",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "This is your trust score, used as a basis to determine the various activities you do on Credit Score.",
                      style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              const Text(
                "General",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              const Divider(),
              
              // Settings List
              _buildSettingItem(Icons.account_tree_outlined, "Account details"),
              _buildSettingItem(Icons.wallet_giftcard_outlined, "Receiving by email or phone"),
              _buildSettingItem(Icons.calendar_month_outlined, "Scheduled pay"),
              _buildSettingItem(Icons.settings_outlined, "Settings"),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.green, size: 20),
      onTap: () {},
    );
  }
}

// Custom Painter for the Arc Gauge
class CreditGauge extends StatelessWidget {
  final int score;
  const CreditGauge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GaugePainter(),
      child: const Stack(
        children: [
          Positioned(left: 0, bottom: 20, child: Text("300", style: TextStyle(color: Colors.grey))),
          Positioned(right: 0, bottom: 20, child: Text("850", style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw Background Arc (Gradient)
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    const gradient = SweepGradient(
      startAngle: math.pi,
      endAngle: 2 * math.pi,
      colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green],
    );

    paint.shader = gradient.createShader(rect);
    canvas.drawArc(rect, math.pi, math.pi, false, paint);

    // Draw Inner Dashed Arc
    final dashPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 20), math.pi, math.pi, false, dashPaint);

    // Draw Needle
    final needlePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Angle calculation for score 720 (approx 135 degrees from the left)
    const angle = math.pi + (math.pi * 0.75); 
    final needleEnd = Offset(
      center.dx + (radius - 40) * math.cos(angle),
      center.dy + (radius - 40) * math.sin(angle),
    );
    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 4, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
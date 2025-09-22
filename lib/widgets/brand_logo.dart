import 'package:flutter/material.dart';

class TrashitBrandMark extends StatelessWidget {
  final double height;
  final bool applyTheming;
  final Color? color;

  const TrashitBrandMark({super.key, this.height = 32, this.applyTheming = false, this.color});

  @override
  Widget build(BuildContext context) {
    final double size = height;

    if (applyTheming) {
      final scheme = Theme.of(context).colorScheme;
      final Color badgeColor = color ?? scheme.primary;
      return SizedBox(
        height: size,
        width: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(size * 0.22),
            border: Border.all(color: badgeColor, width: size * 0.06),
          ),
          child: Center(child: Icon(Icons.delete_outline, color: scheme.onSurface, size: size * 0.58)),
        ),
      );
    }

    return CustomPaint(size: Size(size, size), painter: _TrashitLogoPainter());
  }
}

class _TrashitLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final redFill = Paint()..color = const Color(0xFFE53935)..style = PaintingStyle.fill;
    final whiteFill = Paint()..color = Colors.white..style = PaintingStyle.fill..strokeWidth = 2.0;
    final whiteStroke = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round;

    // Red rounded square background
    final rect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(size.width * 0.15));
    canvas.drawRRect(rect, redFill);

    // Scale for the figure
    final double scale = size.width / 100;
    final double centerX = size.width * 0.5;
    final double centerY = size.height * 0.5;

    // Figure positioning
    final double figureSize = scale * 25;
    final double figureX = centerX - size.width * 0.15;
    final double figureY = centerY;

    // Head
    canvas.drawCircle(Offset(figureX, figureY - figureSize * 0.6), figureSize * 0.2, whiteFill);

    // Body
    canvas.drawLine(Offset(figureX, figureY - figureSize * 0.4), Offset(figureX, figureY + figureSize * 0.3), whiteStroke);

    // Legs
    canvas.drawLine(Offset(figureX, figureY + figureSize * 0.3), Offset(figureX - figureSize * 0.25, figureY + figureSize * 0.6), whiteStroke);
    canvas.drawLine(Offset(figureX, figureY + figureSize * 0.3), Offset(figureX + figureSize * 0.25, figureY + figureSize * 0.6), whiteStroke);

    // Arms
    canvas.drawLine(Offset(figureX, figureY - figureSize * 0.1), Offset(figureX + figureSize * 0.5, figureY - figureSize * 0.3), whiteStroke);
    canvas.drawLine(Offset(figureX, figureY), Offset(figureX - figureSize * 0.3, figureY + figureSize * 0.1), whiteStroke);

    // Trash bin
    final double binX = figureX + figureSize * 0.8;
    final double binY = figureY + figureSize * 0.1;
    final double binWidth = figureSize * 0.6;
    final double binHeight = figureSize * 0.7;
    final Path binPath = Path()
      ..moveTo(binX - binWidth * 0.4, binY)
      ..lineTo(binX + binWidth * 0.4, binY)
      ..lineTo(binX + binWidth * 0.3, binY + binHeight)
      ..lineTo(binX - binWidth * 0.3, binY + binHeight)
      ..close();
    canvas.drawPath(binPath, whiteStroke);
    canvas.drawLine(Offset(binX - binWidth * 0.5, binY), Offset(binX + binWidth * 0.5, binY), whiteStroke);

    // Trash piece being thrown
    final double trashX = figureX + figureSize * 0.6;
    final double trashY = figureY - figureSize * 0.4;
    final Path trashPath = Path()
      ..moveTo(trashX, trashY)
      ..lineTo(trashX + figureSize * 0.12, trashY + figureSize * 0.08)
      ..lineTo(trashX + figureSize * 0.08, trashY + figureSize * 0.2)
      ..lineTo(trashX - figureSize * 0.04, trashY + figureSize * 0.12)
      ..close();
    canvas.drawPath(trashPath, whiteFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TrashitCompleteLogo extends StatelessWidget {
  final double height;
  final bool applyTheming;
  final Color? color;

  const TrashitCompleteLogo({
    super.key,
    this.height = 36,
    this.applyTheming = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (applyTheming) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TrashitBrandMark(height: height, applyTheming: true, color: color),
          SizedBox(width: height * 0.2),
          TrashitWordmark(color: color, fontSize: height * 0.5),
        ],
      );
    }

    // Full branded logo with red background
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: height * 0.3,
        vertical: height * 0.15,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(height * 0.25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomPaint(
            size: Size(height * 0.7, height * 0.7),
            painter: _TrashitFigurePainter(),
          ),
          SizedBox(width: height * 0.15),
          Text(
            'trashit',
            style: TextStyle(
              fontSize: height * 0.45,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrashitFigurePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final whiteFill = Paint()..color = Colors.white..style = PaintingStyle.fill..strokeWidth = 2.0;
    final whiteStroke = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round;

    // Scale for the figure
    final double scale = size.width / 100;
    final double centerX = size.width * 0.5;
    final double centerY = size.height * 0.5;

    // Figure positioning
    final double figureSize = scale * 25;
    final double figureX = centerX - size.width * 0.15;
    final double figureY = centerY;

    // Head
    canvas.drawCircle(Offset(figureX, figureY - figureSize * 0.6), figureSize * 0.2, whiteFill);

    // Body
    canvas.drawLine(Offset(figureX, figureY - figureSize * 0.4), Offset(figureX, figureY + figureSize * 0.3), whiteStroke);

    // Legs
    canvas.drawLine(Offset(figureX, figureY + figureSize * 0.3), Offset(figureX - figureSize * 0.25, figureY + figureSize * 0.6), whiteStroke);
    canvas.drawLine(Offset(figureX, figureY + figureSize * 0.3), Offset(figureX + figureSize * 0.25, figureY + figureSize * 0.6), whiteStroke);

    // Arms
    canvas.drawLine(Offset(figureX, figureY - figureSize * 0.1), Offset(figureX + figureSize * 0.5, figureY - figureSize * 0.3), whiteStroke);
    canvas.drawLine(Offset(figureX, figureY), Offset(figureX - figureSize * 0.3, figureY + figureSize * 0.1), whiteStroke);

    // Trash bin
    final double binX = figureX + figureSize * 0.8;
    final double binY = figureY + figureSize * 0.1;
    final double binWidth = figureSize * 0.6;
    final double binHeight = figureSize * 0.7;
    final Path binPath = Path()
      ..moveTo(binX - binWidth * 0.4, binY)
      ..lineTo(binX + binWidth * 0.4, binY)
      ..lineTo(binX + binWidth * 0.3, binY + binHeight)
      ..lineTo(binX - binWidth * 0.3, binY + binHeight)
      ..close();
    canvas.drawPath(binPath, whiteStroke);
    canvas.drawLine(Offset(binX - binWidth * 0.5, binY), Offset(binX + binWidth * 0.5, binY), whiteStroke);

    // Trash piece being thrown
    final double trashX = figureX + figureSize * 0.6;
    final double trashY = figureY - figureSize * 0.4;
    final Path trashPath = Path()
      ..moveTo(trashX, trashY)
      ..lineTo(trashX + figureSize * 0.12, trashY + figureSize * 0.08)
      ..lineTo(trashX + figureSize * 0.08, trashY + figureSize * 0.2)
      ..lineTo(trashX - figureSize * 0.04, trashY + figureSize * 0.12)
      ..close();
    canvas.drawPath(trashPath, whiteFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TrashitWordmark extends StatelessWidget {
  final Color? color;
  final double fontSize;
  const TrashitWordmark({super.key, this.color, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return Text('trashit', maxLines: 1, overflow: TextOverflow.fade, style: TextStyle(fontSize: fontSize, color: c, fontWeight: FontWeight.bold, letterSpacing: 0.5));
  }
}

/// Clean, header-only logo: white figure + white wordmark on transparent background
/// Meant to be rendered on the red AppBar background for maximum clarity.
class TrashitHeaderLogo extends StatelessWidget {
  final double height;
  const TrashitHeaderLogo({super.key, this.height = 44});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: height * 0.9,
          height: height * 0.9,
          child: CustomPaint(
            size: Size.square(height * 0.9),
            painter: _TrashitHeaderIconPainter(),
          ),
        ),
        SizedBox(width: height * 0.18),
        Text(
          'trashit',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            height: 1.0,
            fontSize: height * 0.7,
          ),
        ),
      ],
    );
  }
}

class _TrashitHeaderIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final whiteFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final double w = size.width;
    final double h = size.height;

    // Create a professional stick figure similar to your image
    // Scale everything to be larger and more prominent
    
    // Head (circle)
    canvas.drawCircle(
      Offset(w * 0.25, h * 0.18), 
      w * 0.08, 
      whiteFill
    );

    // Body (torso)
    final bodyPath = Path()
      ..moveTo(w * 0.20, h * 0.26)
      ..lineTo(w * 0.30, h * 0.26)
      ..lineTo(w * 0.32, h * 0.50)
      ..lineTo(w * 0.18, h * 0.50)
      ..close();
    canvas.drawPath(bodyPath, whiteFill);

    // Left leg
    final leftLegPath = Path()
      ..moveTo(w * 0.18, h * 0.50)
      ..lineTo(w * 0.22, h * 0.50)
      ..lineTo(w * 0.16, h * 0.82)
      ..lineTo(w * 0.08, h * 0.82)
      ..close();
    canvas.drawPath(leftLegPath, whiteFill);

    // Right leg
    final rightLegPath = Path()
      ..moveTo(w * 0.28, h * 0.50)
      ..lineTo(w * 0.32, h * 0.50)
      ..lineTo(w * 0.42, h * 0.82)
      ..lineTo(w * 0.34, h * 0.82)
      ..close();
    canvas.drawPath(rightLegPath, whiteFill);

    // Right arm (throwing motion)
    final rightArmPath = Path()
      ..moveTo(w * 0.30, h * 0.30)
      ..lineTo(w * 0.70, h * 0.15)
      ..lineTo(w * 0.72, h * 0.22)
      ..lineTo(w * 0.32, h * 0.37)
      ..close();
    canvas.drawPath(rightArmPath, whiteFill);

    // Left arm
    final leftArmPath = Path()
      ..moveTo(w * 0.20, h * 0.30)
      ..lineTo(w * 0.12, h * 0.42)
      ..lineTo(w * 0.08, h * 0.38)
      ..lineTo(w * 0.18, h * 0.37)
      ..close();
    canvas.drawPath(leftArmPath, whiteFill);

    // Trash bin
    final binPath = Path()
      ..moveTo(w * 0.60, h * 0.45)
      ..lineTo(w * 0.90, h * 0.45)
      ..lineTo(w * 0.88, h * 0.80)
      ..lineTo(w * 0.62, h * 0.80)
      ..close();
    canvas.drawPath(binPath, whiteFill);

    // Bin lid
    final lidPath = Path()
      ..moveTo(w * 0.58, h * 0.42)
      ..lineTo(w * 0.92, h * 0.42)
      ..lineTo(w * 0.92, h * 0.48)
      ..lineTo(w * 0.58, h * 0.48)
      ..close();
    canvas.drawPath(lidPath, whiteFill);

    // Trash being thrown (diamond shape)
    final trashPath = Path()
      ..moveTo(w * 0.74, h * 0.22)
      ..lineTo(w * 0.78, h * 0.26)
      ..lineTo(w * 0.74, h * 0.30)
      ..lineTo(w * 0.70, h * 0.26)
      ..close();
    canvas.drawPath(trashPath, whiteFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// swim_charts.dart
// 추세 차트(막대+라인)와 심박 차트(영역+라인)를 CustomPainter로 구현.
// 외부 차트 패키지 의존 없음 — 디자인을 픽셀에 가깝게 재현.

import 'package:flutter/material.dart';
import '../models/swim_session.dart';

// ── 랩별 페이스(막대) + SWOLF(라인) ─────────────────────────────
class PaceTrendChart extends StatelessWidget {
  final List<SwimLap> laps;
  final List<Color> barColors; // 위→아래 그라데이션
  final Color swolfColor;
  final double height;

  const PaceTrendChart({
    super.key,
    required this.laps,
    required this.barColors,
    required this.swolfColor,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _PaceTrendPainter(laps, barColors, swolfColor),
      ),
    );
  }
}

class _PaceTrendPainter extends CustomPainter {
  final List<SwimLap> laps;
  final List<Color> barColors;
  final Color swolfColor;
  _PaceTrendPainter(this.laps, this.barColors, this.swolfColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (laps.isEmpty) return;
    final secs = laps.map((l) => l.seconds).toList();
    final sws = laps.map((l) => l.swolf.toDouble()).toList();
    final sMin = secs.reduce((a, b) => a < b ? a : b);
    final sMax = secs.reduce((a, b) => a > b ? a : b);
    final wMin = sws.reduce((a, b) => a < b ? a : b);
    final wMax = sws.reduce((a, b) => a > b ? a : b);

    const gap = 4.0;
    final slot = size.width / laps.length;
    final barW = (slot - gap).clamp(4.0, 13.0);
    const minBarH = 30.0;
    final maxBarH = size.height;

    // 막대
    for (var i = 0; i < laps.length; i++) {
      final t = sMax == sMin ? 0.5 : (secs[i] - sMin) / (sMax - sMin);
      final h = minBarH + t * (maxBarH - minBarH) * 0.68;
      final cx = slot * i + slot / 2;
      final rect = Rect.fromLTWH(cx - barW / 2, size.height - h, barW, h);
      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: barColors,
        ).createShader(rect);
      canvas.drawRRect(rrect, paint);
    }

    // SWOLF 라인
    final path = Path();
    for (var i = 0; i < laps.length; i++) {
      final t = wMax == wMin ? 0.5 : (sws[i] - wMin) / (wMax - wMin);
      final x = slot * i + slot / 2;
      final y = 16 + t * (size.height - 30);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = swolfColor,
    );
  }

  @override
  bool shouldRepaint(covariant _PaceTrendPainter old) =>
      old.laps != laps || old.swolfColor != swolfColor;
}

// ── 심박수 변화 (영역 + 라인) ───────────────────────────────────
class HeartRateChart extends StatelessWidget {
  final List<int> series; // 시간순 bpm
  final Color lineColor;
  final Color gridColor;
  final double height;

  const HeartRateChart({
    super.key,
    required this.series,
    required this.lineColor,
    required this.gridColor,
    this.height = 108,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _HeartRatePainter(series, lineColor, gridColor),
      ),
    );
  }
}

class _HeartRatePainter extends CustomPainter {
  final List<int> series;
  final Color lineColor;
  final Color gridColor;
  _HeartRatePainter(this.series, this.lineColor, this.gridColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (series.length < 2) return;
    final hMin = series.reduce((a, b) => a < b ? a : b) - 4;
    final hMax = series.reduce((a, b) => a > b ? a : b) + 4;
    const top = 10.0;
    final bot = size.height - 10;

    // 가로 그리드 3선
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final fy in [0.18, 0.5, 0.82]) {
      final y = size.height * fy;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    Offset pt(int i) {
      final x = i / (series.length - 1) * size.width;
      final t = (series[i] - hMin) / (hMax - hMin);
      final y = bot - t * (bot - top);
      return Offset(x, y);
    }

    final line = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < series.length; i++) {
      line.lineTo(pt(i).dx, pt(i).dy);
    }

    // 영역 채우기
    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.32),
            lineColor.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );

    // 라인
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = lineColor,
    );
  }

  @override
  bool shouldRepaint(covariant _HeartRatePainter old) =>
      old.series != series || old.lineColor != lineColor;
}

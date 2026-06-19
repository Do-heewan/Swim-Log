// swim_session_view.dart
// 추세 중심 리포트(시안 C) 본문. claude design 핸드오프를 실데이터(SwimSession)에 맞춰 이식.
// 라이트/다크는 Theme(SwimColors)로 자동 전환된다.
//
// 컨테이너(LatestSessionScreen)가 Scaffold·배경·새로고침을 제공하므로
// 이 위젯은 스크롤되는 카드 목록만 책임진다.
// 심박 시계열이 없으면 심박 카드를, 랩별 심박이 없으면 ♥ 열을 생략한다.

import 'package:flutter/material.dart';

import '../models/swim_session.dart';
import '../theme/swim_theme.dart';
import 'swim_charts.dart';

class SwimSessionView extends StatelessWidget {
  final SwimSession session;
  const SwimSessionView({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _InsightHeader(session: session),
        const SizedBox(height: 14),
        _PaceTrendCard(session: session),
        const SizedBox(height: 14),
        if (session.hasHeartRate) ...[
          _HeartRateCard(session: session),
          const SizedBox(height: 14),
        ],
        _SummaryGrid(session: session),
        const SizedBox(height: 14),
        _StrokeDistribution(session: session),
        const SizedBox(height: 14),
        _LapTable(session: session),
      ],
    );
  }
}

// ── 헤더 + 인사이트 히어로 ──────────────────────────────────────
class _InsightHeader extends StatelessWidget {
  final SwimSession session;
  const _InsightHeader({required this.session});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<SwimColors>()!;
    final hasFatigue = session.laps.length >= 10;
    final f = session.fatigue();
    final dropped = hasFatigue && f.paceDeltaSec > 3; // 후반 페이스가 유의미하게 처졌나
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_dateKo(session.startTime)} · 실내 ${session.poolLength}m',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.inkFaint,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.35,
                letterSpacing: -0.4,
                color: c.ink,
              ),
              children: dropped
                  ? [
                      const TextSpan(text: '초반은 좋았지만, '),
                      TextSpan(
                        text: '후반부에 무너졌어요.',
                        style: TextStyle(color: c.accent),
                      ),
                    ]
                  : [const TextSpan(text: '페이스를 끝까지 유지했어요. 👏')],
            ),
          ),
          const SizedBox(height: 6),
          if (hasFatigue)
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 13, height: 1.5, color: c.inkSub),
                children: [
                  const TextSpan(text: '마지막 5랩 평균 페이스가 초반보다 '),
                  TextSpan(
                    text: '${f.paceDeltaSec.abs()}초',
                    style: TextStyle(
                      color: c.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: f.paceDeltaSec >= 0
                        ? ' 느려지고 SWOLF가 '
                        : ' 빨라지고 SWOLF가 ',
                  ),
                  TextSpan(
                    text: '${f.swolfDelta.abs()}',
                    style: TextStyle(
                      color: c.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: f.swolfDelta >= 0 ? ' 올랐습니다.' : ' 내렸습니다.'),
                ],
              ),
            )
          else
            Text(
              '총 ${session.laps.length}랩 · ${session.totalDistance.round()}m 세션',
              style: TextStyle(fontSize: 13, height: 1.5, color: c.inkSub),
            ),
        ],
      ),
    );
  }
}

// ── 추세 히어로 카드 ────────────────────────────────────────────
class _PaceTrendCard extends StatelessWidget {
  final SwimSession session;
  const _PaceTrendCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<SwimColors>()!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: c.trendCard,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3A48).withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '랩별 페이스 & 효율',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFDFFAFE),
                ),
              ),
              Row(
                children: [
                  _legendDot(
                    const Color(0xFF4CD6E8),
                    '페이스',
                    const Color(0xFF7FE9F7),
                    false,
                  ),
                  const SizedBox(width: 12),
                  _legendDot(
                    c.swolfLine,
                    'SWOLF',
                    const Color(0xFFFF9576),
                    true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          PaceTrendChart(
            laps: session.laps,
            barColors: c.bar,
            swolfColor: c.swolfLine,
            height: 140,
          ),
          const SizedBox(height: 8),
          _axisRow(
            _lapAxisLabels(session.laps.length),
            const Color(0xFF6FB6C4),
          ),
        ],
      ),
    );
  }
}

/// 랩 수에 맞춘 x축 라벨 4개(대략 균등).
List<String> _lapAxisLabels(int n) {
  if (n <= 1) return ['랩 1'];
  if (n <= 4) return ['랩 1', for (var i = 2; i <= n; i++) '$i'];
  final m1 = ((n + 1) / 3).round();
  final m2 = ((n + 1) * 2 / 3).round();
  return ['랩 1', '$m1', '$m2', '$n'];
}

Widget _legendDot(Color dot, String label, Color textColor, bool isLine) {
  return Row(
    children: [
      Container(
        width: isLine ? 11 : 9,
        height: isLine ? 3 : 9,
        decoration: BoxDecoration(
          color: dot,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    ],
  );
}

Widget _axisRow(List<String> labels, Color color) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      for (final l in labels)
        Text(
          l,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
    ],
  );
}

// ── 심박수 변화 카드 (심박 데이터가 있을 때만 렌더) ───────────────
class _HeartRateCard extends StatelessWidget {
  final SwimSession session;
  const _HeartRateCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<SwimColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('❤️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 7),
                  Text(
                    '심박수 변화',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _stat(
                    '평균',
                    '${session.avgHeartRate ?? '-'}',
                    'bpm',
                    c.ink,
                    c,
                  ),
                  const SizedBox(width: 14),
                  _stat(
                    '최대',
                    '${session.maxHeartRate ?? '-'}',
                    'bpm',
                    c.heart,
                    c,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          HeartRateChart(
            series: session.heartRateSeries,
            lineColor: c.heart,
            gridColor: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFEEF3F4),
            height: 108,
          ),
        ],
      ),
    );
  }

  Widget _stat(
    String label,
    String value,
    String unit,
    Color valueColor,
    SwimColors c,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: c.inkSub,
          ),
        ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  fontFeatures: tabularFigures,
                ),
              ),
              TextSpan(
                text: unit,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: c.inkFaint,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 요약 컴팩트 그리드 ──────────────────────────────────────────
class _SummaryGrid extends StatelessWidget {
  final SwimSession session;
  const _SummaryGrid({required this.session});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<SwimColors>()!;
    final dist = session.totalDistance.round().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    );
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _metric('총거리', dist, 'm', c.ink, c)),
            const SizedBox(width: 10),
            Expanded(
              child: _metric(
                '순수 수영 / 경과',
                '${formatMmSs(session.activeTime)} / ${formatMmSs(session.elapsed)}',
                null,
                c.primary,
                c,
                splitUnit: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _metric(
                '평균 100m',
                formatPace(session.avgPacePer100Sec),
                null,
                c.accent,
                c,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metric('평균 SWOLF', '${session.avgSwolf}', null, c.ink, c),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metric(
    String label,
    String value,
    String? unit,
    Color valueColor,
    SwimColors c, {
    bool splitUnit = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 15),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.inkSub,
            ),
          ),
          const SizedBox(height: 2),
          if (splitUnit)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value.split(' / ')[0],
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: valueColor,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${value.split(' / ')[1]}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.inkFaint,
                    ),
                  ),
                ],
              ),
            )
          else
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: valueColor,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.inkSub,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── 영법 분포 ───────────────────────────────────────────────────
class _StrokeDistribution extends StatelessWidget {
  final SwimSession session;
  const _StrokeDistribution({required this.session});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<SwimColors>()!;
    final entries = session.strokeDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final segColors = [c.primary, c.stroke2, c.zoneHigh, c.zoneLow];
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '영법 분포',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: c.inkSub,
                ),
              ),
              Text(
                '랩 기준',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: c.inkFaint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Row(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0) const SizedBox(width: 2),
                  Expanded(
                    flex: (entries[i].value * 1000).round().clamp(1, 1000000),
                    child: Container(
                      height: 9,
                      color: segColors[i % segColors.length],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (var i = 0; i < entries.length; i++)
                Text(
                  '● ${entries[i].key.ko} ${(entries[i].value * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: segColors[i % segColors.length],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 랩별 스플릿 테이블 ──────────────────────────────────────────
class _LapTable extends StatelessWidget {
  final SwimSession session;
  const _LapTable({required this.session});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<SwimColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bestIdx = session.fastestLap?.index;
    // 랩별 심박은 SDK가 제공하지 않으므로, 실제로 값이 있을 때만 ♥ 열을 보인다.
    // (세션 심박 카드는 시계열 기반이라 별개로 표시된다.)
    final hasHr = session.laps.any((l) => l.avgHeartRate != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '랩별 스플릿',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              Text(
                '${session.poolLength}m · ${session.laps.length}랩',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: c.inkFaint,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            border: Border.all(color: c.cardBorder),
            borderRadius: BorderRadius.circular(18),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 9,
                  ),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0xFFF3F8F9),
                  child: _row(
                    ['랩', '영법', '시간', 'SWOLF', if (hasHr) '♥'],
                    isHeader: true,
                    c: c,
                    hasHr: hasHr,
                  ),
                ),
                for (final lap in session.laps)
                  _LapRow(
                    lap: lap,
                    isBest: lap.index == bestIdx,
                    hasHr: hasHr,
                    c: c,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(
    List<String> cols, {
    required bool isHeader,
    required SwimColors c,
    required bool hasHr,
  }) {
    final style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: c.inkFaint,
      letterSpacing: 0.3,
    );
    return Row(
      children: [
        SizedBox(width: 24, child: Text(cols[0], style: style)),
        const SizedBox(width: 10),
        Expanded(child: Text(cols[1], style: style)),
        SizedBox(
          width: 52,
          child: Text(cols[2], style: style, textAlign: TextAlign.right),
        ),
        SizedBox(
          width: 38,
          child: Text(cols[3], style: style, textAlign: TextAlign.right),
        ),
        if (hasHr)
          SizedBox(
            width: 30,
            child: Text(cols[4], style: style, textAlign: TextAlign.right),
          ),
      ],
    );
  }
}

class _LapRow extends StatelessWidget {
  final SwimLap lap;
  final bool isBest;
  final bool hasHr;
  final SwimColors c;
  const _LapRow({
    required this.lap,
    required this.isBest,
    required this.hasHr,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final isFree = lap.stroke == StrokeType.freestyle;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.cardBorder.withValues(alpha: 0.6)),
        ),
      ),
      child: Stack(
        children: [
          if (isBest)
            Positioned(
              left: 0,
              top: 8,
              bottom: 8,
              child: Container(width: 3, color: c.accent),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${lap.index}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: c.primary,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      _strokeBadge(lap.stroke, isFree ? c.primary : c.stroke2),
                      if (isBest) ...[
                        const SizedBox(width: 6),
                        _bestBadge(c.accent),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: 52,
                  child: Text(
                    formatMmSs(lap.time),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: c.ink,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ),
                SizedBox(
                  width: 38,
                  child: Text(
                    '${lap.swolf}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.inkSub,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ),
                if (hasHr)
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${lap.avgHeartRate ?? '-'}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.heart,
                        fontFeatures: tabularFigures,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _strokeBadge(StrokeType s, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        s.ko,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _bestBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text(
        'BEST',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── 공용 카드 셸 ────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<SwimColors>()!;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

String _dateKo(DateTime d) {
  final ampm = d.hour < 12 ? '오전' : '오후';
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '${d.year}년 ${d.month}월 ${d.day}일 · $ampm $h12:${d.minute.toString().padLeft(2, '0')}';
}

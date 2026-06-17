// swim_theme.dart
// 디자인 시스템 토큰을 Flutter ThemeExtension으로 옮긴 것 (claude design 핸드오프).
// 라이트/다크 두 인스턴스를 MaterialApp.theme / darkTheme 에 끼우면
// 모든 위젯이 Theme.of(context).extension<SwimColors>() 로 색을 읽습니다.

import 'package:flutter/material.dart';

@immutable
class SwimColors extends ThemeExtension<SwimColors> {
  // 표면
  final Color scaffold; // 화면 배경
  final Color card; // 카드 표면
  final Color cardBorder; // 카드 외곽선
  final Color cardSubtle; // 존 칩 등 옅은 표면

  // 텍스트
  final Color ink; // 본문 강조 (큰 숫자/제목)
  final Color inkSub; // 보조 텍스트
  final Color inkFaint; // 캡션/축 레이블

  // 브랜드 / 데이터 컬러
  final Color primary; // 아쿠아/시안 (순수 수영 시간, 랩 번호)
  final Color accent; // 코랄/오렌지 (페이스 강조)
  final Color swolfLine; // SWOLF 라인 (오렌지)
  final Color heart; // 심박 (레드/핑크)
  final Color stroke2; // 보조 영법 (접영, 퍼플)

  // 추세 히어로 카드 그라데이션
  final List<Color> trendCard;
  // 막대 그라데이션 (위→아래)
  final List<Color> bar;

  // 심박 존 4색
  final Color zoneLow;
  final Color zoneMid;
  final Color zoneHigh;
  final Color zoneMax;

  const SwimColors({
    required this.scaffold,
    required this.card,
    required this.cardBorder,
    required this.cardSubtle,
    required this.ink,
    required this.inkSub,
    required this.inkFaint,
    required this.primary,
    required this.accent,
    required this.swolfLine,
    required this.heart,
    required this.stroke2,
    required this.trendCard,
    required this.bar,
    required this.zoneLow,
    required this.zoneMid,
    required this.zoneHigh,
    required this.zoneMax,
  });

  static const light = SwimColors(
    scaffold: Color(0xFFEEF5F6),
    card: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE3EDEE),
    cardSubtle: Color(0xFFF6FAFA),
    ink: Color(0xFF0B2730),
    inkSub: Color(0xFF5D7178),
    inkFaint: Color(0xFF9BB0B6),
    primary: Color(0xFF0892A5),
    accent: Color(0xFFFF6B4A),
    swolfLine: Color(0xFFFF8A66),
    heart: Color(0xFFFF4D6D),
    stroke2: Color(0xFF6D4BD1),
    trendCard: [Color(0xFF0B3A48), Color(0xFF0F5E6E)],
    bar: [Color(0xFF6CF0FF), Color(0xFF1AA6C0)],
    zoneLow: Color(0xFF52B788),
    zoneMid: Color(0xFF1F9AAE),
    zoneHigh: Color(0xFFF4861F),
    zoneMax: Color(0xFFFF4D6D),
  );

  static const dark = SwimColors(
    scaffold: Color(0xFF071A24), // 그라데이션 베이스 (배경은 화면에서 그라데이션 처리)
    card: Color(0x0DFFFFFF), // rgba(255,255,255,0.05)
    cardBorder: Color(0x1F78DCEB), // rgba(120,220,235,0.12)
    cardSubtle: Color(0x0DFFFFFF),
    ink: Color(0xFFEEF9FB),
    inkSub: Color(0xFF8FB2BB),
    inkFaint: Color(0xFF6F969F),
    primary: Color(0xFF34E0F2),
    accent: Color(0xFFFF8A66),
    swolfLine: Color(0xFFFF8A66),
    heart: Color(0xFFFF5C7A),
    stroke2: Color(0xFFB69BFF),
    trendCard: [Color(0xFF0A3340), Color(0xFF0E525F)],
    bar: [Color(0xFF6CF0FF), Color(0xFF1AA6C0)],
    zoneLow: Color(0xFF5FE3A0),
    zoneMid: Color(0xFF34E0F2),
    zoneHigh: Color(0xFFFFB259),
    zoneMax: Color(0xFFFF5C7A),
  );

  /// 다크 모드 화면 배경 그라데이션 (Scaffold 대신 Container에 사용).
  static const darkScaffoldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF06202E), Color(0xFF08293A), Color(0xFF061A26)],
    stops: [0.0, 0.45, 1.0],
  );

  @override
  SwimColors copyWith() => this;

  @override
  SwimColors lerp(ThemeExtension<SwimColors>? other, double t) {
    if (other is! SwimColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    List<Color> cl(List<Color> a, List<Color> b) => [
      for (var i = 0; i < a.length; i++) c(a[i], b[i]),
    ];
    return SwimColors(
      scaffold: c(scaffold, other.scaffold),
      card: c(card, other.card),
      cardBorder: c(cardBorder, other.cardBorder),
      cardSubtle: c(cardSubtle, other.cardSubtle),
      ink: c(ink, other.ink),
      inkSub: c(inkSub, other.inkSub),
      inkFaint: c(inkFaint, other.inkFaint),
      primary: c(primary, other.primary),
      accent: c(accent, other.accent),
      swolfLine: c(swolfLine, other.swolfLine),
      heart: c(heart, other.heart),
      stroke2: c(stroke2, other.stroke2),
      trendCard: cl(trendCard, other.trendCard),
      bar: cl(bar, other.bar),
      zoneLow: c(zoneLow, other.zoneLow),
      zoneMid: c(zoneMid, other.zoneMid),
      zoneHigh: c(zoneHigh, other.zoneHigh),
      zoneMax: c(zoneMax, other.zoneMax),
    );
  }
}

/// tabular figures(고정폭 숫자) — 표·통계 숫자가 흔들리지 않게.
const tabularFigures = [FontFeature.tabularFigures()];

/// 앱 테마 헬퍼. Pretendard 폰트가 등록돼 있으면 사용, 없으면 시스템 폰트로 폴백.
class SwimTheme {
  static const _font = 'Pretendard';

  static ThemeData lightTheme() => _base(Brightness.light, SwimColors.light);
  static ThemeData darkTheme() => _base(Brightness.dark, SwimColors.dark);

  static ThemeData _base(Brightness b, SwimColors c) {
    final base = ThemeData(brightness: b, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: c.scaffold,
      extensions: [c],
      textTheme: base.textTheme.apply(
        fontFamily: _font,
        bodyColor: c.ink,
        displayColor: c.ink,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'debug/swim_bridge_dump.dart';
import 'features/session/latest_session_screen.dart';
import 'features/session/theme/swim_theme.dart';

/// `--dart-define=DUMP_SWIM=true`일 때만 브릿지 덤프를 실행(dev 전용, UI 영향 없음).
const _dumpBridge = bool.fromEnvironment('DUMP_SWIM');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (_dumpBridge) {
    dumpLatestPoolSwimming();
  }
  runApp(const SwimLogApp());
}

class SwimLogApp extends StatelessWidget {
  const SwimLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '수영 기록',
      debugShowCheckedModeBanner: false,
      theme: SwimTheme.lightTheme(),
      darkTheme: SwimTheme.darkTheme(),
      themeMode: ThemeMode.system, // 시스템 설정 따라 라이트/다크 자동 전환
      home: const LatestSessionScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/samsung_health/models/swimming_log.dart';
import '../../data/samsung_health/samsung_health_bridge.dart';
import 'models/swim_session.dart';
import 'theme/swim_theme.dart';
import 'widgets/swim_session_view.dart';

/// 가장 최근 POOL_SWIMMING 세션을 브릿지로 읽어 추세 리포트를 보여주는 첫 화면.
///
/// 실기기 + Samsung Health(개발자 모드) 에서만 실제 데이터가 들어온다.
/// 권한/없음/오류 상태를 모두 화면으로 처리하고, 로드 성공 시 디자인 본문을 그린다.
class LatestSessionScreen extends StatefulWidget {
  const LatestSessionScreen({super.key});

  @override
  State<LatestSessionScreen> createState() => _LatestSessionScreenState();
}

/// 화면이 가질 수 있는 상태.
enum _Status { loading, denied, empty, error, loaded }

class _LatestSessionScreenState extends State<LatestSessionScreen> {
  static const _bridge = SamsungHealthBridge();

  _Status _status = _Status.loading;
  SwimmingLog? _log;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _status = _Status.loading;
      _errorMessage = null;
    });

    try {
      final granted = await _bridge.requestExercisePermission();
      if (!mounted) return;
      if (!granted) {
        setState(() => _status = _Status.denied);
        return;
      }

      final log = await _bridge.getLatestPoolSwimming();
      if (!mounted) return;
      setState(() {
        if (log == null) {
          _status = _Status.empty;
        } else {
          _log = log;
          _status = _Status.loaded;
        }
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _Status.error;
        _errorMessage = '[${e.code}] ${e.message ?? '알 수 없는 오류'}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _Status.error;
        _errorMessage = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = Theme.of(context).extension<SwimColors>()!;

    final scaffold = Scaffold(
      backgroundColor: isDark ? Colors.transparent : c.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: c.ink,
        title: const Text(
          '최근 수영',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _status == _Status.loading ? null : _load,
            icon: Icon(Icons.refresh, color: c.primary),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: SafeArea(top: false, child: _buildBody(c)),
    );

    if (isDark) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: SwimColors.darkScaffoldGradient,
        ),
        child: scaffold,
      );
    }
    return scaffold;
  }

  Widget _buildBody(SwimColors c) {
    switch (_status) {
      case _Status.loading:
        return Center(child: CircularProgressIndicator(color: c.primary));

      case _Status.denied:
        return _MessageState(
          icon: Icons.lock_outline,
          title: '권한이 필요합니다',
          message:
              'Samsung Health 운동 기록 읽기 권한을 허용해야 합니다.\n'
              '개발자 모드가 켜져 있는지 확인 후 다시 시도하세요.',
          onRetry: _load,
          c: c,
        );

      case _Status.empty:
        return _MessageState(
          icon: Icons.pool_outlined,
          title: '수영 기록이 없습니다',
          message: '최근 기간 내 POOL_SWIMMING 세션을 찾지 못했습니다.',
          onRetry: _load,
          c: c,
        );

      case _Status.error:
        return _MessageState(
          icon: Icons.error_outline,
          title: '불러오기 실패',
          message: _errorMessage ?? '알 수 없는 오류가 발생했습니다.',
          onRetry: _load,
          c: c,
        );

      case _Status.loaded:
        return RefreshIndicator(
          onRefresh: _load,
          child: SwimSessionView(session: SwimSession.fromSwimmingLog(_log!)),
        );
    }
  }
}

/// 비어있음/권한/오류 등 안내 + 다시 시도 버튼을 가진 공통 상태 화면.
class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
    required this.c,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;
  final SwimColors c;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: c.inkFaint),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: c.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 13, height: 1.5, color: c.inkSub),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

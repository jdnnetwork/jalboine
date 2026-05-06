import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 외부에서 들어온 jalboine.app/connect?code=XXXXXX 같은 링크를 잡아서
/// SharedPreferences에 보관. 첫 화면에서 이 값을 보고 자동 페어링.
class DeepLinkService {
  DeepLinkService._();
  static final instance = DeepLinkService._();

  static const _kPendingCode = 'jalboine.pending_pair_code';

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  String? _initialCode;

  Future<void> init() async {
    try {
      final initial = await _appLinks.getInitialLink();
      _initialCode = _extractCode(initial);
      if (_initialCode != null) {
        await _save(_initialCode!);
      }
      _sub ??= _appLinks.uriLinkStream.listen((uri) async {
        final code = _extractCode(uri);
        if (code != null) await _save(code);
      }, onError: (_) {});
    } catch (_) {
      // 디바이스/플러그인 미지원 시 무시
    }
  }

  String? _extractCode(Uri? uri) {
    if (uri == null) return null;
    if (uri.host != 'jalboine.app') return null;
    if (!uri.path.contains('connect')) return null;
    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) return null;
    return code;
  }

  Future<void> _save(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPendingCode, code);
  }

  Future<String?> takePendingCode() async {
    final prefs = await SharedPreferences.getInstance();
    final c = prefs.getString(_kPendingCode);
    if (c != null) {
      await prefs.remove(_kPendingCode);
    }
    return c;
  }

  Future<void> dispose() async {
    await _sub?.cancel();
  }
}

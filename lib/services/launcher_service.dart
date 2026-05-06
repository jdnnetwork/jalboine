import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';

class LauncherService {
  static Future<void> launchApp(String key) async {
    try {
      switch (key) {
        case 'phone':
          await launchUrl(Uri.parse('tel:'));
          break;
        case 'message':
          await launchUrl(Uri.parse('sms:'));
          break;
        case 'kakaotalk':
          await _launchPackageOrStore('com.kakao.talk');
          break;
        case 'youtube':
          await _launchPackageOrStore('com.google.android.youtube');
          break;
        case 'camera':
          await const AndroidIntent(
            action: 'android.media.action.IMAGE_CAPTURE',
          ).launch();
          break;
        case 'gallery':
          await const AndroidIntent(
            action: 'android.intent.action.VIEW',
            type: 'image/*',
          ).launch();
          break;
      }
    } catch (_) {
      // 실패 시 무시
    }
  }

  static Future<void> _launchPackageOrStore(String pkg) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.MAIN',
      category: 'android.intent.category.LAUNCHER',
      package: pkg,
    );
    final installed = (await intent.canResolveActivity()) ?? false;
    if (installed) {
      try {
        await intent.launch();
        return;
      } catch (_) {
        // 실행 실패 시 Play Store로 폴백
      }
    }
    await launchUrl(
      Uri.parse('https://play.google.com/store/apps/details?id=$pkg'),
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<void> dial(String number) =>
      launchUrl(Uri.parse('tel:$number'));
}

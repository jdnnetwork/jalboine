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
        case 'kakao':
          await const AndroidIntent(
            action: 'action_main',
            package: 'com.kakao.talk',
          ).launch();
          break;
        case 'youtube':
          await const AndroidIntent(
            action: 'action_main',
            package: 'com.google.android.youtube',
          ).launch();
          break;
        case 'camera':
          await const AndroidIntent(
            action: 'android.media.action.IMAGE_CAPTURE',
          ).launch();
          break;
        case 'album':
          await const AndroidIntent(
            action: 'android.intent.action.VIEW',
            type: 'image/*',
          ).launch();
          break;
      }
    } catch (_) {
      // 앱 미설치 등 실패 시 무시
    }
  }

  static Future<void> dial(String number) =>
      launchUrl(Uri.parse('tel:$number'));
}

import 'package:lumi/core/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherUtils {
  UrlLauncherUtils._();

  static Future<void> launchWebUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        AppLogger.e('无法开启传送：$url');
      }
    } catch (e) {
      AppLogger.e('传送失败：$e');
    }
  }
}

import 'package:engine/utils/url/url.dart';
import 'package:url_launcher/url_launcher.dart';

class TypedUrlOpener implements AbstractTypedUrlOpener {
  @override
  Future<void> open(String url) async {
    await launchUrl(Uri.parse(url));
  }
}

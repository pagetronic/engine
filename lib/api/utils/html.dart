import 'package:html_unescape/html_unescape.dart';

class HtmlEscaper {
  static final HtmlUnescape htmlUnescape = HtmlUnescape();

  static String unescape(String? html) {
    return htmlUnescape.convert(html ?? "");
  }
}

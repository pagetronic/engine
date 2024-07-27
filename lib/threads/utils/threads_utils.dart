import 'package:engine/api/utils/html.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PostParser {
  static TextSpan parse(BuildContext context, String? text) {
    String textUnescape = HtmlEscaper.unescape(text ?? '');
    RegExp tags = RegExp(r'([@#][^ .,]+)');
    RegExp links = RegExp(r'\[url=([^\]]+)\](.+?)\[/url\]');
    RegExp photos = RegExp(r'\[Photos\(([^)]+)\)[^\]]+\]');
    List<String> matches = textUnescape.multiSplit([tags, links, photos]);

    List<TextSpan> spans = [];
    for (String match in matches) {
      if (tags.hasMatch(match)) {
        Match m = tags.matchAsPrefix(match)!;
        String tag = m.group(1)!;
        spans.add(
          TextSpan(
            text: m.group(0),
            mouseCursor: SystemMouseCursors.click,
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                if (match.startsWith("@")) {
                  Navigator.pushNamed(context, "/users/${tag.substring(1)}");
                }
                if (match.startsWith("#")) {
                  Navigator.pushNamed(context, "/search?q=${Uri.encodeComponent(tag.substring(1))}");
                }
              },
          ),
        );
      } else if (links.hasMatch(match)) {
        Match m = links.matchAsPrefix(match)!;
        String url = m.group(1)!;
        String anchor = m.group(2)!;
        spans.add(
          TextSpan(
            text: anchor,
            mouseCursor: SystemMouseCursors.click,
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => url.startsWith("http") ? launchUrl(Uri.parse(url)) : Navigator.pushNamed(context, url),
          ),
        );
      } else if (photos.hasMatch(match)) {
        // spans.add(WidgetSpan(child: child))
      } else {
        spans.add(TextSpan(text: match));
      }
    }
    return TextSpan(children: spans);
  }
}

extension StringMultiSpliter on String {
  List<String> multiSplit(Iterable<RegExp> delimiters) {
    if (delimiters.isEmpty) return [this];
    if (delimiters.length == 1) return splitWithDelimiter(delimiters.first);

    final next = delimiters.skip(1);
    return splitWithDelimiter(delimiters.first).expand((i) => i.multiSplit(next)).toList();
  }

  List<String> allMatchesWithSep(String input, [int start = 0]) {
    var result = <String>[];
    for (var match in allMatches(input, start)) {
      result.add(input.substring(start, match.start));
      result.add(match[0]!);
      start = match.end;
    }
    result.add(input.substring(start));
    return result;
  }

  List<String> splitWithDelimiter(RegExp pattern) => pattern.allMatchesWithSep(this);
}

extension RegExpExtension on RegExp {
  List<String> allMatchesWithSep(String input, [int start = 0]) {
    var result = <String>[];
    for (var match in allMatches(input, start)) {
      result.add(input.substring(start, match.start));
      result.add(match[0]!);
      start = match.end;
    }
    result.add(input.substring(start));
    return result;
  }
}

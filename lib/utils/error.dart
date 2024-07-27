import 'package:engine/lng/language.dart';
import 'package:engine/utils/platform/views.dart';
import 'package:engine/utils/text.dart';
import 'package:flutter/widgets.dart';

class NotFoundView extends StatelessWidget {
  const NotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseView(children: [H1(Language.of(context).route_not_found)]);
  }
}

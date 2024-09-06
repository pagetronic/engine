import 'package:engine/api/utils/json.dart';
import 'package:engine/api/utils/settings.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/utils/actions.dart';
import 'package:engine/utils/base.dart';
import 'package:engine/utils/fx.dart';
import 'package:engine/utils/platform/menu.dart';
import 'package:engine/utils/platform/views.dart';
import 'package:engine/utils/text.dart';
import 'package:engine/utils/widgets/form.dart';
import 'package:engine/utils/widgets/form/share_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

export 'package:engine/utils/widgets/form.dart';
export 'package:engine/utils/widgets/form/share_picker.dart';

abstract class FormRoute<T extends StatefulWidget> extends BaseRoute<T> {
  final ValueNotifierJson _data = ValueNotifierJson(Json());
  final ValueStore<bool> _changed = ValueStore<bool>(false);

  final ScrollController scrollController = ScrollController();

  final List<Widget> inputs = [];

  void save();

  void setValue(String key, dynamic value) {
    if (value is String && value == '') {
      value = null;
    }
    Json data = _data.value!;
    if (data[key] != value) {
      data[key] = value;
      _data.value = data;
      this._changed.value = true;
    }
  }

  Json getValue() {
    return _data.value!..update = DateTime.now();
  }

  void setValueLocker(String key, dynamic value) {
    Json data = _data.value!;
    if (data[key] != value) {
      data[key] = value;
      _data.value = data;
    }
  }

  Input addInput(String? initial, String title, void Function(String) onChange,
      {String? explains, bool obscureText = false, Widget? icon}) {
    Input input = Input(title, obscureText: obscureText, icon: icon);
    input.controller.text = initial ?? '';

    input.controller.addListener(() => onChange(input.controller.value.text.trim()));
    if (explains != null) {
      inputs.add(Explain(input, explains, maxWidth: Settings.maxWidth));
    } else {
      inputs.add(input);
    }

    return input;
  }

  addArea(String? initial, String title, void Function(String) onChange, {required explains}) {
    Area input = Area(title);
    input.controller.text = initial ?? '';
    input.controller.addListener(() => onChange(input.controller.value.text.trim()));

    if (explains != null) {
      inputs.add(Explain(input, explains, maxWidth: Settings.maxWidth));
    } else {
      inputs.add(input);
    }
    return input;
  }

  void addDate(DateTime? initial, String title, void Function(DateTime) onChange, {String? explains}) {
    DateFormat dateFormat = DateFormat.yMd(Language.of(context).localeName);
    DateInput date = DateInput(title);

    date.controller.text = initial != null && !initial.isAtSameMomentAs(DateTime.utc(0))
        ? dateFormat.format(initial)
        : dateFormat.format(DateTime.now());
    date.controller.addListener(() => onChange(dateFormat.parseUtc(date.controller.text)));
    if (explains != null) {
      inputs.add(Explain(date, explains, maxWidth: Settings.maxWidth));
    } else {
      inputs.add(date);
    }
  }

  Select<T> addSelect<T>({required Map<T, String> options, required String label, String? initial, String? explains}) {
    Select<T> select = Select(options: options, initial: initial, label: label);
    if (explains != null) {
      inputs.add(Explain(select, explains, maxWidth: Settings.maxWidth));
    } else {
      inputs.add(Expanded(child: select));
    }
    return select;
  }

  void addShareBox(List? share, String infos,
      {String? explains, required void Function(List<String>? share) onChanged}) {
    ShareBox locker = ShareBox(
      share: share == null ? null : List<String>.from(share.map((entry) => entry as String)),
      infos: infos,
      onChanged: onChanged,
    );
    if (explains != null) {
      inputs.add(Explain(locker, explains, maxWidth: Settings.maxWidth));
    } else {
      inputs.add(Expanded(child: locker));
    }
  }

  void addWidget(Widget widget, {String? explains, double? verticalSpacing}) {
    if (explains != null) {
      if (verticalSpacing != null) {
        inputs.add(Explain(widget, explains, maxWidth: Settings.maxWidth, verticalSpacing: verticalSpacing));
      } else {
        inputs.add(Explain(widget, explains, maxWidth: Settings.maxWidth));
      }
    } else {
      inputs.add(widget);
    }
  }

  void addDivider({key, height, thickness, indent, endIndent, color, double? paddingTop, double? paddingBottom}) {
    inputs.add(
      Container(
        margin: EdgeInsets.only(top: paddingTop ?? 30, bottom: paddingBottom ?? 30),
        child: Divider(
          key: key,
          height: height,
          thickness: thickness,
          indent: indent,
          endIndent: endIndent,
          color: color,
        ),
      ),
    );
  }

  void addSpace({double? height}) {
    inputs.add(SizedBox(height: height));
  }

  void addTitle(String title) {
    addWidget(H1(title));
  }

  @override
  Future<void> beforeLoad(AppLocalizations locale) async {
    inputs.clear();
    await super.beforeLoad(locale);
  }

  @override
  Widget getBody() {
    if (inputs.isEmpty) {
      makeForm();
    }
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            onPop();
          }
        },
        child: BaseView(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 30, top: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: inputs),
            )
          ],
        ));
  }

  void makeForm();

  void onPop() {
    if (!_changed.value) {
      Navigator.pop(context);
      return;
    }
    ActionsUtils.confirm(
      context,
      title: Language.of(context).save_modifications,
    ).then((value) async {
      if (value == ActionsType.yes) {
        if (mounted) {
          save();
        }
      } else if (value == ActionsType.no) {
        if (mounted) {
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  List<GlobalMenuItem> getBaseMenu([String? active]) {
    return [];
  }
}

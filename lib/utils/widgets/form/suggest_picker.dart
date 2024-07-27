import 'package:engine/api/api.dart';
import 'package:engine/blobs/images.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/utils/defer.dart';
import 'package:engine/utils/lists/lists_api.dart';
import 'package:engine/utils/lists/lists_utils.dart';
import 'package:engine/utils/platform/load.dart';
import 'package:engine/utils/widgets/form/color_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class UsersPicker extends StatelessWidget {
  final void Function(List<Json> users) onSelect;
  final List<Json> users;

  const UsersPicker({super.key, required this.onSelect, required this.users});

  @override
  Widget build(BuildContext context) {
    Notifier notifier = Notifier();
    itemBuilder(BuildContext context, Json user, int index) {
      return InkWell(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user['avatar'] != null) ImageWidget.json(user['avatar'], format: ImageFormat.png36x36),
              if (user['avatar'] == null) const Icon(Icons.person, size: 36, color: Colors.grey),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'],
                      softWrap: true,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      (user['idn'] ?? user.id) + (user['email'] != null ? " > ${user['email']}" : ""),
                      softWrap: true,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              SuggestPick(
                  active: users.where((element) => element.id == user.id).isNotEmpty,
                  onSelect: () {
                    if (users.where((element) => element.id == user.id).isNotEmpty) {
                      users.removeWhere((element) => element.id == user.id);
                      onSelect(users);
                    } else {
                      users.add(user);
                    }
                    onSelect(users);
                    notifier.notify();
                  })
            ],
          ),
        ),
      );
    }

    return SuggestPicker(
        notifier: notifier,
        decoration:
            InputDecoration(suffixIcon: const Icon(Icons.person_add_alt), hintText: Language.of(context).share_users),
        request: (String? search, String? paging) async {
          return Result(await Api.post("/users", Json({"action": "search", "search": search, "paging": paging})));
        },
        onSelect: onSelect,
        header: () {
          if (users.isNotEmpty) {
            return Material(
                elevation: 2,
                child: Column(children: [
                  for (int index = 0; index < users.length; index++)
                    Container(
                      decoration: StyleListView.getOddEvenBoxDecoration(index + 1 - users.length % 2),
                      child: itemBuilder(context, users[index], index),
                    ),
                ]));
          }
          return const SizedBox.shrink();
        },
        itemBuilder: itemBuilder);
  }
}

class SuggestPicker extends StatelessWidget {
  final bool autocorrect;
  final InputDecoration? decoration;
  final void Function(List<Json> items) onSelect;
  final String tag = const Uuid().v1();
  final Future<Result?> Function(String? search, String? paging) request;
  final Widget Function(BuildContext context, Json item, int index) itemBuilder;
  final Widget Function()? header;
  final Notifier? notifier;

  SuggestPicker(
      {super.key,
      required this.request,
      required this.itemBuilder,
      required this.onSelect,
      this.autocorrect = true,
      this.decoration,
      this.notifier,
      this.header});

  @override
  Widget build(BuildContext context) {
    Widget fake = Listener(
      onPointerDown: (_) {
        Navigator.of(context).push(
          PageRouteBuilder<void>(
            opaque: false,
            fullscreenDialog: true,
            maintainState: true,
            pageBuilder: (context, animation, secondaryAnimation) {
              return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return SuggestPickerSearch(
                        tag: tag, header: header, notifier: notifier, request: request, itemBuilder: itemBuilder);
                  });
            },
          ),
        );
      },
      child: AbsorbPointer(
        child: TextField(
          decoration: decoration ??
              InputDecoration(suffixIcon: const Icon(Icons.search), hintText: Language.of(context).search),
        ),
      ),
    );

    return Hero(tag: tag, child: Material(child: fake));
  }
}

class SuggestPick extends StatelessWidget {
  final bool active;
  final void Function() onSelect;

  const SuggestPick({super.key, required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(active ? Icons.close : Icons.check),
        ),
      ),
    );
  }
}

class SuggestPickerSearch extends StatefulWidget {
  final Future<Result?> Function(String? search, String? paging) request;
  final Widget Function(BuildContext context, Json item, int index) itemBuilder;
  final String tag;
  final Notifier? notifier;
  final Widget Function()? header;
  final ScrollController controller = ScrollController();

  SuggestPickerSearch(
      {super.key,
      required this.tag,
      required this.header,
      required this.request,
      required this.itemBuilder,
      this.notifier});

  @override
  State<StatefulWidget> createState() {
    return SuggestPickerSearchState();
  }
}

class SuggestPickerSearchState extends State<SuggestPickerSearch> {
  String query = "";
  final Deferrer deferrer = Deferrer(700);
  final TextEditingController controller = TextEditingController();
  final FocusNode focus = FocusNode(canRequestFocus: true);

  @override
  Widget build(BuildContext context) {
    return SearchFold(
      controller: controller,
      body: ApiListView(
        controller: widget.controller,
        header: widget.header == null ? null : widget.header!(),
        padding: const EdgeInsets.symmetric(vertical: 5),
        request: (String? paging) {
          if (paging == null) {
            focus.requestFocus();
          }
          return widget.request(query, paging);
        },
        getView: widget.itemBuilder,
      ),
      tag: widget.tag,
    );
  }

  void setQuery() {
    deferrer.defer(() {
      if (query != controller.text) {
        setState(() {
          query = controller.text;
        });
      }
    });
  }

  void refresh() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(setQuery);
    widget.notifier?.addListener(refresh);
  }

  @override
  void dispose() {
    controller.removeListener(setQuery);
    widget.notifier?.removeListener(refresh);
    super.dispose();
  }
}

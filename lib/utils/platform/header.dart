import 'package:engine/lng/language.dart';
import 'package:engine/notices/notices.dart';
import 'package:engine/utils/platform/load.dart';
import 'package:engine/utils/tabs.dart';
import 'package:flutter/material.dart';

class Header extends StatefulWidget implements PreferredSizeWidget {
  final TabStore? tabs;
  final String? title;
  final Color? color;
  final List<Widget>? actionsButtons;
  final List<ActionMenuItem>? actionsMenu;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final String? search;

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  const Header(
      {super.key,
      this.tabs,
      this.search,
      this.title,
      this.actionsButtons,
      this.actionsMenu,
      this.color,
      this.leading,
      this.automaticallyImplyLeading = false});

  @override
  StateHeader createState() => StateHeader();
}

class StateHeader extends State<Header> {
  Widget? header;

  @override
  Widget build(BuildContext context) {
    final List<Widget> actions = [];
    actions.addAll(widget.actionsButtons ?? []);
    if (widget.search != null) {
      actions.add(IconButton(
        onPressed: () => Navigator.of(context).pushNamed(widget.search!),
        icon: const Icon(Icons.search),
      ));
    }
    if (!NoticesView.isNoticesView(context)) {
      actions.add(const NoticesButton());
    }

    if ((widget.actionsMenu ?? []).isNotEmpty) {
      PopupMenuButton popupMenu = PopupMenuButton<Function>(
        itemBuilder: (BuildContext context) => widget.actionsMenu ?? [],
        onSelected: (Function func) {
          func();
        },
      );
      actions.add(popupMenu);
    }

    Widget title = Theme(
      data: ThemeData(
        textSelectionTheme: const TextSelectionThemeData(
          selectionColor: Colors.grey,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          maxLines: 1,
          widget.title ?? "",
          scrollPhysics: const NeverScrollableScrollPhysics(),
          style: const TextStyle(
            overflow: TextOverflow.ellipsis,
            color: Colors.white,
          ),
        ),
      ),
    );
    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Theme.of(context).shadowColor, blurRadius: 2, offset: const Offset(0, 1))],
        ),
        child: AppBar(
          titleSpacing: 0,
          leadingWidth: !widget.automaticallyImplyLeading ? kToolbarHeight - 12 : null,
          leading: !widget.automaticallyImplyLeading
              ? Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 12, left: 5),
                  child: Image.asset("assets/images/logo.png", width: kToolbarHeight))
              : widget.leading,
          automaticallyImplyLeading: widget.automaticallyImplyLeading,
          iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
          backgroundColor: widget.color ?? Theme.of(context).colorScheme.primary,
          title: title,
          actions: actions,
        ),
      ),
    );
  }
}

class SearchFoldHead extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final BorderRadiusGeometry? borderRadius;
  final Object? tag;

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  const SearchFoldHead(this.controller, this.tag, {this.borderRadius, super.key});

  @override
  Widget build(BuildContext context) {
    AppBar appBar = AppBar(
      clipBehavior: Clip.antiAlias,
      titleSpacing: 0,
      iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
      backgroundColor: Theme.of(context).colorScheme.primary,
      title: TextField(
        autofocus: true,
        cursorColor: Colors.white,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          border: InputBorder.none,
          suffixIcon: const Icon(Icons.search, color: Colors.white),
          hintText: Language.of(context).search,
          hintStyle: TextStyle(
            color: Colors.grey[400],
          ),
        ),
        controller: controller,
      ),
    );
    return Material(clipBehavior: Clip.hardEdge, borderRadius: borderRadius, elevation: 5, child: appBar);
  }
}

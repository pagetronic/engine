import 'package:flutter/material.dart';

class BottomNavigation extends StatefulWidget {
  final List<BottomNavigationButton> children;
  final ValueNotifier<bool> _show = ValueNotifier(false);

  BottomNavigation({required this.children, super.key});

  @override
  State<StatefulWidget> createState() {
    return BottomNavigationState();
  }

  void show(bool isShow) {
    _show.value = isShow;
  }
}

class BottomNavigationState extends State<BottomNavigation> {
  static const double height = 60;
  double hideHeight = 60;

  BottomNavigationState();

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(0),
      height: hideHeight,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Theme.of(context).shadowColor, blurRadius: 2, offset: const Offset(0, -1))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: BottomAppBar(
                height: height,
                padding: const EdgeInsets.all(0),
                color: Theme.of(context).colorScheme.secondary,
                shape: const CircularNotchedRectangle(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: widget.children,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void hide() {
    setState(() {
      hideHeight = widget._show.value ? height : 0;
    });
  }

  @override
  void initState() {
    super.initState();
    widget._show.addListener(hide);
  }

  @override
  void dispose() {
    widget._show.removeListener(hide);
    super.dispose();
  }
}

class BottomNavigationButton extends StatelessWidget {
  final IconData icon;
  final void Function() onSelect;
  final String? title;

  const BottomNavigationButton({super.key, required this.icon, required this.onSelect, this.title});

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    children.add(Icon(
      icon,
      color: Colors.white,
      size: 32,
    ));
    if (title != null) {
      children.add(
        Text(
          title!,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      );
    }
    return InkWell(
      onTap: () => onSelect(),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(top: 3, bottom: 5, left: 5, right: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: children,
          ),
        ),
      ),
    );
  }
}

class BigActionButton extends StatelessWidget {
  final void Function() onPressed;
  final String? tooltip;
  final Icon? child;

  const BigActionButton({super.key, required this.onPressed, this.tooltip, this.child = const Icon(Icons.add)});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(100))),
      child: child ?? const Icon(Icons.add),
    );
  }
}

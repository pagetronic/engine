import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContextMenuRegion extends StatefulWidget {
  final Widget child;
  final List<ContextMenuAction> buttonItems;

  const ContextMenuRegion({super.key, required this.buttonItems, required this.child});

  @override
  State<ContextMenuRegion> createState() => ContextMenuRegionState();
}

class ContextMenuRegionState extends State<ContextMenuRegion> {
  final MenuController _menuController = MenuController();
  bool _menuWasEnabled = false;

  Color get backgroundColor => _backgroundColor;
  Color _backgroundColor = Colors.red;

  set backgroundColor(Color value) {
    if (_backgroundColor != value) {
      setState(() {
        _backgroundColor = value;
      });
    }
  }

  bool get showingMessage => _showingMessage;
  bool _showingMessage = false;

  set showingMessage(bool value) {
    if (_showingMessage != value) {
      setState(() {
        _showingMessage = value;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _disableContextMenu();
  }

  Future<void> _disableContextMenu() async {
    if (!kIsWeb) {
      // Does nothing on non-web platforms.
      return;
    }
    _menuWasEnabled = BrowserContextMenu.enabled;
    if (_menuWasEnabled) {
      await BrowserContextMenu.disableContextMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onSecondaryTapDown: _handleSecondaryTapDown,
      child: MenuAnchor(
        controller: _menuController,
        consumeOutsideTap: true,
        menuChildren: [
          for (ContextMenuAction action in widget.buttonItems)
            MenuItemButton(
              onPressed: action.onPressed,
              child: Row(
                children: [
                  Icon(action.icon),
                  const SizedBox(width: 5),
                  Text(action.label),
                ],
              ),
            ),
        ],
        child: widget.child,
      ),
    );
  }

  void _handleSecondaryTapDown(TapDownDetails details) {
    _menuController.open(position: details.localPosition);
  }

  void _handleTapDown(TapDownDetails details) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        if (HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
            HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight)) {
          _menuController.open(position: details.localPosition);
        }
    }
  }
}

class ContextMenuAction {
  final void Function() onPressed;
  final IconData icon;
  final String label;

  ContextMenuAction({required this.label, required this.icon, required this.onPressed});
}

import 'package:engine/utils/fx.dart';
import 'package:flutter/material.dart';

class DialogModal extends StatelessWidget {
  final ValueNotifier<Widget?> _modal = ValueNotifier(null);
  final ValueStore<void Function()?> dismiss = ValueStore(null);

  DialogModal({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _modal,
      builder: (context, modal, child) {
        if (modal == null) {
          return const SizedBox.shrink();
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            Listener(
              onPointerDown: (event) {
                _modal.value = null;
                if (dismiss.value != null) {
                  dismiss.value!();
                  dismiss.value = null;
                }
              },
              child: ColoredBox(color: Theme.of(context).shadowColor.withOpacity(0.7), child: const SizedBox.expand()),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: SingleChildScrollView(child: modal),
              ),
            ),
          ],
        );
      },
    );
  }

  void setModal(Widget? widget) {
    _modal.value = widget;
    dismiss.value = null;
  }

  void onDismiss(void Function() dismiss) {
    this.dismiss.value = dismiss;
  }
}

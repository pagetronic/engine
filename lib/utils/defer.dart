import 'dart:async';

class Deferrer {
  final int milliseconds;
  Future? _next;
  Completer<void> completer = Completer();

  Deferrer(this.milliseconds);

  get future => completer.future;

  void defer(Function() toDo) {
    Future? next_;
    next_ = Future.delayed(Duration(milliseconds: milliseconds), () {
      if (_next == next_) {
        toDo();
        if (_next != null && !completer.isCompleted) {
          completer.complete();
        }
      }
    });
    _next = next_;
  }

  void abort() {
    _next = null;
  }
}

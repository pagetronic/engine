enum States {
  system(-1),
  archive(-2),
  active(0),
  planned(1);

  final int state;

  const States(this.state);
}

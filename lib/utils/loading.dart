import 'package:engine/utils/fx.dart';
import 'package:flutter/material.dart';

class Loading extends StatelessWidget {
  final Duration? delay;

  const Loading({super.key, this.delay});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.delayed(delay ?? const Duration(milliseconds: 500)),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxWidth: 400),
              child: SizedBox(
                height: 2,
                child: AnimatedOpacity(
                  opacity: snapshot.connectionState != ConnectionState.done ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  child: const LinearProgressIndicator(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          );
        });
  }
}

class CircularLoading extends StatelessWidget {
  final int? delay;
  final double? width;
  final double? height;

  const CircularLoading({super.key, this.delay, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.delayed(Duration(milliseconds: delay == null ? 700 : (delay! + 10))),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          return Center(
            child: Container(
              width: width,
              height: height,
              padding: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxWidth: 400),
              child: AnimatedOpacity(
                opacity: snapshot.connectionState != ConnectionState.done ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                child: const Center(child: AspectRatio(aspectRatio: 1, child: CircularProgressIndicator())),
              ),
            ),
          );
        });
  }
}

class CaterpillarDelayedLoading extends StatelessWidget {
  final int? delay;
  final int frameDelay;

  const CaterpillarDelayedLoading({super.key, this.frameDelay = 80, this.delay});

  @override
  Widget build(BuildContext context) {
    CaterpillarLoading caterpillar = CaterpillarLoading(frameDelay: frameDelay);
    return FutureBuilder(
      future: Future.delayed(delay == null ? Duration.zero : Duration(milliseconds: delay!)),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        return FutureBuilder(
            future: Future.delayed(Duration.zero),
            builder: (context, snapshot) {
              return AnimatedOpacity(
                  opacity: snapshot.connectionState != ConnectionState.done ? 0 : 1,
                  duration: const Duration(milliseconds: 700),
                  child: caterpillar);
            });
      },
    );
  }
}

class CaterpillarLoading extends StatefulWidget {
  final int frameDelay;

  const CaterpillarLoading({super.key, this.frameDelay = 80});

  @override
  State<StatefulWidget> createState() {
    return CaterpillarLoadingState();
  }
}

class CaterpillarLoadingState extends State<CaterpillarLoading> with TickerProviderStateMixin {
  double frame = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400),
        child: FutureBuilder(
          future: Future.delayed(Duration(milliseconds: widget.frameDelay)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              loop();
            }
            return Stack(
              children: [
                const SizedBox(
                  width: 90,
                  height: 90,
                  child: ColoredBox(color: Colors.transparent),
                ),
                Positioned(
                  top: -93 * frame,
                  child: Image.asset(
                    fit: BoxFit.fitWidth,
                    "packages/engine/assets/images/chenille.png",
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> loop() async {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          frame++;
          if (frame > 6) {
            frame = 0;
          }
        });
      });
    }
  }
}

class ButterflyLoading extends StatefulWidget {
  final int frameDelay;

  const ButterflyLoading({super.key, this.frameDelay = 70});

  @override
  State<StatefulWidget> createState() {
    return ButterflyLoadingState();
  }
}

class ButterflyLoadingState extends State<ButterflyLoading> with TickerProviderStateMixin {
  double frame = 0;
  final ValueStore<bool> stop = ValueStore(false);

  @override
  Widget build(BuildContext context) {
    return stop.value
        ? const SizedBox.shrink()
        : Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxWidth: 400),
              child: FutureBuilder(
                future: Future.delayed(Duration(milliseconds: widget.frameDelay)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    loop();
                  }
                  return Stack(
                    children: [
                      const SizedBox(
                        width: 231,
                        height: 200,
                        child: ColoredBox(color: Colors.transparent),
                      ),
                      Positioned(
                        top: -200 * frame,
                        child: Image.asset(
                          fit: BoxFit.fitWidth,
                          "packages/engine/assets/images/papillon.png",
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
  }

  Future<void> loop() async {
    if (mounted && !stop.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          frame++;
          if (frame > 3) {
            frame = 0;
          }
        });
      });
    }
  }
}

class LoadingModal extends StatelessWidget {
  final ValueNotifier<bool> _active = ValueNotifier(false);
  final ValueNotifier<Function()?> _dismiss = ValueNotifier(null);

  LoadingModal({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _active,
      builder: (context, value, child) {
        if (!value) {
          return const SizedBox.shrink();
        }
        return Listener(
          onPointerDown: _dismiss.value == null
              ? null
              : (event) {
                  _dismiss.value?.call();
                  _dismiss.value = null;
                  _active.value = false;
                },
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CaterpillarLoading(),
              ],
            ),
          ),
        );
      },
    );
  }

  void setActive(bool active, [Function()? dismiss]) {
    _dismiss.value = dismiss;
    _active.value = active;
  }
}

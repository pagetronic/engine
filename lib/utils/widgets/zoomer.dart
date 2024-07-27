import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class DoubleTappableInteractiveViewer extends StatefulWidget {
  final double scale;
  final Duration scaleDuration;
  final Curve curve;
  final Widget child;

  final Alignment? alignment;
  final Clip clipBehavior;
  final PanAxis panAxis;
  final EdgeInsets boundaryMargin;
  final bool constrained;
  final bool panEnabled;
  final bool scaleEnabled;
  final bool trackpadScrollCausesScale;
  final double scaleFactor;
  final double maxScale;
  final double minScale;
  final GestureScaleEndCallback? onInteractionEnd;
  final GestureScaleStartCallback? onInteractionStart;
  final GestureScaleUpdateCallback? onInteractionUpdate;
  final void Function()? onTap;
  final TransformationController? controller;

  const DoubleTappableInteractiveViewer({
    super.key,
    this.scale = 3,
    this.curve = Curves.fastLinearToSlowEaseIn,
    this.scaleDuration = const Duration(milliseconds: 700),
    this.clipBehavior = Clip.hardEdge,
    this.panAxis = PanAxis.free,
    this.boundaryMargin = EdgeInsets.zero,
    this.constrained = true,
    this.maxScale = 2.5,
    this.minScale = 0.8,
    this.onInteractionEnd,
    this.onInteractionStart,
    this.onInteractionUpdate,
    this.panEnabled = true,
    this.scaleEnabled = true,
    this.alignment,
    this.trackpadScrollCausesScale = false,
    required this.child,
    required this.scaleFactor,
    this.onTap,
    this.controller,
  });

  @override
  State<DoubleTappableInteractiveViewer> createState() => _DoubleTappableInteractiveViewerState();
}

class _DoubleTappableInteractiveViewerState extends State<DoubleTappableInteractiveViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Animation<Matrix4>? _zoomAnimation;
  late TransformationController _transformationController;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _transformationController = widget.controller ?? TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.scaleDuration,
    )..addListener(() {
        _transformationController.value = _zoomAnimation!.value;
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    final newValue = _transformationController.value.isIdentity() ? _applyZoom() : _revertZoom();

    _zoomAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: newValue,
    ).animate(CurveTween(curve: widget.curve).animate(_animationController));
    _animationController.forward(from: 0);
  }

  Matrix4 _applyZoom() {
    final tapPosition = _doubleTapDetails!.localPosition;
    final translationCorrection = widget.scale - 1;
    final zoomed = Matrix4.identity()
      ..translate(
        -tapPosition.dx * translationCorrection,
        -tapPosition.dy * translationCorrection,
      )
      ..scale(widget.scale);
    return zoomed;
  }

  Matrix4 _revertZoom() => Matrix4.identity();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: _handleDoubleTapDown,
      onDoubleTap: _handleDoubleTap,
      onTap: widget.onTap,
      child: InteractiveViewer(
        alignment: widget.alignment,
        clipBehavior: widget.clipBehavior,
        panAxis: widget.panAxis,
        boundaryMargin: widget.boundaryMargin,
        constrained: widget.constrained,
        panEnabled: widget.panEnabled,
        scaleEnabled: widget.scaleEnabled,
        trackpadScrollCausesScale: widget.trackpadScrollCausesScale,
        scaleFactor: widget.scaleFactor,
        maxScale: widget.maxScale,
        minScale: widget.minScale,
        onInteractionEnd: widget.onInteractionEnd,
        onInteractionStart: widget.onInteractionStart,
        onInteractionUpdate: widget.onInteractionUpdate,
        transformationController: _transformationController,
        child: widget.child,
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Quad, Vector3;

typedef InteractiveViewerWidgetBuilder = Widget Function(BuildContext context, Quad viewport);

@immutable
class InteractiveViewer extends StatefulWidget {
  InteractiveViewer({
    super.key,
    this.clipBehavior = Clip.hardEdge,
    this.panAxis = PanAxis.free,
    this.boundaryMargin = EdgeInsets.zero,
    this.constrained = true,
    this.maxScale = 2.5,
    this.minScale = 0.8,
    this.interactionEndFrictionCoefficient = _kDrag,
    this.onInteractionEnd,
    this.onInteractionStart,
    this.onInteractionUpdate,
    this.panEnabled = true,
    this.scaleEnabled = true,
    this.scaleFactor = kDefaultMouseScrollToScaleFactor,
    this.transformationController,
    this.alignment,
    this.trackpadScrollCausesScale = false,
    required Widget this.child,
    this.onTapDown,
    this.onDoubleTapDown,
    this.onMoveStart,
    this.onMoveEnd,
    this.onMoveUpdate,
    this.onLongPress,
  })  : assert(minScale > 0),
        assert(interactionEndFrictionCoefficient > 0),
        assert(minScale.isFinite),
        assert(maxScale > 0),
        assert(!maxScale.isNaN),
        assert(maxScale >= minScale),
        assert(
          (boundaryMargin.horizontal.isInfinite && boundaryMargin.vertical.isInfinite) ||
              (boundaryMargin.top.isFinite &&
                  boundaryMargin.right.isFinite &&
                  boundaryMargin.bottom.isFinite &&
                  boundaryMargin.left.isFinite),
        ),
        builder = null;

  final GestureTapDownCallback? onTapDown;
  final GestureTapDownCallback? onDoubleTapDown;
  final GestureLongPressStartCallback? onLongPress;
  final bool Function(Offset point)? onMoveStart;
  final void Function()? onMoveEnd;
  final void Function(Offset point)? onMoveUpdate;

  final Alignment? alignment;

  final Clip clipBehavior;

  final PanAxis panAxis;

  final EdgeInsets boundaryMargin;

  final InteractiveViewerWidgetBuilder? builder;

  final Widget? child;

  final bool constrained;

  final bool panEnabled;

  final bool scaleEnabled;

  final bool trackpadScrollCausesScale;

  final double scaleFactor;

  final double maxScale;

  final double minScale;

  final double interactionEndFrictionCoefficient;

  final GestureScaleEndCallback? onInteractionEnd;

  final GestureScaleStartCallback? onInteractionStart;

  final GestureScaleUpdateCallback? onInteractionUpdate;

  final TransformationController? transformationController;

  static const double _kDrag = 0.0000135;

  @visibleForTesting
  static Vector3 getNearestPointOnLine(Vector3 point, Vector3 l1, Vector3 l2) {
    final double lengthSquared = math.pow(l2.x - l1.x, 2.0).toDouble() + math.pow(l2.y - l1.y, 2.0).toDouble();

    if (lengthSquared == 0) {
      return l1;
    }

    final Vector3 l1P = point - l1;
    final Vector3 l1L2 = l2 - l1;
    final double fraction = clampDouble(l1P.dot(l1L2) / lengthSquared, 0.0, 1.0);
    return l1 + l1L2 * fraction;
  }

  @visibleForTesting
  static Quad getAxisAlignedBoundingBox(Quad quad) {
    final double minX = math.min(
      quad.point0.x,
      math.min(
        quad.point1.x,
        math.min(
          quad.point2.x,
          quad.point3.x,
        ),
      ),
    );
    final double minY = math.min(
      quad.point0.y,
      math.min(
        quad.point1.y,
        math.min(
          quad.point2.y,
          quad.point3.y,
        ),
      ),
    );
    final double maxX = math.max(
      quad.point0.x,
      math.max(
        quad.point1.x,
        math.max(
          quad.point2.x,
          quad.point3.x,
        ),
      ),
    );
    final double maxY = math.max(
      quad.point0.y,
      math.max(
        quad.point1.y,
        math.max(
          quad.point2.y,
          quad.point3.y,
        ),
      ),
    );
    return Quad.points(
      Vector3(minX, minY, 0),
      Vector3(maxX, minY, 0),
      Vector3(maxX, maxY, 0),
      Vector3(minX, maxY, 0),
    );
  }

  @visibleForTesting
  static bool pointIsInside(Vector3 point, Quad quad) {
    final Vector3 aM = point - quad.point0;
    final Vector3 aB = quad.point1 - quad.point0;
    final Vector3 aD = quad.point3 - quad.point0;

    final double aMAB = aM.dot(aB);
    final double aBAB = aB.dot(aB);
    final double aMAD = aM.dot(aD);
    final double aDAD = aD.dot(aD);

    return 0 <= aMAB && aMAB <= aBAB && 0 <= aMAD && aMAD <= aDAD;
  }

  @visibleForTesting
  static Vector3 getNearestPointInside(Vector3 point, Quad quad) {
    if (pointIsInside(point, quad)) {
      return point;
    }

    final List<Vector3> closestPoints = <Vector3>[
      InteractiveViewer.getNearestPointOnLine(point, quad.point0, quad.point1),
      InteractiveViewer.getNearestPointOnLine(point, quad.point1, quad.point2),
      InteractiveViewer.getNearestPointOnLine(point, quad.point2, quad.point3),
      InteractiveViewer.getNearestPointOnLine(point, quad.point3, quad.point0),
    ];
    double minDistance = double.infinity;
    late Vector3 closestOverall;
    for (final Vector3 closePoint in closestPoints) {
      final double distance = math.sqrt(
        math.pow(point.x - closePoint.x, 2) + math.pow(point.y - closePoint.y, 2),
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestOverall = closePoint;
      }
    }
    return closestOverall;
  }

  @override
  State<InteractiveViewer> createState() => _InteractiveViewerState();
}

class _InteractiveViewerState extends State<InteractiveViewer> with TickerProviderStateMixin {
  TransformationController? _transformationController;

  final GlobalKey _childKey = GlobalKey();
  final GlobalKey _parentKey = GlobalKey();
  Animation<Offset>? _animation;
  Animation<double>? _scaleAnimation;
  late Offset _scaleAnimationFocalPoint;
  late AnimationController _controller;
  late AnimationController _scaleController;
  Axis? _currentAxis;
  Offset? _referenceFocalPoint;
  double? _scaleStart;
  double? _rotationStart = 0.0;
  double _currentRotation = 0.0;
  _GestureType? _gestureType;

  final bool _rotateEnabled = false;

  Rect get _boundaryRect {
    assert(_childKey.currentContext != null);
    assert(!widget.boundaryMargin.left.isNaN);
    assert(!widget.boundaryMargin.right.isNaN);
    assert(!widget.boundaryMargin.top.isNaN);
    assert(!widget.boundaryMargin.bottom.isNaN);

    final RenderBox childRenderBox = _childKey.currentContext!.findRenderObject()! as RenderBox;
    final Size childSize = childRenderBox.size;
    final Rect boundaryRect = widget.boundaryMargin.inflateRect(Offset.zero & childSize);
    assert(
      !boundaryRect.isEmpty,
      "InteractiveViewer's child must have nonzero dimensions.",
    );
    assert(
      boundaryRect.isFinite ||
          (boundaryRect.left.isInfinite &&
              boundaryRect.top.isInfinite &&
              boundaryRect.right.isInfinite &&
              boundaryRect.bottom.isInfinite),
      'boundaryRect must either be infinite in all directions or finite in all directions.',
    );
    return boundaryRect;
  }

  Rect get _viewport {
    assert(_parentKey.currentContext != null);
    final RenderBox parentRenderBox = _parentKey.currentContext!.findRenderObject()! as RenderBox;
    return Offset.zero & parentRenderBox.size;
  }

  Matrix4 _matrixTranslate(Matrix4 matrix, Offset translation) {
    if (translation == Offset.zero) {
      return matrix.clone();
    }

    late final Offset alignedTranslation;

    if (_currentAxis != null) {
      switch (widget.panAxis) {
        case PanAxis.horizontal:
          alignedTranslation = _alignAxis(translation, Axis.horizontal);
        case PanAxis.vertical:
          alignedTranslation = _alignAxis(translation, Axis.vertical);
        case PanAxis.aligned:
          alignedTranslation = _alignAxis(translation, _currentAxis!);
        case PanAxis.free:
          alignedTranslation = translation;
      }
    } else {
      alignedTranslation = translation;
    }

    final Matrix4 nextMatrix = matrix.clone()
      ..translate(
        alignedTranslation.dx,
        alignedTranslation.dy,
      );

    final Quad nextViewport = _transformViewport(nextMatrix, _viewport);

    if (_boundaryRect.isInfinite) {
      return nextMatrix;
    }

    final Quad boundariesAabbQuad = _getAxisAlignedBoundingBoxWithRotation(
      _boundaryRect,
      _currentRotation,
    );

    final Offset offendingDistance = _exceedsBy(boundariesAabbQuad, nextViewport);
    if (offendingDistance == Offset.zero) {
      return nextMatrix;
    }

    final Offset nextTotalTranslation = _getMatrixTranslation(nextMatrix);
    final double currentScale = matrix.getMaxScaleOnAxis();
    final Offset correctedTotalTranslation = Offset(
      nextTotalTranslation.dx - offendingDistance.dx * currentScale,
      nextTotalTranslation.dy - offendingDistance.dy * currentScale,
    );
    final Matrix4 correctedMatrix = matrix.clone()
      ..setTranslation(Vector3(
        correctedTotalTranslation.dx,
        correctedTotalTranslation.dy,
        0.0,
      ));

    final Quad correctedViewport = _transformViewport(correctedMatrix, _viewport);
    final Offset offendingCorrectedDistance = _exceedsBy(boundariesAabbQuad, correctedViewport);
    if (offendingCorrectedDistance == Offset.zero) {
      return correctedMatrix;
    }

    if (offendingCorrectedDistance.dx != 0.0 && offendingCorrectedDistance.dy != 0.0) {
      return matrix.clone();
    }

    final Offset unidirectionalCorrectedTotalTranslation = Offset(
      offendingCorrectedDistance.dx == 0.0 ? correctedTotalTranslation.dx : 0.0,
      offendingCorrectedDistance.dy == 0.0 ? correctedTotalTranslation.dy : 0.0,
    );
    return matrix.clone()
      ..setTranslation(Vector3(
        unidirectionalCorrectedTotalTranslation.dx,
        unidirectionalCorrectedTotalTranslation.dy,
        0.0,
      ));
  }

  Matrix4 _matrixScale(Matrix4 matrix, double scale) {
    if (scale == 1.0) {
      return matrix.clone();
    }
    assert(scale != 0.0);

    final double currentScale = _transformationController!.value.getMaxScaleOnAxis();
    final double totalScale = math.max(
      currentScale * scale,
      math.max(
        _viewport.width / _boundaryRect.width,
        _viewport.height / _boundaryRect.height,
      ),
    );
    final double clampedTotalScale = clampDouble(
      totalScale,
      widget.minScale,
      widget.maxScale,
    );
    final double clampedScale = clampedTotalScale / currentScale;
    return matrix.clone()..scale(clampedScale);
  }

  Matrix4 _matrixRotate(Matrix4 matrix, double rotation, Offset focalPoint) {
    if (rotation == 0) {
      return matrix.clone();
    }
    final Offset focalPointScene = _transformationController!.toScene(
      focalPoint,
    );
    return matrix.clone()
      ..translate(focalPointScene.dx, focalPointScene.dy)
      ..rotateZ(-rotation)
      ..translate(-focalPointScene.dx, -focalPointScene.dy);
  }

  bool _gestureIsSupported(_GestureType? gestureType) {
    switch (gestureType) {
      case _GestureType.rotate:
        return _rotateEnabled;

      case _GestureType.scale:
        return widget.scaleEnabled;

      case _GestureType.pan:
      case null:
        return widget.panEnabled;
    }
  }

  _GestureType _getGestureType(ScaleUpdateDetails details) {
    final double scale = !widget.scaleEnabled ? 1.0 : details.scale;
    final double rotation = !_rotateEnabled ? 0.0 : details.rotation;
    if ((scale - 1).abs() > rotation.abs()) {
      return _GestureType.scale;
    } else if (rotation != 0.0) {
      return _GestureType.rotate;
    } else {
      return _GestureType.pan;
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    widget.onInteractionStart?.call(details);

    if (_controller.isAnimating) {
      _controller.stop();
      _controller.reset();
      _animation?.removeListener(_onAnimate);
      _animation = null;
    }
    if (_scaleController.isAnimating) {
      _scaleController.stop();
      _scaleController.reset();
      _scaleAnimation?.removeListener(_onScaleAnimate);
      _scaleAnimation = null;
    }

    _gestureType = null;
    _currentAxis = null;
    _scaleStart = _transformationController!.value.getMaxScaleOnAxis();
    _referenceFocalPoint = _transformationController!.toScene(
      details.localFocalPoint,
    );
    _rotationStart = _currentRotation;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final double scale = _transformationController!.value.getMaxScaleOnAxis();
    _scaleAnimationFocalPoint = details.localFocalPoint;
    final Offset focalPointScene = _transformationController!.toScene(
      details.localFocalPoint,
    );

    if (_gestureType == _GestureType.pan) {
      _gestureType = _getGestureType(details);
    } else {
      _gestureType ??= _getGestureType(details);
    }
    if (!_gestureIsSupported(_gestureType)) {
      widget.onInteractionUpdate?.call(details);
      return;
    }

    switch (_gestureType!) {
      case _GestureType.scale:
        assert(_scaleStart != null);
        final double desiredScale = _scaleStart! * details.scale;
        final double scaleChange = desiredScale / scale;
        _transformationController!.value = _matrixScale(
          _transformationController!.value,
          scaleChange,
        );

        final Offset focalPointSceneScaled = _transformationController!.toScene(
          details.localFocalPoint,
        );
        _transformationController!.value = _matrixTranslate(
          _transformationController!.value,
          focalPointSceneScaled - _referenceFocalPoint!,
        );

        final Offset focalPointSceneCheck = _transformationController!.toScene(
          details.localFocalPoint,
        );
        if (_round(_referenceFocalPoint!) != _round(focalPointSceneCheck)) {
          _referenceFocalPoint = focalPointSceneCheck;
        }

      case _GestureType.rotate:
        if (details.rotation == 0.0) {
          widget.onInteractionUpdate?.call(details);
          return;
        }
        final double desiredRotation = _rotationStart! + details.rotation;
        _transformationController!.value = _matrixRotate(
          _transformationController!.value,
          _currentRotation - desiredRotation,
          details.localFocalPoint,
        );
        _currentRotation = desiredRotation;

      case _GestureType.pan:
        assert(_referenceFocalPoint != null);
        if (details.scale != 1.0) {
          widget.onInteractionUpdate?.call(details);
          return;
        }
        _currentAxis ??= _getPanAxis(_referenceFocalPoint!, focalPointScene);
        final Offset translationChange = focalPointScene - _referenceFocalPoint!;
        _transformationController!.value = _matrixTranslate(
          _transformationController!.value,
          translationChange,
        );
        _referenceFocalPoint = _transformationController!.toScene(
          details.localFocalPoint,
        );
    }
    widget.onInteractionUpdate?.call(details);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    widget.onInteractionEnd?.call(details);
    _scaleStart = null;
    _rotationStart = null;
    _referenceFocalPoint = null;

    _animation?.removeListener(_onAnimate);
    _scaleAnimation?.removeListener(_onScaleAnimate);
    _controller.reset();
    _scaleController.reset();

    if (!_gestureIsSupported(_gestureType)) {
      _currentAxis = null;
      return;
    }

    if (_gestureType == _GestureType.pan) {
      if (details.velocity.pixelsPerSecond.distance < kMinFlingVelocity) {
        _currentAxis = null;
        return;
      }
      final Vector3 translationVector = _transformationController!.value.getTranslation();
      final Offset translation = Offset(translationVector.x, translationVector.y);
      final FrictionSimulation frictionSimulationX = FrictionSimulation(
        widget.interactionEndFrictionCoefficient,
        translation.dx,
        details.velocity.pixelsPerSecond.dx,
      );
      final FrictionSimulation frictionSimulationY = FrictionSimulation(
        widget.interactionEndFrictionCoefficient,
        translation.dy,
        details.velocity.pixelsPerSecond.dy,
      );
      final double tFinal = _getFinalTime(
        details.velocity.pixelsPerSecond.distance,
        widget.interactionEndFrictionCoefficient,
      );
      _animation = Tween<Offset>(
        begin: translation,
        end: Offset(frictionSimulationX.finalX, frictionSimulationY.finalX),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.decelerate,
      ));
      _controller.duration = Duration(milliseconds: (tFinal * 1000).round());
      _animation!.addListener(_onAnimate);
      _controller.forward();
    } else if (_gestureType == _GestureType.scale) {
      if (details.scaleVelocity.abs() < 0.1) {
        _currentAxis = null;
        return;
      }
      final double scale = _transformationController!.value.getMaxScaleOnAxis();
      final FrictionSimulation frictionSimulation = FrictionSimulation(
          widget.interactionEndFrictionCoefficient * widget.scaleFactor, scale, details.scaleVelocity / 10);
      final double tFinal = _getFinalTime(details.scaleVelocity.abs(), widget.interactionEndFrictionCoefficient,
          effectivelyMotionless: 0.1);
      _scaleAnimation = Tween<double>(begin: scale, end: frictionSimulation.x(tFinal))
          .animate(CurvedAnimation(parent: _scaleController, curve: Curves.decelerate));
      _scaleController.duration = Duration(milliseconds: (tFinal * 1000).round());
      _scaleAnimation!.addListener(_onScaleAnimate);
      _scaleController.forward();
    }
  }

  void _receivedPointerSignal(PointerSignalEvent event) {
    final double scaleChange;
    if (event is PointerScrollEvent) {
      if (event.kind == PointerDeviceKind.trackpad && !widget.trackpadScrollCausesScale) {
        widget.onInteractionStart?.call(
          ScaleStartDetails(
            focalPoint: event.position,
            localFocalPoint: event.localPosition,
          ),
        );

        final Offset localDelta = PointerEvent.transformDeltaViaPositions(
          untransformedEndPosition: event.position + event.scrollDelta,
          untransformedDelta: event.scrollDelta,
          transform: event.transform,
        );

        if (!_gestureIsSupported(_GestureType.pan)) {
          widget.onInteractionUpdate?.call(ScaleUpdateDetails(
            focalPoint: event.position - event.scrollDelta,
            localFocalPoint: event.localPosition - event.scrollDelta,
            focalPointDelta: -localDelta,
          ));
          widget.onInteractionEnd?.call(ScaleEndDetails());
          return;
        }

        final Offset focalPointScene = _transformationController!.toScene(
          event.localPosition,
        );

        final Offset newFocalPointScene = _transformationController!.toScene(
          event.localPosition - localDelta,
        );

        _transformationController!.value =
            _matrixTranslate(_transformationController!.value, newFocalPointScene - focalPointScene);

        widget.onInteractionUpdate?.call(ScaleUpdateDetails(
            focalPoint: event.position - event.scrollDelta,
            localFocalPoint: event.localPosition - localDelta,
            focalPointDelta: -localDelta));
        widget.onInteractionEnd?.call(ScaleEndDetails());
        return;
      }
      if (event.scrollDelta.dy == 0.0) {
        return;
      }
      scaleChange = math.exp(-event.scrollDelta.dy / widget.scaleFactor);
    } else if (event is PointerScaleEvent) {
      scaleChange = event.scale;
    } else {
      return;
    }
    widget.onInteractionStart?.call(
      ScaleStartDetails(
        focalPoint: event.position,
        localFocalPoint: event.localPosition,
      ),
    );

    if (!_gestureIsSupported(_GestureType.scale)) {
      widget.onInteractionUpdate?.call(ScaleUpdateDetails(
        focalPoint: event.position,
        localFocalPoint: event.localPosition,
        scale: scaleChange,
      ));
      widget.onInteractionEnd?.call(ScaleEndDetails());
      return;
    }

    final Offset focalPointScene = _transformationController!.toScene(
      event.localPosition,
    );

    _transformationController!.value = _matrixScale(
      _transformationController!.value,
      scaleChange,
    );

    final Offset focalPointSceneScaled = _transformationController!.toScene(
      event.localPosition,
    );
    _transformationController!.value = _matrixTranslate(
      _transformationController!.value,
      focalPointSceneScaled - focalPointScene,
    );

    widget.onInteractionUpdate?.call(ScaleUpdateDetails(
      focalPoint: event.position,
      localFocalPoint: event.localPosition,
      scale: scaleChange,
    ));
    widget.onInteractionEnd?.call(ScaleEndDetails());
  }

  void _onAnimate() {
    if (!_controller.isAnimating) {
      _currentAxis = null;
      _animation?.removeListener(_onAnimate);
      _animation = null;
      _controller.reset();
      return;
    }
    final Vector3 translationVector = _transformationController!.value.getTranslation();
    final Offset translation = Offset(translationVector.x, translationVector.y);
    final Offset translationScene = _transformationController!.toScene(
      translation,
    );
    final Offset animationScene = _transformationController!.toScene(
      _animation!.value,
    );
    final Offset translationChangeScene = animationScene - translationScene;
    _transformationController!.value = _matrixTranslate(
      _transformationController!.value,
      translationChangeScene,
    );
  }

  void _onScaleAnimate() {
    if (!_scaleController.isAnimating) {
      _currentAxis = null;
      _scaleAnimation?.removeListener(_onScaleAnimate);
      _scaleAnimation = null;
      _scaleController.reset();
      return;
    }
    final double desiredScale = _scaleAnimation!.value;
    final double scaleChange = desiredScale / _transformationController!.value.getMaxScaleOnAxis();
    final Offset referenceFocalPoint = _transformationController!.toScene(
      _scaleAnimationFocalPoint,
    );
    _transformationController!.value = _matrixScale(
      _transformationController!.value,
      scaleChange,
    );

    final Offset focalPointSceneScaled = _transformationController!.toScene(
      _scaleAnimationFocalPoint,
    );
    _transformationController!.value = _matrixTranslate(
      _transformationController!.value,
      focalPointSceneScaled - referenceFocalPoint,
    );
  }

  void _onTransformationControllerChange() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _transformationController = widget.transformationController ?? TransformationController();
    _transformationController!.addListener(_onTransformationControllerChange);
    _controller = AnimationController(
      vsync: this,
    );
    _scaleController = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(InteractiveViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transformationController == null) {
      if (widget.transformationController != null) {
        _transformationController!.removeListener(_onTransformationControllerChange);
        _transformationController!.dispose();
        _transformationController = widget.transformationController;
        _transformationController!.addListener(_onTransformationControllerChange);
      }
    } else {
      if (widget.transformationController == null) {
        _transformationController!.removeListener(_onTransformationControllerChange);
        _transformationController = TransformationController();
        _transformationController!.addListener(_onTransformationControllerChange);
      } else if (widget.transformationController != oldWidget.transformationController) {
        _transformationController!.removeListener(_onTransformationControllerChange);
        _transformationController = widget.transformationController;
        _transformationController!.addListener(_onTransformationControllerChange);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scaleController.dispose();
    _transformationController!.removeListener(_onTransformationControllerChange);
    if (widget.transformationController == null) {
      _transformationController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (widget.child != null) {
      child = _InteractiveViewerBuilt(
        childKey: _childKey,
        clipBehavior: widget.clipBehavior,
        constrained: widget.constrained,
        matrix: _transformationController!.value,
        alignment: widget.alignment,
        child: widget.child!,
      );
    } else {
      assert(widget.builder != null);
      assert(!widget.constrained);
      child = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Matrix4 matrix = _transformationController!.value;
          return _InteractiveViewerBuilt(
            childKey: _childKey,
            clipBehavior: widget.clipBehavior,
            constrained: widget.constrained,
            alignment: widget.alignment,
            matrix: matrix,
            child: widget.builder!(
              context,
              _transformViewport(matrix, Offset.zero & constraints.biggest),
            ),
          );
        },
      );
    }
    bool movePoint = false;
    return Listener(
      key: _parentKey,
      onPointerSignal: _receivedPointerSignal,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTapDown,
        onDoubleTapDown: widget.onDoubleTapDown,
        onLongPressStart: (details) {
          if (widget.onLongPress != null) {
            widget.onLongPress!(details);
          }
        },
        onLongPressEnd: (details) {
          movePoint = false;
        },
        onScaleEnd: (details) {
          if (!movePoint) {
            _onScaleEnd(details);
          } else if (widget.onMoveEnd != null) {
            movePoint = false;
            widget.onMoveEnd!();
          }
        },
        onScaleStart: (details) {
          if (widget.onMoveStart == null || !widget.onMoveStart!(details.localFocalPoint)) {
            _onScaleStart(details);
          } else {
            movePoint = true;
          }
        },
        onScaleUpdate: (details) {
          if (!movePoint) {
            _onScaleUpdate(details);
          } else if (widget.onMoveUpdate != null) {
            widget.onMoveUpdate!(details.localFocalPoint);
          }
        },
        trackpadScrollCausesScale: widget.trackpadScrollCausesScale,
        trackpadScrollToScaleFactor: Offset(0, -1 / widget.scaleFactor),
        child: child,
      ),
    );
  }
}

class _InteractiveViewerBuilt extends StatelessWidget {
  const _InteractiveViewerBuilt({
    required this.child,
    required this.childKey,
    required this.clipBehavior,
    required this.constrained,
    required this.matrix,
    required this.alignment,
  });

  final Widget child;
  final GlobalKey childKey;
  final Clip clipBehavior;
  final bool constrained;
  final Matrix4 matrix;
  final Alignment? alignment;

  @override
  Widget build(BuildContext context) {
    Widget child = Transform(
      transform: matrix,
      alignment: alignment,
      child: KeyedSubtree(
        key: childKey,
        child: this.child,
      ),
    );

    if (!constrained) {
      child = OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: 0.0,
        minHeight: 0.0,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: child,
      );
    }

    return ClipRect(
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

enum _GestureType {
  pan,
  scale,
  rotate,
}

double _getFinalTime(double velocity, double drag, {double effectivelyMotionless = 10}) {
  return math.log(effectivelyMotionless / velocity) / math.log(drag / 100);
}

Offset _getMatrixTranslation(Matrix4 matrix) {
  final Vector3 nextTranslation = matrix.getTranslation();
  return Offset(nextTranslation.x, nextTranslation.y);
}

Quad _transformViewport(Matrix4 matrix, Rect viewport) {
  final Matrix4 inverseMatrix = matrix.clone()..invert();
  return Quad.points(
    inverseMatrix.transform3(Vector3(
      viewport.topLeft.dx,
      viewport.topLeft.dy,
      0.0,
    )),
    inverseMatrix.transform3(Vector3(
      viewport.topRight.dx,
      viewport.topRight.dy,
      0.0,
    )),
    inverseMatrix.transform3(Vector3(
      viewport.bottomRight.dx,
      viewport.bottomRight.dy,
      0.0,
    )),
    inverseMatrix.transform3(Vector3(
      viewport.bottomLeft.dx,
      viewport.bottomLeft.dy,
      0.0,
    )),
  );
}

Quad _getAxisAlignedBoundingBoxWithRotation(Rect rect, double rotation) {
  final Matrix4 rotationMatrix = Matrix4.identity()
    ..translate(rect.size.width / 2, rect.size.height / 2)
    ..rotateZ(rotation)
    ..translate(-rect.size.width / 2, -rect.size.height / 2);
  final Quad boundariesRotated = Quad.points(
    rotationMatrix.transform3(Vector3(rect.left, rect.top, 0.0)),
    rotationMatrix.transform3(Vector3(rect.right, rect.top, 0.0)),
    rotationMatrix.transform3(Vector3(rect.right, rect.bottom, 0.0)),
    rotationMatrix.transform3(Vector3(rect.left, rect.bottom, 0.0)),
  );
  return InteractiveViewer.getAxisAlignedBoundingBox(boundariesRotated);
}

Offset _exceedsBy(Quad boundary, Quad viewport) {
  final List<Vector3> viewportPoints = <Vector3>[
    viewport.point0,
    viewport.point1,
    viewport.point2,
    viewport.point3,
  ];
  Offset largestExcess = Offset.zero;
  for (final Vector3 point in viewportPoints) {
    final Vector3 pointInside = InteractiveViewer.getNearestPointInside(point, boundary);
    final Offset excess = Offset(
      pointInside.x - point.x,
      pointInside.y - point.y,
    );
    if (excess.dx.abs() > largestExcess.dx.abs()) {
      largestExcess = Offset(excess.dx, largestExcess.dy);
    }
    if (excess.dy.abs() > largestExcess.dy.abs()) {
      largestExcess = Offset(largestExcess.dx, excess.dy);
    }
  }

  return _round(largestExcess);
}

Offset _round(Offset offset) {
  return Offset(
    double.parse(offset.dx.toStringAsFixed(9)),
    double.parse(offset.dy.toStringAsFixed(9)),
  );
}

Offset _alignAxis(Offset offset, Axis axis) {
  switch (axis) {
    case Axis.horizontal:
      return Offset(offset.dx, 0.0);
    case Axis.vertical:
      return Offset(0.0, offset.dy);
  }
}

Axis? _getPanAxis(Offset point1, Offset point2) {
  if (point1 == point2) {
    return null;
  }
  final double x = point2.dx - point1.dx;
  final double y = point2.dy - point1.dy;
  return x.abs() > y.abs() ? Axis.horizontal : Axis.vertical;
}

enum PanAxis {
  horizontal,
  vertical,
  aligned,
  free,
}

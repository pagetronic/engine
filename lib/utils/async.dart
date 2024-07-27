import 'dart:async';

import 'package:engine/utils/ux.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class FutureBuilderLoading<T> extends StatelessWidget {
  final Future<T?> future;
  final Widget Function(BuildContext context, T? result) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Duration? delay;

  const FutureBuilderLoading({super.key, required this.future, required this.builder, this.loadingBuilder, this.delay});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return loadingBuilder != null ? loadingBuilder!(context) : Ux.loading(context, delay: delay);
        } else {
          return builder(context, snapshot.data);
        }
      },
    );
  }
}

class FutureOrBuilderLoading<T> extends StatelessWidget {
  final FutureOr<T?> future;
  final Widget Function(BuildContext context, T? result) builder;

  const FutureOrBuilderLoading({super.key, required this.future, required this.builder});

  @override
  Widget build(BuildContext context) {
    return FutureOrBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Ux.loading(context);
        } else {
          return builder(context, snapshot.data);
        }
      },
    );
  }
}

class FutureOrBuilder<T> extends StatelessWidget {
  final FutureOr<T?> future;
  final Widget Function(BuildContext context, AsyncSnapshot<T?> snapshot) builder;

  const FutureOrBuilder({super.key, required this.future, required this.builder});

  @override
  Widget build(BuildContext context) {
    if (future is T?) {
      return builder(context, AsyncSnapshot<T?>.withData(ConnectionState.done, future as T?));
    }
    return FutureBuilder(future: future as Future<T?>, builder: builder);
  }
}

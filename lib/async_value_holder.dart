import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AsyncValueHolder<T extends Object?> extends StatelessWidget {
  const AsyncValueHolder({
    super.key,
    required this.value,
    required this.builder,
  });

  final AsyncValue<T> value;

  final Widget Function(T value) builder;

  @override
  Widget build(BuildContext context) {
    return value.map(
      data: (value) => builder(value.value),
      error: (error) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Error: ${error.error}'),
        ),
      ),
      loading: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

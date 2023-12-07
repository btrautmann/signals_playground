import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' hide Provider;
import 'package:provider/provider.dart';
import 'package:signal_repro/async_value_holder.dart';
import 'package:signals/signals_flutter.dart';

// This signal is used to simulate a piece of data that can
// change many times throughout the app's lifecycle.
final mainSignal = signal<int>(0);

void main() {
  // Pretend to fetch new data from the server that other state in the
  // app should respond to.
  Timer.periodic(const Duration(seconds: 5), (timer) {
    mainSignal.value = Random().nextInt(100);
  });
  runApp(const MainApp());
}

// A simple state container that exposes a signal to be displayed on the UI
class DataHolder {
  ReadonlySignal<AsyncValue<DailyNetIncomeData>> get data => _data.toReadonlySignal();
  final _data = signal<AsyncValue<DailyNetIncomeData>>(const AsyncLoading());

  DataHolder() {
    // In lieu of something like a `StreamSignal` that automatically reevaluates
    // in response to the `signal`s accessed within changing, run an `effect`
    // that will update `_data` whenever `mainSignal` changes.
    _observe();
  }

  void _observe() {
    effect(() async {
      _data.value = const AsyncLoading();
      try {
        // await Future<void>.delayed(const Duration(seconds: 1));
        // Placing this `print` BEFORE the `await` will cause the UI to
        // work as expected. As it is, the UI will not update after the first
        // running of this `effect`.
        // print('Effect running for ${mainSignal.value}');
        _data.value = AsyncData(
          DailyNetIncomeData(
            dailyIncome: mainSignal.value + Random().nextInt(100),
            totalIncome: mainSignal.value + Random().nextInt(100),
            averageNetIncome: mainSignal.value + Random().nextInt(100),
          ),
        );
      } catch (e) {
        _data.value = AsyncError(e, StackTrace.current);
      }
    });
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context) => DataHolder(),
      child: MaterialApp(
        home: Scaffold(
          body: Watch((context) {
            final value = context.read<DataHolder>().data;
            return AsyncValueHolder(
              value: value.value,
              builder: (data) => Center(
                child: Text(
                  value.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class DailyNetIncomeData extends Equatable {
  final int dailyIncome;
  final int totalIncome;
  final int averageNetIncome;

  const DailyNetIncomeData({
    required this.dailyIncome,
    required this.totalIncome,
    required this.averageNetIncome,
  });

  @override
  List<Object?> get props => [dailyIncome, totalIncome, averageNetIncome];
}

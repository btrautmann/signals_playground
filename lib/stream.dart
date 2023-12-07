import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:state_beacon/state_beacon.dart';

// This signal is used to simulate a piece of data that can
// change many times throughout the app's lifecycle.
final mainSignal = Beacon.writable(0);

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
  final StreamController<DailyNetIncomeData> _controller = StreamController();

  //
  late final data = Beacon.stream(_controller.stream.asBroadcastStream());

  DataHolder() {
    // In lieu of something like a `StreamSignal` that automatically reevaluates
    // in response to the `signal`s accessed within changing, run an `effect`
    // that will update `_data` whenever `mainSignal` changes.
    _observe();
  }

  void _observe() {
    Beacon.createEffect(() async {
      try {
        // await Future<void>.delayed(const Duration(seconds: 1));
        // Placing this `print` BEFORE the `await` will cause the UI to
        // work as expected. As it is, the UI will not update after the first
        // running of this `effect`.
        // print('Effect running for ${mainSignal.value}');
        _controller.add(
          DailyNetIncomeData(
            dailyIncome: mainSignal.value + Random().nextInt(100),
            totalIncome: mainSignal.value + Random().nextInt(100),
            averageNetIncome: mainSignal.value + Random().nextInt(100),
          ),
        );
      } catch (e, s) {
        _controller.addError(e, s);
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
          body: Builder(
            builder: (ctx) {
              final data = ctx.read<DataHolder>().data;
              return switch (data.watch(ctx)) {
                AsyncData<DailyNetIncomeData>(value: final v) => Center(
                    child: Text(
                      v.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                AsyncError(error: final e) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Error: $e'),
                    ),
                  ),
                _ => const Center(
                    child: CircularProgressIndicator(),
                  ),
              };
            },
          ),
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

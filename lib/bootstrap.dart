import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';

/// HuggingFace access token for the gated Gemma model repos.
///
/// Never committed: passed at build time with
/// `flutter run --dart-define=HF_TOKEN=hf_...`. Only needed for the one-time
/// model download; once the model is cached the app runs fully offline.
const huggingFaceToken = String.fromEnvironment('HF_TOKEN');

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  WidgetsFlutterBinding.ensureInitialized();

  // flutter_gemma ships no inference engine of its own: engines are opt-in
  // packages registered here. LiteRT-LM covers .litertlm models on both
  // Android and iOS with GPU acceleration.
  await FlutterGemma.initialize(
    inferenceEngines: const [LiteRtLmEngine()],
    huggingFaceToken: huggingFaceToken.isEmpty ? null : huggingFaceToken,
  );

  runApp(await builder());
}

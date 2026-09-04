import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

part 'chat_state.dart';

/// Gemma 3 1B instruction-tuned, int4-quantized, LiteRT-LM format.
///
/// The repo is gated: request access on HuggingFace once, then pass a token
/// via `--dart-define=HF_TOKEN=...` for the one-time download.
const modelUrl =
    'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/'
    'Gemma3-1B-IT_multi-prefill-seq_q4_ekv4096.litertlm';

/// flutter_gemma identifies installed models by file name.
const modelFileName = 'Gemma3-1B-IT_multi-prefill-seq_q4_ekv4096.litertlm';

/// The iOS Simulator emulates Metal on the Mac's GPU, and LiteRT-LM's GPU
/// kernels return garbage there: deterministic multilingual noise instead of
/// an answer. The CPU backend is correct on the Simulator, just slower.
///
/// `Platform.environment` is empty inside an iOS app, so the check reads the
/// executable path instead: Simulator apps live under
/// `~/Library/Developer/CoreSimulator/`, phone apps under `/private/var/`.
final bool isIosSimulator =
    Platform.isIOS && Platform.resolvedExecutable.contains('/CoreSimulator/');

// Excluded from coverage in CI (coverage_excludes): every method talks to
// the native flutter_gemma plugin, which has no implementation under
// `flutter test`.
class ChatCubit extends Cubit<ChatState> {
  ChatCubit() : super(const ChatState());

  InferenceModel? _model;
  InferenceChat? _chat;

  /// Decides the whole demo flow: cached model → straight to offline chat,
  /// no model → show the download screen. Never touches the network itself,
  /// so airplane mode with a cached model is safe.
  Future<void> initialize() async {
    try {
      final installed = await FlutterGemma.isModelInstalled(modelFileName);
      if (installed) {
        await _loadModel();
      } else {
        emit(state.copyWith(status: ChatStatus.needsDownload));
      }
    } on Object catch (error) {
      // A crash on camera is worse than a broad catch in demo code.
      emit(state.copyWith(status: ChatStatus.error, errorMessage: '$error'));
    }
  }

  Future<void> downloadModel() async {
    emit(
      state.copyWith(
        status: ChatStatus.downloading,
        download: const DownloadProgress(),
      ),
    );
    // Only used to derive the average rate and time left shown on screen.
    final clock = Stopwatch()..start();
    try {
      // fileType must be explicit: it selects the engine, and the default
      // (.task) would route this .litertlm file to MediaPipe, which cannot
      // read it. foreground:true keeps Android from killing the download
      // at the 9-minute background execution limit.
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
        fileType: ModelFileType.litertlm,
      ).fromNetwork(modelUrl, foreground: true).withProgress((percent) {
        if (!isClosed) {
          emit(
            state.copyWith(
              download: DownloadProgress(
                percent: percent,
                elapsed: clock.elapsed,
              ),
            ),
          );
        }
      }).install();
      await _loadModel();
    } on Object catch (error) {
      emit(state.copyWith(status: ChatStatus.error, errorMessage: '$error'));
    }
  }

  Future<void> retry() => initialize();

  Future<void> _loadModel() async {
    emit(state.copyWith(status: ChatStatus.loadingModel));

    final path = await FlutterGemma.getModelPath(modelFileName);
    final sizeBytes = await File(path).length();

    // Cold load = weights from flash into RAM + GPU warm-up. This is the
    // price the user pays on every app start, so it goes on screen.
    final clock = Stopwatch()..start();
    final model = await FlutterGemma.getActiveModel(
      maxTokens: 2048,
      preferredBackend: isIosSimulator
          ? PreferredBackend.cpu
          : PreferredBackend.gpu,
    );
    final chat = await model.createChat();
    clock.stop();

    _model = model;
    _chat = chat;
    emit(
      state.copyWith(
        status: ChatStatus.ready,
        metrics: state.metrics.copyWith(
          modelSizeBytes: sizeBytes,
          coldLoad: clock.elapsed,
          peakMemoryBytes: ProcessInfo.currentRss,
        ),
      ),
    );
  }

  Future<void> sendMessage(String text) async {
    final chat = _chat;
    final prompt = text.trim();
    if (chat == null || prompt.isEmpty || state.status != ChatStatus.ready) {
      return;
    }

    emit(
      state.copyWith(
        status: ChatStatus.generating,
        messages: [
          ...state.messages,
          ChatMessage(text: prompt, isFromUser: true),
          const ChatMessage(text: '', isFromUser: false),
        ],
      ),
    );

    try {
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));

      final clock = Stopwatch()..start();
      var tokenCount = 0;
      Duration? firstToken;
      var peakRss = state.metrics.peakMemoryBytes ?? 0;

      await for (final response in chat.generateChatResponseAsync()) {
        if (response is! TextResponse) continue;
        tokenCount++;
        firstToken ??= clock.elapsed;
        if (ProcessInfo.currentRss > peakRss) {
          peakRss = ProcessInfo.currentRss;
        }
        // Decode rate only: the prefill wait before the first token is
        // reported separately as time-to-first-token.
        final decodeMs = (clock.elapsed - firstToken).inMilliseconds;
        final tokensPerSecond = tokenCount > 1 && decodeMs > 0
            ? (tokenCount - 1) * 1000 / decodeMs
            : null;
        emit(
          state.copyWith(
            messages: _appendToReply(response.token),
            metrics: state.metrics.copyWith(
              timeToFirstToken: firstToken,
              tokensPerSecond: tokensPerSecond,
              peakMemoryBytes: peakRss,
            ),
          ),
        );
      }
      emit(state.copyWith(status: ChatStatus.ready));
    } on Object catch (error) {
      // Keep the transcript and stay usable: surface the failure inline.
      emit(
        state.copyWith(
          status: ChatStatus.ready,
          messages: _appendToReply('\n[error] $error'),
        ),
      );
    }
  }

  /// Cancels decoding at the native level; the token stream then completes
  /// and [sendMessage] returns to ready on its own.
  Future<void> stopGeneration() async {
    if (state.status != ChatStatus.generating) return;
    await _chat?.stopGeneration();
  }

  List<ChatMessage> _appendToReply(String token) {
    final messages = [...state.messages];
    final reply = messages.last;
    messages[messages.length - 1] = reply.copyWith(
      text: reply.text + token,
      tokenCount: reply.tokenCount + 1,
    );
    return messages;
  }

  @override
  Future<void> close() async {
    await _model?.close();
    return super.close();
  }
}

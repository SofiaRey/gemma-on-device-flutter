part of 'chat_cubit.dart';

/// Lifecycle of the demo, in the order the audience sees it.
enum ChatStatus {
  checkingCache,
  needsDownload,
  downloading,
  loadingModel,
  ready,
  generating,
  error,
}

/// A single transcript entry.
class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isFromUser,
    this.tokenCount = 0,
  });

  final String text;
  final bool isFromUser;

  /// Tokens decoded so far. Only meaningful for model replies.
  final int tokenCount;

  ChatMessage copyWith({String? text, int? tokenCount}) {
    return ChatMessage(
      text: text ?? this.text,
      isFromUser: isFromUser,
      tokenCount: tokenCount ?? this.tokenCount,
    );
  }
}

const int _bytesPerMegabyte = 1024 * 1024;
const String _placeholder = '—';

/// The one-time download, formatted for the downloading screen.
///
/// The plugin only reports a percentage, so bytes are derived from the
/// known model size and the rate is the average since the download started.
class DownloadProgress {
  const DownloadProgress({this.percent = 0, this.elapsed = Duration.zero});

  final int percent;
  final Duration elapsed;

  /// Size of the Gemma 3 1B q4 .litertlm file. Approximate by design: once
  /// installed, the real on-disk size replaces it in [ChatMetrics].
  static const int totalBytes = 555 * _bytesPerMegabyte;

  int get downloadedBytes => totalBytes * percent ~/ 100;

  double? get bytesPerSecond => elapsed.inMilliseconds == 0 || percent == 0
      ? null
      : downloadedBytes * 1000 / elapsed.inMilliseconds;

  Duration? get timeLeft {
    final rate = bytesPerSecond;
    if (rate == null) return null;
    final remaining = totalBytes - downloadedBytes;
    return Duration(seconds: (remaining / rate).round());
  }

  String get percentLabel => '$percent%';

  String get totalLabel => '${totalBytes ~/ _bytesPerMegabyte} MB';

  String get downloadedLabel =>
      '${downloadedBytes ~/ _bytesPerMegabyte} / '
      '${totalBytes ~/ _bytesPerMegabyte} MB';

  String get rateLabel => bytesPerSecond == null
      ? _placeholder
      : '${(bytesPerSecond! / _bytesPerMegabyte).toStringAsFixed(1)} MB/s';

  String get timeLeftLabel {
    final left = timeLeft;
    if (left == null) return _placeholder;
    final minutes = left.inMinutes.toString().padLeft(2, '0');
    final seconds = (left.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// The talking points: every number the talk is about, formatted for the
/// stat strip. All values are approximate by design.
class ChatMetrics {
  const ChatMetrics({
    this.modelSizeBytes,
    this.coldLoad,
    this.timeToFirstToken,
    this.tokensPerSecond,
    this.peakMemoryBytes,
  });

  final int? modelSizeBytes;
  final Duration? coldLoad;
  final Duration? timeToFirstToken;
  final double? tokensPerSecond;
  final int? peakMemoryBytes;

  String get sizeLabel => modelSizeBytes == null
      ? _placeholder
      : '${modelSizeBytes! ~/ _bytesPerMegabyte} MB';

  String get coldLoadLabel => coldLoad == null
      ? _placeholder
      : '${(coldLoad!.inMilliseconds / 1000).toStringAsFixed(2)} s';

  String get timeToFirstTokenLabel => timeToFirstToken == null
      ? _placeholder
      : '${timeToFirstToken!.inMilliseconds} ms';

  String get tokensPerSecondLabel => tokensPerSecond == null
      ? _placeholder
      : tokensPerSecond!.toStringAsFixed(1);

  String get peakMemoryLabel => peakMemoryBytes == null
      ? _placeholder
      : '~${peakMemoryBytes! ~/ _bytesPerMegabyte} MB';

  ChatMetrics copyWith({
    int? modelSizeBytes,
    Duration? coldLoad,
    Duration? timeToFirstToken,
    double? tokensPerSecond,
    int? peakMemoryBytes,
  }) {
    return ChatMetrics(
      modelSizeBytes: modelSizeBytes ?? this.modelSizeBytes,
      coldLoad: coldLoad ?? this.coldLoad,
      timeToFirstToken: timeToFirstToken ?? this.timeToFirstToken,
      tokensPerSecond: tokensPerSecond ?? this.tokensPerSecond,
      peakMemoryBytes: peakMemoryBytes ?? this.peakMemoryBytes,
    );
  }
}

class ChatState {
  const ChatState({
    this.status = ChatStatus.checkingCache,
    this.download = const DownloadProgress(),
    this.messages = const [],
    this.metrics = const ChatMetrics(),
    this.errorMessage,
  });

  final ChatStatus status;
  final DownloadProgress download;
  final List<ChatMessage> messages;
  final ChatMetrics metrics;
  final String? errorMessage;

  ChatState copyWith({
    ChatStatus? status,
    DownloadProgress? download,
    List<ChatMessage>? messages,
    ChatMetrics? metrics,
    String? errorMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      download: download ?? this.download,
      messages: messages ?? this.messages,
      metrics: metrics ?? this.metrics,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

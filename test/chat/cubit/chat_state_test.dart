import 'package:fcl_2026_demo/chat/chat.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatMetrics', () {
    test('shows placeholders when nothing is measured yet', () {
      const metrics = ChatMetrics();
      expect(metrics.sizeLabel, '—');
      expect(metrics.coldLoadLabel, '—');
      expect(metrics.timeToFirstTokenLabel, '—');
      expect(metrics.tokensPerSecondLabel, '—');
      expect(metrics.peakMemoryLabel, '—');
    });

    test('formats measured values for the stat strip', () {
      const metrics = ChatMetrics(
        modelSizeBytes: 555 * 1024 * 1024,
        coldLoad: Duration(milliseconds: 1843),
        timeToFirstToken: Duration(milliseconds: 240),
        tokensPerSecond: 27.349,
        peakMemoryBytes: 742 * 1024 * 1024,
      );
      expect(metrics.sizeLabel, '555 MB');
      expect(metrics.coldLoadLabel, '1.84 s');
      expect(metrics.timeToFirstTokenLabel, '240 ms');
      expect(metrics.tokensPerSecondLabel, '27.3');
      expect(metrics.peakMemoryLabel, '~742 MB');
    });

    test('copyWith keeps existing values when omitted', () {
      const metrics = ChatMetrics(modelSizeBytes: 10);
      final updated = metrics.copyWith(
        tokensPerSecond: 5,
        timeToFirstToken: const Duration(milliseconds: 100),
      );
      expect(updated.modelSizeBytes, 10);
      expect(updated.tokensPerSecond, 5);
      expect(updated.timeToFirstToken, const Duration(milliseconds: 100));

      final unchanged = updated.copyWith();
      expect(unchanged.tokensPerSecond, 5);
      expect(unchanged.timeToFirstToken, const Duration(milliseconds: 100));
    });
  });

  group('DownloadProgress', () {
    test('shows placeholders before the first progress report', () {
      const progress = DownloadProgress();
      expect(progress.percentLabel, '0%');
      expect(progress.totalLabel, '555 MB');
      expect(progress.downloadedLabel, '0 / 555 MB');
      expect(progress.rateLabel, '—');
      expect(progress.timeLeftLabel, '—');
    });

    test('derives bytes, rate and time left from percent and elapsed', () {
      const progress = DownloadProgress(
        percent: 40,
        elapsed: Duration(seconds: 20),
      );
      expect(progress.percentLabel, '40%');
      expect(progress.downloadedLabel, '222 / 555 MB');
      expect(progress.rateLabel, '11.1 MB/s');
      expect(progress.timeLeftLabel, '00:30');
    });

    test('formats minutes in the time left', () {
      const progress = DownloadProgress(
        percent: 10,
        elapsed: Duration(seconds: 30),
      );
      expect(progress.timeLeftLabel, '04:30');
    });
  });

  group('ChatMessage', () {
    test('copyWith replaces text and token count and keeps author', () {
      const message = ChatMessage(text: 'a', isFromUser: false);
      final updated = message.copyWith(text: 'ab', tokenCount: 2);
      expect(updated.text, 'ab');
      expect(updated.tokenCount, 2);
      expect(updated.isFromUser, isFalse);
    });
  });

  group('ChatState', () {
    test('starts checking the cache with empty transcript', () {
      const state = ChatState();
      expect(state.status, ChatStatus.checkingCache);
      expect(state.messages, isEmpty);
      expect(state.download.percent, 0);
      expect(state.errorMessage, isNull);
    });

    test('copyWith keeps existing values when omitted', () {
      const state = ChatState(
        status: ChatStatus.ready,
        download: DownloadProgress(percent: 80),
      );
      final updated = state.copyWith(
        messages: const [ChatMessage(text: 'hi', isFromUser: true)],
      );
      expect(updated.status, ChatStatus.ready);
      expect(updated.download.percent, 80);
      expect(updated.messages, hasLength(1));
    });
  });
}

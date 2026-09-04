import 'package:bloc_test/bloc_test.dart';
import 'package:fcl_2026_demo/chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class _MockChatCubit extends MockCubit<ChatState> implements ChatCubit {}

void main() {
  late ChatCubit cubit;

  setUp(() {
    cubit = _MockChatCubit();
  });

  Future<void> pumpChatView(WidgetTester tester, ChatState state) async {
    whenListen(
      cubit,
      const Stream<ChatState>.empty(),
      initialState: state,
    );
    await tester.pumpApp(
      BlocProvider.value(value: cubit, child: const ChatView()),
    );
  }

  group('ChatPage', () {
    testWidgets('renders and falls back to the error screen when the '
        'native engine is unavailable', (tester) async {
      await tester.pumpApp(const ChatPage());
      await tester.pump();
      expect(find.byType(ChatView), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
    });
  });

  group('ChatView', () {
    testWidgets('shows an indeterminate track while checking the cache', (
      tester,
    ) async {
      await pumpChatView(tester, const ChatState());
      expect(find.text('Checking model cache'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the download screen before the model is cached', (
      tester,
    ) async {
      await pumpChatView(
        tester,
        const ChatState(status: ChatStatus.needsDownload),
      );
      expect(find.text('Model not installed'), findsOneWidget);
      expect(find.text('Install once, then answer offline.'), findsOneWidget);
      expect(find.text('Gemma3-1B-IT'), findsOneWidget);
      expect(find.text('555 MB'), findsOneWidget);
    });

    testWidgets('starts the download when the button is tapped', (
      tester,
    ) async {
      when(() => cubit.downloadModel()).thenAnswer((_) async {});
      await pumpChatView(
        tester,
        const ChatState(status: ChatStatus.needsDownload),
      );
      await tester.tap(find.byType(FilledButton));
      verify(() => cubit.downloadModel()).called(1);
    });

    testWidgets('shows the download percentage, bytes, rate and time left', (
      tester,
    ) async {
      await pumpChatView(
        tester,
        const ChatState(
          status: ChatStatus.downloading,
          download: DownloadProgress(
            percent: 40,
            elapsed: Duration(seconds: 20),
          ),
        ),
      );
      expect(find.text('Downloading'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('222 / 555 MB'), findsOneWidget);
      expect(find.text('11.1 MB/s'), findsOneWidget);
      expect(find.text('00:30'), findsOneWidget);
    });

    testWidgets('shows the loading state once the model is cached', (
      tester,
    ) async {
      await pumpChatView(
        tester,
        const ChatState(status: ChatStatus.loadingModel),
      );
      expect(find.text('Loading model into RAM'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the header state and metric values when ready', (
      tester,
    ) async {
      await pumpChatView(
        tester,
        const ChatState(
          status: ChatStatus.ready,
          metrics: ChatMetrics(
            modelSizeBytes: 528 * 1024 * 1024,
            coldLoad: Duration(milliseconds: 1840),
            timeToFirstToken: Duration(milliseconds: 312),
            tokensPerSecond: 24.6,
            peakMemoryBytes: 742 * 1024 * 1024,
          ),
        ),
      );
      expect(find.text('Gemma 3 1B'), findsOneWidget);
      expect(find.text('Offline ready'), findsOneWidget);
      expect(find.text('528 MB'), findsOneWidget);
      expect(find.text('1.84 s'), findsOneWidget);
      expect(find.text('312 ms'), findsOneWidget);
      expect(find.text('24.6'), findsOneWidget);
      expect(find.text('~742 MB'), findsOneWidget);
    });

    testWidgets('renders transcript turns and sends a message', (
      tester,
    ) async {
      when(() => cubit.sendMessage(any())).thenAnswer((_) async {});
      await pumpChatView(
        tester,
        const ChatState(
          status: ChatStatus.ready,
          messages: [
            ChatMessage(text: 'hello', isFromUser: true),
            ChatMessage(text: 'hi there', isFromUser: false),
          ],
        ),
      );
      expect(find.text('You'), findsOneWidget);
      expect(find.text('hello'), findsOneWidget);
      expect(find.text('hi there'), findsOneWidget);
      // Header title plus the role label of the reply.
      expect(find.text('Gemma 3 1B'), findsNWidgets(2));

      await tester.enterText(find.byType(TextField), 'why offline?');
      await tester.tap(find.byIcon(Icons.arrow_upward));
      verify(() => cubit.sendMessage('why offline?')).called(1);

      await tester.enterText(find.byType(TextField), 'and again');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      verify(() => cubit.sendMessage('and again')).called(1);
    });

    testWidgets('shows the token count, caret and stop button while '
        'generating', (tester) async {
      when(() => cubit.stopGeneration()).thenAnswer((_) async {});
      await pumpChatView(
        tester,
        const ChatState(
          status: ChatStatus.generating,
          messages: [
            ChatMessage(text: 'Explain prefill vs decode.', isFromUser: true),
            ChatMessage(
              text: 'Prefill reads the prompt',
              isFromUser: false,
              tokenCount: 41,
            ),
          ],
        ),
      );
      expect(find.text('Generating'), findsOneWidget);
      expect(find.text('41 tokens'), findsOneWidget);
      expect(find.byKey(const Key('streaming_caret')), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text('Stop generating'));
      verify(() => cubit.stopGeneration()).called(1);
    });

    testWidgets('shows the error screen and retries', (tester) async {
      when(() => cubit.retry()).thenAnswer((_) async {});
      await pumpChatView(
        tester,
        const ChatState(status: ChatStatus.error, errorMessage: 'boom'),
      );
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('boom'), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      verify(() => cubit.retry()).called(1);
    });
  });
}

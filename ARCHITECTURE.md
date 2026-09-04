# Architecture

One feature, no layers. The cubit talks to the `FlutterGemma` facade directly.

## Code map

- `lib/bootstrap.dart`: runs once before `runApp`. `FlutterGemma.initialize`
  registers `LiteRtLmEngine` and stores the HuggingFace token from
  `String.fromEnvironment('HF_TOKEN')`. This line is load-bearing: without a
  registered engine the first model call throws a `StateError` at runtime.
- `lib/main_development.dart`, `main_staging.dart`, `main_production.dart`:
  flavor entry points, all funnel through `bootstrap`.
- `lib/app/view/app.dart`: `MaterialApp` with the light Geist theme. Home
  is `ChatPage`.
- `lib/chat/cubit/chat_cubit.dart`: every inference call lives here. Model URL
  and file name are the two constants at the top, followed by the iOS
  Simulator check that switches the engine to the CPU backend. Also measures all metrics:
  cold load, time to first token, tokens per second, peak RSS.
- `lib/chat/cubit/chat_state.dart`: the `ChatStatus` state machine
  (`checkingCache`, `needsDownload`, `downloading`, `loadingModel`, `ready`,
  `generating`, `error`), `ChatMessage` with its token count,
  `DownloadProgress` with the bytes, rate, and time-left labels derived from
  the plugin's percentage, and `ChatMetrics` with its stat labels.
- `lib/chat/view/chat_page.dart`: `ChatColors` and `ChatText` copied from the
  design, then one screen per `ChatStatus`. The chat screen is a header with
  the state label, `_StatStrip` (the five stats), the transcript, and the
  composer, which swaps to a stop button while generating.
- `assets/fonts/`: Geist and Geist Mono variable fonts, SIL OFL licensed.
- `lib/l10n/`: ARB strings, English and Spanish.
- `test/`: state, metric formatting, and every screen state of the view via a
  mocked cubit. `chat_cubit.dart` is excluded from coverage in
  `.github/workflows/main.yaml` because its methods hit the native plugin.

## Data flow for one inference

1. User submits text. `_Composer` calls `ChatCubit.sendMessage`.
2. Cubit emits `generating` with the user message and an empty reply turn
   appended to `messages`.
3. `chat.addQueryChunk(Message.text(text: prompt, isUser: true))` hands the
   prompt to the native session.
4. `await for` over `chat.generateChatResponseAsync()`. Each `TextResponse`
   token is appended to the last message and counted, metrics are recomputed
   (first token latency once, decode rate from the second token on, peak RSS
   per token), and the state is re-emitted.
5. The view rebuilds per token, but only the subtrees that `context.select`
   the changed slice.
6. The stream completes, or `stopGeneration` cancels it at the native level,
   and the cubit returns to `ready`.

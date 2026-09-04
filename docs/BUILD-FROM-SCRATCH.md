# Build this demo from scratch

Paste the block below into Claude Code, Cursor, or Codex from inside a fresh
project generated with `very_good create flutter_app my_demo`. It is a spec,
not a diff. Expect the agent to need a device attached to verify the result.

````text
Build an on-device AI chat demo for a conference talk, on top of this
Very Good CLI Flutter app template.

GOAL
A single-screen chat app that runs Google's Gemma 3 1B entirely on the
phone. After a one-time model download it must work in airplane mode. The
app is projected on stage, so the UI must be legible from the back row and
must display live performance metrics at all times.

STACK, FIXED
- Dependencies to add: flutter_gemma (>=1.6.5) and flutter_gemma_litertlm
  (>=1.5.2). Nothing else. No routing, no connectivity packages, no DI.
- The flutter_gemma API changed at 1.5: engines are now separate opt-in
  packages registered at startup, and the old FlutterGemmaPlugin.instance /
  modelManager API is gone. Do NOT trust your training data for this
  package. Read the current flutter_gemma README on pub.dev first and use
  the FlutterGemma static facade plus a builder-style
  installModel(...).fromNetwork(...).withProgress(...).install() chain.
- Model: Gemma 3 1B instruction-tuned, int4, LiteRT-LM format, from
  https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT_multi-prefill-seq_q4_ekv4096.litertlm
  (about 550 MB). The repo is gated: the download needs a HuggingFace token
  supplied at build time via --dart-define=HF_TOKEN=... and read with
  String.fromEnvironment. Never commit the token.

ARCHITECTURE, DELIBERATELY FLAT
- One ChatCubit (flutter_bloc) that calls the FlutterGemma facade directly.
  No repository or service layer: this code may appear on slides, so
  readability beats abstraction.
- Register the inference engine and the token once in lib/bootstrap.dart
  before runApp. If no engine is registered the plugin throws a StateError
  at the first model call, so this registration is mandatory.
- State machine, each status mapping to exactly one screen:
  checkingCache, needsDownload, downloading, loadingModel, ready,
  generating, error.

REQUIRED BEHAVIOR
1. Offline path: on every launch check whether the model file is already
   installed (a local file check, no network). If cached, go straight to
   loading and chat. The download screen is only reachable when the file is
   missing. A header state label flips to a green "Offline ready" as soon
   as the cached model is loaded, and to a blue "Generating" while tokens
   stream.
2. Download screen: a headline, a spec list (model, format, quantization,
   engine, download size) and one full-width button. Then a progress view
   with a 48-point percentage, a thin progress track, and a list with bytes
   downloaded, average rate, time left, and destination. On Android the download must
   run as a foreground service (progress notification) so the OS cannot
   kill it at the 9-minute background limit. When installing the model,
   pass the file type for .litertlm explicitly: the installer's default
   (.task) routes the file to an engine that cannot read it.
3. Chat: streamed generation only. Append each streamed text token to the
   last transcript message and re-emit so the reply visibly types itself.
   Provide a red Stop button that cancels generation natively; the cubit
   returns to ready when the stream completes.
4. Metrics bar, five tiles always visible, measured with nothing beyond the
   Dart SDK:
   - ON DISK: File(path).length() of the installed model.
   - COLD LOAD: stopwatch around model load plus chat creation.
   - 1ST TOKEN: send to first streamed token.
   - TOK/SEC: decode rate counted from the second token, so prefill does
     not pollute it.
   - PEAK MEM: ProcessInfo.currentRss sampled at load and per token,
     labeled approximate.
5. Projector UI: near-black background, 24pt chat bubbles, oversized metric
   tiles with tabular figures, hard-coded high-contrast colors.

PLATFORM CONFIG
- iOS: raise IPHONEOS_DEPLOYMENT_TARGET to 15.0 in project.pbxproj (Flutter
  3.44 templates use Swift Package Manager, there is no Podfile). Add
  UIFileSharingEnabled=true and an NSLocalNetworkUsageDescription string to
  Info.plist.
- Android: in AndroidManifest.xml add POST_NOTIFICATIONS and
  FOREGROUND_SERVICE_DATA_SYNC permissions, override WorkManager's
  SystemForegroundService with foregroundServiceType="dataSync" (mandatory
  on API 34+ or the foreground download crashes), and add the four
  uses-native-library OpenCL entries (libvndksupport.so, libOpenCL.so,
  libOpenCL-car.so, libOpenCL-pixel.so, all required=false) so GPU
  inference does not silently fall back to CPU on Android 12+.

CONSTRAINTS
- very_good_analysis must pass with zero issues.
- Keep the template's flavors, l10n, and test setup. All user-facing
  strings go through the l10n ARB files.
- The cubit cannot be unit tested (the plugin's statics hit native code):
  exclude it from CI coverage and test everything else, including every
  screen state of the view through a mocked cubit.
- Test on a physical device. On the iOS Simulator request the CPU backend,
  because the GPU backend returns garbage tokens there. Detect the Simulator
  with `Platform.resolvedExecutable.contains('/CoreSimulator/')`;
  `Platform.environment` is empty inside an iOS app. The Simulator proves the code path,
  not the performance.

ACCEPTANCE
Fresh install downloads the model with visible progress, then chats with
streamed tokens and live metrics. Kill the app, enable airplane mode,
relaunch: it must go straight to chat and answer prompts offline.
````

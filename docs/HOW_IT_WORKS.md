# How this demo works

Speaker notes for "Offline AI in Flutter with Gemma". Each step says what
changed, where, what the alternative was, and what it costs the user. The
workaround flags are the interesting parts, tell those stories.

## Step 1: Two dependencies, not one

**Changed:** `pubspec.yaml` adds `flutter_gemma` and `flutter_gemma_litertlm`.

**Why two.** As of flutter_gemma 1.5, the core package ships zero inference
engines. An inference engine is the native runtime that actually executes the
model: it loads the weights into memory and runs the transformer math on the
device's CPU or GPU. The core `flutter_gemma` package is only the Dart API on
top; without an engine it cannot run anything. Engines are opt-in add-on
packages you register at startup. This is
worth 30 seconds on stage: the plugin went modular so apps only bundle the
native runtime they actually use.

**Alternative:** `flutter_gemma_mediapipe`, which runs the older `.task`
format. It raises the iOS floor to 16.0 and adds a second native runtime. The
LiteRT-LM engine covers Android and iOS with one runtime and the newer format,
so it wins for this demo.

**Cost to the user:** the LiteRT-LM native library adds roughly 10 to 20 MB to
the app binary before any model is downloaded. That is the entry fee for
on-device inference.

> **Workaround flag:** if you register no engine, nothing fails at compile
> time. You get a StateError at the first model call. The registration in
> `lib/bootstrap.dart` is load-bearing and invisible, which is exactly the
> kind of API trap a talk audience enjoys.

## Step 2: The model choice

**Changed:** constants at the top of `lib/chat/cubit/chat_cubit.dart`.

Gemma 3 1B instruction-tuned, int4 quantized, `.litertlm`, about 550 MB from
`litert-community/Gemma3-1B-IT`. The int4 quantization is the whole trade-off
story in one file name: a quarter of the bytes per weight, a small quality
loss, and it is the difference between "fits on a phone" and "does not".

**Alternative:** Gemma 3 270M is about 300 MB and loads almost instantly, but
its open-ended chat answers are weak enough to become the story on camera. If
you want to show that trade-off live, swap the two URL constants and rebuild.
Nothing else changes.

**Cost to the user:** 550 MB of flash permanently, about 1.2 to 1.5 GB of RAM
while loaded, and sustained CPU/GPU burn during generation. Ten minutes of
heavy chatting costs a few percent of battery on an iPhone 14 Pro. Say this
out loud: offline AI moves the cloud bill onto the user's battery and storage.

> **Workaround flag:** both Gemma repos on HuggingFace are gated. You must
> request access on the model page once, then pass a token at build time.
> The token lives in `secrets.json`, which is gitignored, and reaches the
> build through `--dart-define-from-file=secrets.json`. The VSCode
> "Launch development" configuration passes it automatically. Either way it
> is compiled in via `String.fromEnvironment` and never committed.

## Step 3: Engine registration in bootstrap

**Changed:** `lib/bootstrap.dart`.

`FlutterGemma.initialize` registers `LiteRtLmEngine` and stores the
HuggingFace token read from `String.fromEnvironment('HF_TOKEN')`. This runs
once before `runApp`, in the same place VGV's template puts cross-flavor
setup, so all three flavors get it for free.

**Alternative:** initialize lazily inside the feature. Rejected because the
whole point of a bootstrap file is that wiring happens once, in one place.

**Cost to the user:** none measurable. Registration is bookkeeping, no native
code runs until a model loads.

## Step 4: Platform config, where the bodies are buried

**Changed:** `ios/Runner.xcodeproj/project.pbxproj`, `ios/Runner/Info.plist`,
`android/app/src/main/AndroidManifest.xml`.

iOS: deployment target raised from 13.0 to 15.0. This project uses Swift
Package Manager, the Flutter 3.44 default, so there is no Podfile to set a
platform in. The pbxproj is the only place. Info.plist gains
`UIFileSharingEnabled`, handy on stage because you can show the 550 MB file
sitting in the Files app, and `NSLocalNetworkUsageDescription` which the
engine wants for development builds.

Android: four `uses-native-library` OpenCL entries. Without them the OpenCL
loader cannot open the vendor driver on Android 12+ and inference silently
falls back to a slower path. Silent GPU fallback is a great talk beat: the app
works either way, only the tokens per second number betrays it, which is a
reason the metrics bar exists.

**Alternative:** skip the OpenCL entries and run CPU-only. Works everywhere,
roughly half the speed or worse, and hotter.

> **Workaround flag:** the iOS Simulator is the one place the app asks for
> CPU on purpose. The Simulator emulates Metal on the Mac's GPU, and with
> `PreferredBackend.gpu` LiteRT-LM streams deterministic gibberish there, the
> same wrong tokens every launch, while the CPU backend answers correctly.
> The model file is byte-for-byte intact when this happens, so the cause is
> the compute path, not the download. `chat_cubit.dart` checks whether
> `Platform.resolvedExecutable` contains `/CoreSimulator/`, the directory
> every Simulator app bundle lives in, and picks `cpu` only then. No package
> needed. `Platform.environment` would be the obvious check, but it is empty
> inside an iOS app.

**Cost to the user:** none for the manifest entries themselves. GPU inference
draws more instantaneous power than CPU but finishes far sooner, so it usually
wins on battery per answer.

> **Workaround flag:** the Android manifest also declares
> `FOREGROUND_SERVICE_DATA_SYNC`, `POST_NOTIFICATIONS`, and overrides
> WorkManager's `SystemForegroundService` type. That whole block exists
> because Android kills background work at 9 minutes and a 550 MB download on
> conference wifi can exceed that. The download call passes
> `foreground: true`, which shows a progress notification and survives. On
> API 34+ the manifest block is mandatory or that exact call crashes. iOS
> needs none of this, URLSession handles long downloads natively.

## Step 5: One cubit, no layers

**Changed:** `lib/chat/` replaces the template's `lib/counter/`. Same VGV
shape: a barrel file, a cubit with a part-file state, one view file.

`ChatCubit` talks to the `FlutterGemma` facade directly. No repository, no
service, no abstraction between the state machine and the plugin. That is
deliberate: this file may end up on a slide, and every layer between the cubit
and the API would be a slide the audience has to hold in their head.

The state machine is the demo script: `checkingCache`, `needsDownload`,
`downloading`, `loadingModel`, `ready`, `generating`, `error`. Each maps to
exactly one screen in `chat_page.dart`.

**Alternative:** the production shape, a repository wrapping the plugin and a
cubit that is unit-testable with mocks. Say so on stage, then defend the flat
version for demo honesty.

**Cost:** the cubit cannot be unit tested because the plugin's statics hit
native code, so CI excludes `chat_cubit.dart` from coverage. That line in
`.github/workflows/main.yaml` is the price of skipping the repository layer.

## Step 6: The offline path

**Changed:** `ChatCubit.initialize` in `lib/chat/cubit/chat_cubit.dart`.

On every launch the cubit asks `FlutterGemma.isModelInstalled`. That is a
local file check. If the model is cached the app goes straight to loading and
chat, and no code path touches the network. The download screen is only
reachable when the file is missing. This is what makes the airplane-mode
moment safe: after the first download, toggling airplane mode changes nothing
the app can observe.

The green "Offline ready" state in the chat header appears the moment the
cached model is loaded. On camera, point at it, then toggle airplane mode,
then send a prompt.

**Alternative:** checking connectivity and showing offline states. Needless
here, the app does not care about connectivity once the file exists, and
adding a connectivity package would violate the dependency budget.

**Cost to the user:** the check is one stat call, effectively free.

## Step 7: The stat strip, the actual talk

**Changed:** `ChatMetrics` in `lib/chat/cubit/chat_state.dart`, measured in
`chat_cubit.dart`, rendered by `_StatStrip` in `chat_page.dart`.

Five stats, always visible, all measured with nothing beyond the Dart SDK:

- **ON DISK**: `File(path).length()` on the installed model. The honest
  number users pay in storage.
- **COLD LOAD**: a stopwatch around `getActiveModel` plus `createChat`. This
  is flash-to-RAM plus GPU warm-up, paid on every app start. It is the number
  that made you pick a 550 MB model over a 4 GB one.
- **1ST TOKEN**: send to first streamed token. Prefill cost, grows with
  prompt length.
- **TOK/SEC**: decode rate only, counted from the second token so the prefill
  wait does not pollute it. This is the number that visibly drops on weaker
  phones and on CPU fallback.
- **PEAK MEM**: `ProcessInfo.currentRss` sampled at load and on every token,
  labeled approximate because RSS includes the Flutter engine and every other
  allocation in the process.

**Alternative:** platform-channel memory APIs or DevTools for real numbers.
More accurate, but invisible to an audience. Approximate and on-screen beats
precise and hidden for a talk.

**Cost to the user:** a stopwatch read and an RSS read per token, noise
compared to running a transformer.

> **Workaround flag:** tokens per second counts `TextResponse` stream events,
> and one event is not exactly one tokenizer token. The number is directionally
> right and visually honest, which is what a projector needs. Say "approximate"
> on stage and nobody is misled.

## Step 8: Streaming into bloc state

**Changed:** `ChatCubit.sendMessage`.

The plugin returns a `Stream<ModelResponse>`. Each `TextResponse` token is
appended to the last transcript message and re-emitted, so the UI rebuilds per
token and the text visibly types itself. Stop is `chat.stopGeneration()`,
which cancels at the native level; the stream then completes and the cubit
returns to ready on its own.

**Alternative:** `generateChatResponse()`, the blocking call. One emit, no
typing effect, and the app looks frozen for seconds. Streaming is the
difference between "it is thinking" and "it is broken" on camera.

**Cost to the user:** a widget rebuild per token. Trivial next to inference,
and only the transcript subtree rebuilds because the view selects narrow
slices of state.

## Step 9: Projector UI

**Changed:** `lib/app/view/app.dart` and `chat_page.dart`.

Ink on white, set in Geist and Geist Mono, which ship as variable fonts in
`assets/fonts/` so the 450 weight of the design is available through
`fontVariations`. Every screen opens with the same 7 px dot and state label,
recolored per state: muted while idle or busy, amber while downloading, green
when offline ready, blue while generating, red on error. Transcript turns are
role labels over 24 point text rather than bubbles, and the reply that is
still streaming shows a token counter and a blinking caret. All colors and
text styles are constants in `ChatColors` and `ChatText` at the top of
`chat_page.dart`, copied from the design file rather than derived from a
Material seed.

**Alternative:** stock Material theming. Fine for a generic app, but the
design is the point of this one and Material 3 defaults would fight it.

## Step 10: What CI still enforces

`very_good_analysis` passes with zero issues and all 17 tests pass. The tests
cover the state classes, the metric formatting, and every screen state of the
view through a mocked cubit. The workflow change described in step 5 is the
only concession the native plugin forced.

## The gotcha list, confirmed

- **iOS Simulator** must run on the CPU backend, which the app selects on
  its own. The GPU backend loads and streams but the tokens are noise. It
  works for development, but tokens per second and memory are nothing like a
  phone, so demo on a physical device. iPhone 12 or newer works, iPhone 14 Pro or newer looks
  good on camera.
- **Gated models**: both Gemma repos need the license accepted on the
  HuggingFace model page plus a read token, passed at build time through
  `--dart-define-from-file=secrets.json`. A 401 or 403 during download
  surfaces in the app's error screen instead of crashing. Token creation
  steps are in `ONBOARDING.md`.
- **Desktop wants `.litertlm` exclusively.** Irrelevant here since mobile
  LiteRT-LM uses the same file, so this demo never thinks about it.
- **File type routes the engine.** `installModel` defaults to `.task`. Passing
  `ModelFileType.litertlm` explicitly is mandatory or the file is handed to an
  engine that cannot read it. This is the sharpest edge in the current API.

## Running it

Put your HuggingFace token in `secrets.json` at the project root. How to
create one is in `ONBOARDING.md`, or let an agent do the whole setup with the
prompt at the top of `README.md`. Then:

```sh
flutter run --flavor development --target lib/main_development.dart \
  --dart-define-from-file=secrets.json
```

First run: tap download on conference wifi before the talk. Every run after
that needs no token and no network. Rehearse the airplane-mode toggle once so
you trust it.

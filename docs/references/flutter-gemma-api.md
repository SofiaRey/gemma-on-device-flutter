# flutter_gemma API surface used by this repo

Versions in `pubspec.yaml`: `flutter_gemma: ^1.6.5`,
`flutter_gemma_litertlm: ^1.5.2`.

> **⚠️ The API changed at flutter_gemma 1.5 and most training data predates
> it.** Agents confidently write the old `FlutterGemmaPlugin.instance` shape.
> It does not exist anymore. If you are about to type `FlutterGemmaPlugin`,
> `modelManager`, or `createModel`, stop and use the shapes below, verified
> against the code in this repo. When in doubt, check the package docs on
> pub.dev rather than memory.

Wrong (pre-1.5, will not compile):

```dart
final gemma = FlutterGemmaPlugin.instance;
await gemma.modelManager.downloadModelFromNetwork(modelUrl);
final model = await gemma.createModel(modelType: ModelType.gemmaIt);
```

Right (what this repo does):

```dart
// bootstrap.dart: once, before runApp. Engines are separate packages now.
await FlutterGemma.initialize(
  inferenceEngines: const [LiteRtLmEngine()], // from flutter_gemma_litertlm
  huggingFaceToken: token, // nullable, only needed for gated downloads
);
```

## Calls used in `lib/chat/cubit/chat_cubit.dart`

```dart
// Local file check, no network.
final installed = await FlutterGemma.isModelInstalled(modelFileName);

// Download: builder chain, not a single method.
await FlutterGemma.installModel(
  modelType: ModelType.gemmaIt,
  fileType: ModelFileType.litertlm, // MANDATORY, see gotchas
).fromNetwork(modelUrl, foreground: true)
 .withProgress((percent) { /* int 0-100 */ })
 .install();

// Where the installed file lives, used to read its size.
final path = await FlutterGemma.getModelPath(modelFileName);

// Load into RAM. This is the expensive cold-load step.
final model = await FlutterGemma.getActiveModel(
  maxTokens: 2048,
  preferredBackend: PreferredBackend.gpu,
);
final chat = await model.createChat();

// One turn: add the prompt, then stream the reply.
await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
await for (final response in chat.generateChatResponseAsync()) {
  if (response is! TextResponse) continue;
  response.token; // append to transcript
}

// Cancels natively; the stream above then completes on its own.
await chat.stopGeneration();

// In Cubit.close().
await model.close();
```

## Gotchas this repo hit

- **`fileType` routes the engine.** `installModel` defaults to `.task`
  (MediaPipe). Omit `ModelFileType.litertlm` and the `.litertlm` file is
  handed to an engine that cannot read it. Sharpest edge in the API.
- **No registered engine fails at runtime, not compile time.** A
  `StateError` on the first model call. The `initialize` call in
  `lib/bootstrap.dart` is what prevents it.
- **iOS Simulator needs `PreferredBackend.cpu`.** The engine accepts
  `gpu` there and streams deterministic gibberish. This repo checks
  `Platform.resolvedExecutable` for `/CoreSimulator/` and picks `cpu`.
  `Platform.environment` is empty on iOS, so it cannot be used for this. The numbers are
  not representative either way. Use a physical device, iPhone 12 or newer,
  for anything you want to measure or show.
- **Gated model, token at build time.** Both Gemma repos on HuggingFace
  require a one-time access grant. The token travels via
  `--dart-define=HF_TOKEN=...` (this repo uses
  `--dart-define-from-file=secrets.json`, gitignored) into
  `String.fromEnvironment('HF_TOKEN')` in `bootstrap.dart`. A missing or bad
  token surfaces as a 401/403 in the app's error screen during download.
- **Android needs manifest support for both download and GPU.**
  `foreground: true` on `fromNetwork` requires the
  `FOREGROUND_SERVICE_DATA_SYNC` permission, `POST_NOTIFICATIONS`, and the
  WorkManager `SystemForegroundService` override in
  `android/app/src/main/AndroidManifest.xml`, or the call crashes on API 34+.
  The four `uses-native-library` OpenCL entries in the same file keep GPU
  inference from silently falling back to CPU on Android 12+.
- **iOS platform floor is 15.0**, set in `project.pbxproj` (this project uses
  Swift Package Manager, so there is no Podfile to set it in).

# Onboarding

This app runs Gemma 3 1B entirely on your phone: one-time 550 MB download,
then chat that works in airplane mode. Five always-on metric tiles show what
on-device AI really costs, in storage, load time, latency, throughput, and
RAM. The whole feature is one cubit and one page, built to be read on slides.

Prefer to let an AI agent do the setup? Copy the prompt at the top of
[README.md](README.md). It follows [docs/AGENT-SETUP.md](docs/AGENT-SETUP.md),
which is these same steps written for an agent.

**Use a physical phone for the talk. iPhone 12 or newer, iPhone 14 Pro+ to
look good on camera, or an Android phone over USB.** The iOS Simulator works
for development. The app detects it and runs the model on the CPU backend,
because LiteRT-LM's GPU kernels return garbage under the Simulator's emulated
Metal. Expect slower tokens and a stat strip no phone would show.

## Prerequisites

- Flutter 3.44 or newer on the stable channel, with Dart 3.12 or newer (see
  `pubspec.yaml`)
- A HuggingFace account with the Gemma license accepted on
  [litert-community/Gemma3-1B-IT](https://huggingface.co/litert-community/Gemma3-1B-IT)
- A HuggingFace read token, needed only for the first download

## Get a HuggingFace token

The Gemma model repository is gated, so the one-time download needs a token.
It takes about two minutes:

1. Sign in or create an account at https://huggingface.co.
2. Open https://huggingface.co/litert-community/Gemma3-1B-IT and accept the
   Gemma license on the model page. Access is usually granted right away.
   Without this step the download fails with a 401 or 403.
3. Go to https://huggingface.co/settings/tokens and click "Create new token".
   Pick the **Read** type, give it any name, and create it.
4. Copy the token. It starts with `hf_`.

## Setup and run

Create `secrets.json` in the project root. It is gitignored, never commit it.

```json
{ "HF_TOKEN": "hf_your_token_here" }
```

Then:

```sh
flutter pub get
flutter run --flavor development --target lib/main_development.dart \
  --dart-define-from-file=secrets.json
```

Or use the "Launch development" VSCode configuration or the "development"
Android Studio run configuration. Both pass `secrets.json` automatically.

The token reaches the app through `String.fromEnvironment('HF_TOKEN')` in
`lib/bootstrap.dart`. It is compiled in at build time and used only for the
download.

## First run

Tap DOWNLOAD MODEL. It fetches ~550 MB from HuggingFace, with a big on-screen
percentage. Minutes on good wifi, longer on conference wifi, so do it before
the talk. The file caches in the app's documents storage and survives
restarts. Every later launch skips the network entirely.

## The offline demo

1. Run once and let the download finish. The header state turns green:
   Offline ready.
2. Kill the app, enable airplane mode, relaunch.
3. It goes straight to chat. Send a prompt. Rehearse this once so you trust it.

## Troubleshooting

- **401/403 in the error screen during download**: token missing, or the
  Gemma license was not accepted on the model page yet. Check `secrets.json`
  and the model page, then Retry.
- **StateError at first model call**: an engine was not registered. The
  `FlutterGemma.initialize` call in `lib/bootstrap.dart` must run, do not
  bypass `bootstrap`.
- **Slow tokens/sec on iOS**: you are on the Simulator, where the app
  forces the CPU backend. Use a physical phone for representative numbers.
- **Gibberish answers on the Simulator** (a soup of scripts and code
  fragments instead of English): the model ran on the GPU backend. The cubit
  picks CPU whenever the executable path contains `/CoreSimulator/`, so this
  only happens if that check was removed. The model file is fine, do not
  re-download it.
- **Slow tokens/sec on Android**: GPU fell back to CPU. The four OpenCL
  `uses-native-library` entries in `AndroidManifest.xml` must be present.
- **Android download dies mid-way**: the foreground-service manifest block
  was removed, or notifications are blocked. Restore the manifest, allow the
  notification, tap Retry. Partial downloads restart.

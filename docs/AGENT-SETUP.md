# Agent setup guide

You are an AI coding agent and a human asked you to get this project running
on their phone. Follow the steps below in order. Do not skip ahead, do not
improvise around a failing step, and do not change any source code. If a step
fails, tell the human what failed, show the output, and stop.

Rules that hold for the whole session:

- Never invent, guess, or search this machine for a HuggingFace token. The
  human must hand it to you in chat at step 7.
- Never `git add` or commit `secrets.json`. It is gitignored on purpose.
- Prefer a physical phone. The iOS Simulator works, the app switches to the
  CPU backend there, so it is slower and its metrics are not representative.
  Only fall back to it if the human agrees.
- Never add dependencies or edit files under `lib/`, `android/`, or `ios/`.
  This is a setup task, not a code change.

## Step 1: Clone

Skip this if you are already inside the repository.

```sh
git clone https://github.com/SofiaRey/gemma-on-device-flutter.git
cd gemma-on-device-flutter
```

Work from the repository root for every following step.

## Step 2: Check the toolchain

```sh
flutter --version
```

Required: Flutter 3.44 or newer on the stable channel, which ships Dart 3.12
or newer. This matches the constraint in `pubspec.yaml`. If the installed
version is older, tell the human and stop. Do not install or switch Flutter
SDKs on their behalf.

## Step 3: Install dependencies and generate localizations

```sh
flutter pub get
flutter gen-l10n
```

`flutter pub get` normally runs the localization generator on its own because
`pubspec.yaml` sets `generate: true`. Running `flutter gen-l10n` explicitly
costs nothing and guarantees `lib/l10n/gen/` exists before analysis.

## Step 4: Static analysis

```sh
flutter analyze
```

Expected output ends with `No issues found!`. This project uses
`very_good_analysis` with zero tolerated issues. If anything is reported, stop
and show it to the human. Do not fix lint issues yourself.

## Step 5: Tests

If the Very Good CLI is installed, use it. Otherwise fall back to Flutter.

```sh
very_good test
# or
flutter test
```

Expected: every test passes. There are 17 at the time of writing. They cover
state classes, metric formatting, and every screen state of the chat view
through a mocked cubit. The cubit itself talks to the native plugin and is
deliberately untested.

If the test command itself cannot run in your environment, for example a
hook blocks it or the CLI is missing, use whatever test runner your
environment provides for Flutter projects. If none works, report exactly
what blocked it and continue to step 6. Only a failing test is a reason to
stop: that means the code is broken, show the output and wait.

## Step 6: Look for a physical phone

```sh
flutter devices
```

You are looking for a physical iPhone (iPhone 12 or newer) or a physical
Android phone connected over USB. Ignore Chrome and desktop targets. Note the
device id, you need it in step 9.

If no physical phone appears, tell the human: plug the phone in with a cable,
unlock it, tap "Trust this computer" on iOS or enable USB debugging on
Android, then run `flutter devices` again. Offer the iOS Simulator as a
fallback, with the caveat that the app runs on the CPU backend there and
shows unrepresentative metrics. Continue to step 7 either way, the token can be collected while
they find a cable.

## Step 7: Stop and ask the human for a HuggingFace token

Everything up to here works without credentials. The first run needs a
HuggingFace token because the Gemma model repository is gated. You cannot get
this token yourself. Stop here and send the human this message, adapted to
what you found in steps 2 to 6:

> Setup is done: dependencies installed, analysis clean,
> [all tests pass / tests could not run because `<reason>`],
> [phone detected as `<device id>` / no physical phone detected yet].
>
> To run the app I need a HuggingFace token. It is used once, to download the
> 550 MB Gemma model to your phone, and it never leaves your machine or gets
> committed. Here is how to create one, it takes about two minutes:
>
> 1. Sign in or create an account at https://huggingface.co.
> 2. Open https://huggingface.co/litert-community/Gemma3-1B-IT and accept
>    the Gemma license on the model page. Access is usually granted right
>    away. Without this step the download fails with a 401 or 403.
> 3. Go to https://huggingface.co/settings/tokens and click
>    "Create new token". Pick the **Read** type, give it any name, and create
>    it.
> 4. Copy the token. It starts with `hf_`. Paste it here and I will put it in
>    a gitignored `secrets.json` and launch the app.

Then wait. Do not continue until the human pastes a token.

## Step 8: Store the token

Once you have the token, write it to `secrets.json` in the repository root:

```json
{ "HF_TOKEN": "hf_paste_the_token_here" }
```

Confirm it is ignored by git before doing anything else:

```sh
git check-ignore -q secrets.json && echo "secrets.json is ignored"
```

If that prints nothing, stop. Do not run the app and do not stage the file.

## Step 9: Run on the phone (or the Simulator, if the human chose it)

```sh
flutter run --flavor development --target lib/main_development.dart \
  --dart-define-from-file=secrets.json -d <device id>
```

This is the same command the VSCode "Launch development" configuration and
the Android Studio "development" run configuration use.

What the human should see on the phone:

1. A screen headed "Install once, then answer offline." with a Download
   model button under a short spec list. Tell them to tap it.
2. A large percentage counting up while about 550 MB downloads, with the
   bytes, rate, and time left underneath. Minutes on good wifi. On Android a
   progress notification appears, that is expected.
3. A short "Loading model into RAM" screen, then the chat. The header state
   turns green and reads Offline ready.
4. A stat strip stays visible above the chat: on-disk size, cold load time,
   tokens per second, time to first token, and approximate peak memory.

After the first download the app never touches the network again. Suggest the
airplane-mode test: kill the app, enable airplane mode, relaunch, send a
prompt.

## Step 10: Report

Tell the human what you did, in this shape:

- Flutter version found.
- Analysis result and test count.
- Device used, or that none was connected.
- That `secrets.json` was created and confirmed gitignored.
- Whether the app launched and reached the chat screen.

If anything went wrong, the troubleshooting list in `ONBOARDING.md` covers
the known failure modes: 401/403 on download, StateError at first model call,
slow tokens on the Simulator or Android, gibberish answers on the Simulator,
and Android downloads dying mid-way.

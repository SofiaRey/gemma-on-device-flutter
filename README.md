# Gemma on-device Flutter demo

![coverage][coverage_badge]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A Flutter chat app that runs Google's Gemma 3 1B entirely on the phone. One
550 MB download, then chat that works in airplane mode, with five live metric
tiles showing what on-device AI costs in storage, load time, latency,
throughput, and RAM. Built for a 10-minute talk at FCL 2026, so every file is
written to be read on a slide.

> [!NOTE]
> ### Want an AI agent to set this up for you?
>
> Open Claude Code, Cursor, Codex, or any coding agent in the folder where
> you want the project, and paste this:
>
> ```text
> Clone https://github.com/SofiaRey/gemma-on-device-flutter into the current directory. Then read docs/AGENT-SETUP.md inside the cloned repo and follow every step in it, in order, to get the app running on my phone. Stop where the guide tells you to stop and ask me for what it says to ask for.
> ```
>
> The agent installs dependencies, verifies analysis and tests, looks for a
> connected phone, and then asks you for a HuggingFace token with step-by-step
> instructions on how to create one. Nothing runs until you hand over that
> token. The steps it follows are in
> [docs/AGENT-SETUP.md](docs/AGENT-SETUP.md).

## Run it yourself

Use a physical phone for real numbers: iPhone 12 or newer, or an Android
phone over USB. The iOS Simulator also works: the app switches to the CPU
backend there, because the Simulator's GPU path produces garbage, so it is
slower and its metrics are not what a phone shows. Full details, token creation, and
troubleshooting live in [ONBOARDING.md](ONBOARDING.md).

1. Get a HuggingFace read token and accept the license on
   [litert-community/Gemma3-1B-IT](https://huggingface.co/litert-community/Gemma3-1B-IT).
   The steps are in [ONBOARDING.md](ONBOARDING.md#get-a-huggingface-token).
2. Create `secrets.json` in the project root. It is gitignored.

   ```json
   { "HF_TOKEN": "hf_your_token_here" }
   ```

3. Install and run:

   ```sh
   flutter pub get
   flutter run --flavor development --target lib/main_development.dart \
     --dart-define-from-file=secrets.json
   ```

The VSCode "Launch development" configuration and the Android Studio
"development" run configuration pass `secrets.json` for you. The token is
only used for the one-time model download. After that the app runs fully
offline.

## Documentation

| File | Audience | What it covers |
| --- | --- | --- |
| [ONBOARDING.md](ONBOARDING.md) | Humans running the demo | Device requirement, token, run commands, airplane-mode demo, troubleshooting |
| [docs/AGENT-SETUP.md](docs/AGENT-SETUP.md) | AI agents setting the project up | The exact steps behind the prompt above |
| [AGENTS.md](AGENTS.md) | AI agents changing the code | Where to look first, rules for every change |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Anyone touching `lib/` | Code map and the data flow of one inference |
| [docs/HOW_IT_WORKS.md](docs/HOW_IT_WORKS.md) | Speakers and the curious | Why every decision and workaround is the way it is |
| [docs/BUILD-FROM-SCRATCH.md](docs/BUILD-FROM-SCRATCH.md) | Anyone rebuilding this elsewhere | A standalone prompt that recreates the demo from a fresh template |
| [docs/references/flutter-gemma-api.md](docs/references/flutter-gemma-api.md) | Anyone writing `flutter_gemma` code | The exact plugin calls this repo uses |

## Development

The project was generated with the [Very Good CLI][very_good_cli_link] and
keeps its three flavors. They are identical for this demo, use `development`.

```sh
# Analysis, must report zero issues
flutter analyze

# Tests with coverage
very_good test --coverage --test-randomize-ordering-seed random

# Bloc lint
dart run bloc_tools:bloc lint .
```

To view the coverage report, run `genhtml coverage/lcov.info -o coverage/`
and open `coverage/index.html`.

User-facing strings live in `lib/l10n/arb/` as ARB files, English and
Spanish. Add a key to `app_en.arb` and `app_es.arb`, then run
`flutter gen-l10n` or just `flutter run`, which regenerates them. New locales
also need an entry in `CFBundleLocalizations` in `ios/Runner/Info.plist`. See
the [Flutter internationalization guide][internationalization_link].

[coverage_badge]: coverage_badge.svg
[internationalization_link]: https://docs.flutter.dev/ui/internationalization
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_cli_link]: https://github.com/VeryGoodOpenSource/very_good_cli

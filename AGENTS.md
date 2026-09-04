# AGENTS.md

Conference demo for a 10-minute talk: a Flutter chat app that runs Gemma 3 1B
fully on-device with `flutter_gemma`. Any file here may end up on a slide, so
the one constraint that governs everything is: readability beats abstraction.

## Were you asked to set this project up, not change it?

Follow `docs/AGENT-SETUP.md` step by step and stop where it tells you to. It
ends by asking the human for a HuggingFace token, which you cannot obtain
yourself. Nothing below applies to a setup task.

## Where to look

- `ARCHITECTURE.md`: code map and the data flow of one inference. Read before
  touching anything in `lib/`.
- `docs/references/flutter-gemma-api.md`: the exact `flutter_gemma` calls this
  repo uses. Read before writing any `flutter_gemma` code. The API changed at
  1.5 and your training data is stale.
- `docs/HOW_IT_WORKS.md`: step-by-step rationale for every decision and
  workaround. Read when you need to know why something is the way it is.
- `ONBOARDING.md`: human setup, token creation, run commands, troubleshooting.
- `docs/AGENT-SETUP.md`: the same setup written as steps for an agent.
- `docs/BUILD-FROM-SCRATCH.md`: standalone rebuild prompt. Not needed for
  changes to this repo.

## Rules for every change

- `very_good_analysis` must pass with zero issues. Run `flutter analyze`.
- No new dependencies without asking first.
- No routing, no onboarding flow, no settings screen, no layered
  architecture. One cubit talking straight to the plugin is the design,
  not a shortcut.
- The HuggingFace token lives only in `secrets.json`, which is gitignored,
  and reaches the build through `--dart-define-from-file=secrets.json`. Never
  hardcode it, never commit it, never log it.

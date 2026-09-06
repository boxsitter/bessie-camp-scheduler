# Bessie

**A cross-platform camp activity scheduling and logistics manager, built with Flutter.**

Bessie helps summer-camp staff manage rosters, sessions, and the genuinely hard part of running a camp: assigning hundreds of campers to activities each day while respecting capacities, avoiding repetition, and honoring as many camper preferences as possible. It was originally built for a real YMCA camp and pairs a polished desktop/web UI with a constraint-based scheduling engine.

> **Status:** Portfolio project. The scheduling engine, data model, and UI are functional; some administrative flows are still stubbed. Backed by Firebase (Firestore + Auth).

<!-- TODO: add a screenshot or short GIF here — it's the single highest-impact thing you can add.
     e.g. ![Bessie roster view](docs/screenshot-rosters.png) -->

---

## Highlights

- **Constraint-based scheduling engine** — a pluggable pipeline that assigns campers to activities under real-world constraints, with two interchangeable strategies and per-step satisfaction reporting. ([details below](#the-scheduling-engine))
- **Rich desktop-class UI** — responsive layouts, a theming system (Catppuccin-based palettes), custom widgets, and an embedded terminal/console.
- **In-app command console** — an `xterm`-powered console with a typed command system for power users and debugging.
- **Live, offline-capable data** — reactive Firestore repositories with a commit-based mutation model.
- **Cross-platform** — one codebase targeting web, Windows/macOS/Linux desktop, and mobile.

## Features

| Area | What it does |
|------|--------------|
| **Rosters** | Import (CSV), search, and manage camper rosters in an editable data table |
| **Activity preferences** | Collect and rank camper activity choices (ranking & absolute modes) |
| **Scheduling** | Generate day/session schedules from preferences via the assignment engine |
| **Sessions & branches** | Manage organizations, branches, seasons, and sessions |
| **Console** | Run typed commands against the core services from an in-app terminal |
| **Auth** | Firebase-backed login, password reset, and user management |

## The scheduling engine

The heart of the project (`lib/src/algorithms/`) is a small framework for solving camper-to-activity assignment as a constraint-satisfaction problem.

- **Pipeline architecture** — an `AlgorithmPipeline` runs an ordered list of `AlgorithmStep`s over an `AssignmentContext`, producing an `AssignmentResult` with a **timed report for every step**, so runs are inspectable and debuggable.
- **Two strategies** —
  - *Greedy scoring*: scores every candidate assignment and fills greedily.
  - *Diplomatic*: a fairness-oriented approach that balances request fulfillment across participants and handles over-subscribed activities.
- **Constraints** (composable) — capacity limits, no adjacent-period repetition, no double-booking, and same-day / weekly repetition caps.
- **Evaluation** — satisfaction and novelty evaluators score how well an assignment honors preferences, driving the diplomatic strategy and surfacing quality metrics.

```
lib/src/algorithms/
├── algorithm_pipeline.dart      # runs steps, times them, collects reports
├── data_models/                 # AssignmentContext / Result, pipeline state, analogs
├── common/
│   ├── constraints/             # capacity, repetition, double-schedule, …
│   └── steps/                   # generate → sort → process assignments
├── greedy_scoring_algorithm/
├── diplomatic_algorithm/
└── evaluation/                  # satisfaction & novelty scoring
```

## Architecture

A single, standard Flutter package. State management and dependency injection use [GetX]; the UI is composed from a shared widget/theme library and feature modules.

```
lib/
├── main.dart                # bootstrap: Firebase, error handling, window setup
├── firebase_options.dart
└── src/
    ├── app.dart             # root MaterialApp + routing
    ├── features/            # screens: rosters, schedule, activity_preferences, console, auth, …
    ├── shared/              # shared widgets, theme, constants, utils, services
    ├── models/              # domain objects (camps, sessions, campers, schedules)
    ├── repositories/        # Firestore data access (pull / commit / live)
    ├── services/            # business logic, orchestration (GetX services)
    ├── algorithms/          # the scheduling engine (above)
    ├── commands/            # console command definitions
    └── cli/                 # console I/O primitives
```

> **Design note:** an earlier version of this project was split across four packages to keep a hard boundary between UI, domain, and Firebase layers. That boundary still lives on as the `frontend`/repository interfaces, but the code is now a single idiomatic Flutter app — the layering is expressed through folders and interfaces rather than package boundaries.

## Tech stack

- **Framework:** Flutter (Dart)
- **State / DI:** GetX
- **Backend:** Firebase — Firestore, Auth, Crashlytics, Analytics
- **UI:** shadcn_ui, Lottie, custom theming
- **Monitoring:** Sentry
- **Docs/exports:** PDF & CSV generation

## Getting started

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel, Dart 3.7+).

```bash
flutter pub get
flutter run          # or: flutter run -d chrome
flutter build web    # release web build
```

Firebase is configured via `firebase_options.dart` (client keys are public by design). To run against the local emulator instead of production, start it with `scripts/start_firestore_emu.ps1` and enable the emulator flag in the debug config.

## About

Built by Leyton Houck. Bessie began as a summer internship project for a YMCA camp and grew into a full scheduling application; this repository is a cleaned-up, single-package version of that work.

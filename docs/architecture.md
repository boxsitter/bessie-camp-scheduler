# Architecture

Bessie is a single Flutter app (web, desktop, mobile) on top of a Supabase (Postgres) backend. This page explains
how the code is organized and why. For the database itself see [database.md](database.md).

## Layers

```
┌────────────────────────────── lib/src ───────────────────────────────┐
│ features/ + shared/   screens, GetX controllers, widgets, theme        │  UI
├────────────────────────────────────────────────────────────────────────┤
│ services/             use cases: sign-in, camp context, auto-assign,   │  application
│                       CSV import, backups                              │
├────────────────────────────────────────────────────────────────────────┤
│ data/                 repositories: the only code that talks to        │  data access
│                       Supabase (PostgREST, RPC, Realtime, Auth)        │
├────────────────────────────────────────────────────────────────────────┤
│ models/               immutable domain objects + row codecs            │  domain
│ algorithms/           the scheduling engine: pure Dart, no I/O         │
│ core/                 config, logging, error mapping                   │
└────────────────────────────────────────────────────────────────────────┘
```

Dependencies only point downwards. In particular:

* **`algorithms/` imports nothing from the app.** It takes plain data in (`AssignmentContext`) and returns plain data
  out (`AssignmentResult`), so it is exhaustively unit-tested without a database or Flutter.
  `services/assignment_service.dart` is the adapter that loads a session, builds the context, runs the engine and
  stores the result in one transaction.
* **Only `data/` knows table and column names.** Repositories return domain models (`Camper`, `Schedule`, …) and
  throw `AppException` with a message that is safe to show a user.
* **Controllers never build SQL or handle `PostgrestException`.** They call repositories/services and report failures
  with `Toast.failure`.

## Startup

`main.dart` → `app/bootstrap.dart`:

1. Install error handlers (`core/error_reporter.dart`) and, if a DSN was configured, Sentry.
2. `Supabase.initialize` with `--dart-define` settings (`core/app_config.dart`; defaults to the local stack).
3. `AppBindings.registerCore` (`app/bindings.dart`) creates the repositories and services and registers them with
   GetX. This is the only place dependencies are wired together.
4. Restore a saved session, if any. If the user is signed in, `AppBindings.onSignedIn` loads the camp context
   (organization → branch → season → session) and creates the page controllers; otherwise the router sends them
   to the login screen.

Signing out calls `AppBindings.onSignedOut`, which tears the page controllers down again.

## The camp context

`ContextService` holds where the user is working. `session` is a reactive value: when the user picks another
session in the header, every controller that holds session-scoped data reloads (`ever(context.session, …)`). The
last session used is remembered in the user's profile.

## Data flow

* **Reads.** Repositories use PostgREST embedded selects so one request returns a camper with its assignments and
  preferences. The roster is a stream (`RosterRepository.watchCampers`): it subscribes to Realtime changes for the
  session and refetches (debounced) on any change, so several people can work on the same session.
* **Writes.** Simple edits are table updates; anything that must be atomic or needs rules RLS can't express is a
  Postgres function called through `rpc()` (`assign_campers`, `set_camper_preferences`, `import_campers`,
  `apply_assignments`, …). The database, not the app, is the authority on integrity, limits and permissions.
* **Permissions.** Row level security enforces who can read or write what (see [database.md](database.md#security));
  the UI additionally hides controls the user's role can't use (`StaffRole.canEditSessionData`).

## Time and dates

The camp lives in one place, so dates and times are **wall-clock values with no timezone**: `date` / `time`
columns in Postgres, local midnight `DateTime`s and `Duration`s since midnight in Dart (`models/row_codec.dart`). The
old app stored local times as UTC and birthdates at 21:00 UTC; none of that exists any more.

## The scheduling engine

`algorithms/` is a small framework: an `AlgorithmPipeline` runs ordered `AlgorithmStep`s over a shared state and
records a timed report per step. Two strategies share the pipeline and differ in their scorer — *diplomatic*
(requests outrank novelty outrank repeats; the default) and *greedy*. Hard rules are composable `Constraint`s
(capacity, adjacent repetition, double-block feasibility, max assignments per activity). See the folder's own README
for the details.

## Errors and messages

* `AppException(message)` carries text meant for people. `AppException.from(error)` maps Postgres, Auth and network
  failures to friendly messages.
* `Toast.success/info/warning/error/failure` is how the UI talks to users; `log` (package `logger`) is for developers.
* Uncaught errors end up in `ErrorReporter`: logged, toasted and (if configured) sent to Sentry **without** user
  details, because this app handles children's data.

## Testing

| What | Where | Run |
|---|---|---|
| Database integrity, RPCs, RLS | `supabase/tests/database/*.test.sql` (pgTAP) | `supabase test db` |
| Repositories against the real stack | `test/integration/` (tag `integration`) | `flutter test --tags integration` |
| Algorithms, models, services, controllers' pure logic | `test/**` | `flutter test --exclude-tags integration` |
| Firestore migration transform | `tools/firestore-migration/test` | `npm test` there |

Integration tests skip themselves when the local stack isn't running. CI runs everything
(`.github/workflows/ci.yml`).

## Conventions

* One import style: targeted `package:bessie/...` or relative imports. No barrel files that re-export the world.
* Ids are UUID strings; the models don't wrap them in types.
* Page controllers extend `GetxController` and mix in `RouteAwareControllerMixin` to learn when their page is shown.
* New table → RLS + policies + (if the app listens) the realtime publication, in a new migration.

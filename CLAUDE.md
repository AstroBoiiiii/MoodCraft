# CLAUDE.md — MoodCraft

Persistent context for this project. Read it before writing code; keep it current.

## Project context
- **Final-year CS student project.** Graded by a **live demo on laptop + one Android phone.** Optimise for demo, not production.
- **Do NOT publish, sign, or do store/release work.** Not now. Stop and ask if a task heads that way.
- **Android (mobile) + Web only.** No iOS/macOS.
- **Dev runs on Web/Chrome** by default.
- **Firebase** is the backend — **configured** (project `moodcraft-d9930`, Auth + Firestore enabled, `firebase_options.dart` generated).
- **Demo scope:** keep it simple and working. Do not over-engineer. If it works for the demo, ship it.
- **Language:** English only for now. BM (Malay) and full FR15 multi-language support are deferred — implement after core features are working. Do not add BM strings or arb entries until asked.
- **Role labels:** "Student", "Teacher", "Parent" — never "I am a student" style copy.
- **Profile editing:** all profile screens use view mode by default; user must tap Edit first, then Confirm or Cancel.
- **Username:** every user registers a username (lowercase, letters/digits/underscores). Used as alternate sign-in (email OR username). Stored in `usernameDirectory/{username}` → `{uid, email}` for pre-auth lookup.
- **DEMO-GRADE rules:** `users/{uid}` read is open to any signed-in user (so teacher/parent detail screens can show linked contacts). Tighten before any real data.

## What it is
MoodCraft teaches **emotion recognition to primary-school children with ASD**, and keeps their **teachers and parents** connected to that learning. A special-needs tool, not a general kids' app. Filter every decision through: *is this calm, predictable, supportive for an autistic child?* If it adds stress, surprise, time pressure, or a sense of failure, it's wrong here.

Built with **Flutter** (Android + Web) and **Firebase**.

## Roles & platforms
All three roles use the **Android (mobile)** app. Teacher additionally has a **Web** app.

- **Student** — Android only. Icon-led + audio narration; never depends on reading.
- **Parent** — Android. Monitors child, reads notes, messages teacher. Can share device with child at registration.
- **Teacher** — Android **and** Web. Web is for classroom projection (material shown on laptop/projector) and office-work environment (dashboard, reports, messaging). All features available on mobile too.

**AI Companion (FR3):** Mobile only — not available on the web app.
**AR (FR4):** Mobile natively (ARCore). On the web classroom view, teacher connects a mobile device whose camera feeds the AR experience to the projected screen — web itself has zero native camera/AR deps.

Mobile = all roles. Web = teacher's classroom + office layer only.

## Functional requirements (grading checklist)
| FR | Requirement | Feature | Roles |
|---|---|---|---|
| FR1 | ✓ Multi-role register/login; per-role UI; email-invite linking (auto-resolve + pending fallback); class code join; web teacher-only gate *(device-sharing deferred)* | Auth + role routing | S,T,P |
| FR2 | ✓ Student profiles: details, age category, language, sensory settings (music, volume, theme, animation intensity) | Profiles | T,P |
| FR3 | AI companion teaches emotion via face + body; always calm/patient/consistent; **BM + English** | AI Companion | S |
| FR4 | AR emotion learning: camera + live 3D; **home mode** (1:1) and **classroom projection** | AR Emotion | S,T |
| FR5 | Cartoon story mode: pauses at emotional moments to ask feelings; levels unlock; teacher launches from web | Story Mode | S,T |
| FR6 | ✓ Mix-and-match: drag a card (face/body/situation/word) onto the matching emotion bucket; 4 card types = 4 levels (concrete→abstract), 6 fixed buckets, gentle redirect on wrong, no negativity; teacher classroom launch *(rewards + real TTS deferred)* | Mix-and-Match | S,T |
| FR7 | Stress-free quiz: sound/image/audio prompts; always encouraging; no timer, no competitive score | Quiz | S,T |
| FR8 | Teacher dashboard: assigned students' progress, difficulty areas, trends | Teacher dashboard | T |
| FR9 | Parent dashboard + real-time notifications (task done, milestone, teacher update) | Parent monitoring + FCM | P |
| FR10 | ✓ In-app teacher↔parent messaging: updates, recommendations, links; parents report home observations | Messaging | T,P |
| FR11 | Rewards/levels: stars, badges, unlockables; digital only, non-food, non-competitive | Rewards | S |
| FR12 | ✓ Emotion journal: log feelings with icons (no reading/writing); visible to teacher + parent | Journal | S,T,P |
| FR13 | ✓ Visual schedule: predictable picture schedule of what's next; set by teacher/parent | Visual Schedule | S,T,P |
| FR14 | Offline: games, activities, journal, schedule work offline; auto-sync when back online | Firestore persistence | S,P |
| FR15 | Dual language **BM + English** (UI, narration, content); pick at registration, change in settings | l10n (en + ms) | All |

✓ = implemented and wired. Unmarked = calm placeholder or not built yet (FR3–FR5, FR7–FR9, FR11). FR14 offline persistence is on (Firestore cache) and already covers the built data features; FR15 is English-only for now (see Project context).

**Rewards are deferred (intentional).** We complete each feature first, then do the FR11 rewards/celebration pass (stars/badges/unlockables) across all of them at the end. So a built activity shows a calm "all done" moment but no stars yet — don't add per-feature reward UI until the FR11 pass.

## Tech stack
- **Flutter** (stable, null-safe), **Riverpod** for all state.
- **Firebase**: Auth, Firestore, Cloud Messaging (FR9). Init via FlutterFire CLI (`firebase_options.dart`). **Storage excluded** — not on Blaze plan; use local assets instead.
- **Offline (FR14):** Firestore offline persistence is **on** (`core/firebase/bootstrap.dart`); journal, schedule and messages already read/write through the local cache and sync when back online. `syncStatus` (`pending`/`synced`) is stored on records for a future offline indicator. No hand-rolled cache.
- **AI (FR3, teacher reports):** Firebase AI Logic → Gemini `gemini-2.5-flash-lite`. Key stays server-side; needs Blaze. Keep model name a constant/Remote Config value.
- **Voice:** `speech_to_text` + `flutter_tts` (device, free). Companion takes typed or spoken input.
- **2D companion:** **Rive** state machine (face + body). **AR:** ARCore + 3D `.glb` on detected planes, Android 7+, with non-AR fallback.
- **l10n (FR15):** Flutter `l10n`, arb files `en` + `ms`, covering UI, narration, content.

Visual split: **2D Rive = companion, 3D `.glb` = AR.** Don't mix.

## Design principles (non-negotiable)
1. **No failure states** — no buzzers, red X, "wrong!", dropping scores, timers, losing. Wrong answer → gentle redirect, calm retry.
2. **Predictable & consistent** — same layouts, navigation, character behaviour. No surprise animations or autoplay sound.
3. **Sensory-adjustable (FR2)** — every activity respects music/volume/theme/animation settings.
4. **Icon-led, low-literacy** — pictures + audio first, text second; narration everywhere.
5. **Large tap targets, one action per screen.** Calm soft colours, generous spacing, no flashing.
6. **Child never talks to a raw LLM for core teaching** — teaching content is vetted/cached. Live Gemini only for the optional safe-prompted companion chat and teacher-facing notes.

## Structure (feature-first)
```
lib/
  main.dart  firebase_options.dart
  app/      app.dart  router.dart  theme/
  core/     models/  services/  providers/  widgets/  utils/
  features/
    auth/
    student/  companion/ ar/ story/ mix_match/ quiz/ journal/ schedule/ rewards/
    teacher/  dashboard/ profiles/ classroom/ messaging/ reports/
    parent/   monitoring/ messaging/
  l10n/                     # en + ms arb
assets/  rive/  models/  images/  audio/
```

## Where features live (built so far)
- **FR1 auth/linking:** `core/services/auth/` + `data/linking_service.dart`; screens in `features/auth/`; redirects in `app/router.dart`.
- **FR2 profiles + sensory:** `features/account/account_profile_screen.dart`, `features/teacher/student_profile_detail_screen.dart`, `core/widgets/sensory_settings_sheet.dart`; theming in `app/theme/`.
- **FR10 messaging:** `features/teacher/messaging_thread_screen.dart`; conversation providers in `core/providers/repository_providers.dart`.
- **FR12 journal:** `features/journal/journal_section.dart` — `JournalLogger` (child) + `JournalHistorySection` (shared). Any signed-in role (teacher, parent, or optionally the child) can leave one role-labelled `JournalComment` per entry (`commentBy`/`withComment` on the model); comments render distinctly ("Teacher: …"). Embedded by the student tab and both detail screens, mirroring the schedule pattern.
- **FR13 schedule:** `features/schedule/schedule_section.dart` (`StudentScheduleSection`, `canEdit`).
- **FR6 mix-and-match:** `features/mix_match/` — `mix_match_screen.dart` (level select + shared `MixMatchLevelGrid`), `mix_match_play_screen.dart` (drag-to-bucket round, writes a `Session`), `mix_match_data.dart` (`buildMixMatchDeck` auto-discovers card art from the asset manifest under `assets/images/mixmatch/<type>/<emotion>_<n>.png`; words/situations from `kMixMatchWords`/`kMixMatchSituations`). Level progress = `Student.mixMatchLevel`. Teacher classroom launch in `TeacherProfilesScreen`.
- **Data + models:** interfaces in `core/services/data/repositories.dart`, all Firestore in `firestore_repositories.dart`; models in `core/models/` round-trip via `toJson`/`fromJson` (locked by `test/models_test.dart`). Rules in `firestore.rules`.

## Firestore model
All activity/journal records carry `syncStatus` + `timestamp`.
- `users/{uid}` — role, name, email, phone, language, linkedStudentIds[]
- `students/{id}` — name, avatar, ageCategory, language, teacherIds[], parentIds[], sensorySettings, level, stars, badges[]
- `classes/{id}` — name, classCode (6-char uppercase), teacherId *(FR1 — teacher created at registration)*
- `pendingLinks/{id}` — studentEmail, parentEmail, initiatorUid, initiatorRole *(deleted on resolution)*
- `emailDirectory/{email}` — uid, role *(written at registration; used for invite resolution)*
- `sessions/{id}` — studentId, activityType, emotionsShown[], responses[], correctCount, retries, durationMs, timestamp, syncStatus
- `journalEntries/{id}` — studentId, emotionIcon, contextIcon?, comments[] (role-labelled), timestamp, syncStatus
- `messages/{id}` — fromUid, toUid, studentId, text, timestamp, read
- `observationReports/{id}` — studentId, generatedText, basedOnSessionIds[], dateRange, createdBy, timestamp
- `emotionContent/{id}` — emotion, language, prompt, options[], feedback (curated, offline-capable)
- `visualSchedules/{id}` — studentId, items[], createdBy

Rules: a user reads/writes only their own record + linked students. Students can't read messages or other students' data. Lock down before real data.

## Conventions
- Riverpod everywhere; no global mutable singletons.
- Data access goes through `core/services/data/repositories.dart`; every implementation is Firestore-backed. The `Stub*`/`DevSeed` path is **auth-only** (`--dart-define=USE_STUB_AUTH=true`), not a data backend.
- Guard all AR/camera/AI-companion code behind `kIsWeb`; web build must reach zero ARCore/camera deps. Web AR = receive a stream from a connected mobile device, not native camera access.
- All UI strings via `l10n`. **English is the source of truth:** add keys to `lib/l10n/app_en.arb` only, then run `flutter gen-l10n`. `ms` auto-falls back to English until the deferred BM pass — don't hand-add `ms` strings yet.
- Respect `sensorySettings` in every activity.
- Gemini: system prompt = calm, patient, positive-only, child-safe, short sentences, emotions-only, gently redirect off-topic. Request structured JSON; parse defensively.
- Round any number shown; never raw floats. No secrets/API keys in the repo.

## Asset strategy — placeholders first
Build logic/layout now with stand-in art; swap real art later with no code change. Companion = enum-keyed expressions (`happy, sad, scared, angry, surprised, neutral`). The journal + emotion pickers reuse that same set via `kEmotionIcon`/`kEmotionColor`; schedule pictures via `kScheduleIconCatalog` — all in `core/constants/app_constants.dart`. AR = placeholder `.glb` via a config map of paths. Centralise every asset path in one constants file.

## Build order
0. ✓ Foundation: scaffold, design system + sensory theming, role routing, FR1 auth + linking. Firebase configured.
1. ✓ Vertical slice — Emotion Journal (FR12) end-to-end: student logs → Firestore → teacher/parent view. Also done: FR13 visual schedule, FR10 teacher↔parent messaging, FR2 profiles + sensory settings.
2. **Next — Signature features:** AR → AI Companion → Story → Mix-and-Match → Quiz (all currently calm placeholders behind the student home menu).
3. Teacher portal (dashboard/reports, FR8) + Parent monitoring/notifications (FR9, FCM).
4. Offline indicator polish, accessibility, demo prep; deferred BM (FR15) pass.

**Deploy rules before real data:** `firebase deploy --only firestore:rules`

## Don't
- No fail states, buzzers, red X, timers, punitive scoring.
- No autoplay sound or surprise animations.
- No AR/camera reachable in web build.
- No raw LLM output shown to a child as a lesson.
- No iOS/macOS, no release/signing/publishing.
- No secrets in repo. No features outside FR1–FR15 without asking.

## Commands
```bash
flutter pub get
flutter run -d chrome        # default dev target
flutter run -d android       # mobile build
flutter analyze
dart format lib/
flutter test
```
Dart SDK `^3.7.0`; lints via `flutter_lints`.

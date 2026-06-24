# CLAUDE.md — MoodCraft

Persistent context for this project. Read it before writing code; keep it current.

## Project context
- **Final-year CS student project.** Graded by a **live demo**, not by shipping. Optimise for the demo.
- **Do NOT publish, sign, or do store/release work.** Not now. Stop and ask if a task heads that way.
- **Android (mobile) + Web only.** No iOS/macOS.
- **Dev runs on Web/Chrome** by default (Windows Dev Mode off → native plugin builds can fail locally).
- **Firebase** is the backend — **configured** (project `moodcraft-d9930`, Auth + Firestore enabled, `firebase_options.dart` generated).

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
| FR1 | Multi-role register/login; per-role UI; parent can share device at registration | Auth + role routing | S,T,P |
| FR2 | Student profiles: details, age category, language, sensory settings (music, volume, theme, animation intensity) | Profiles | T,P |
| FR3 | AI companion teaches emotion via face + body; always calm/patient/consistent; **BM + English** | AI Companion | S |
| FR4 | AR emotion learning: camera + live 3D; **home mode** (1:1) and **classroom projection** | AR Emotion | S,T |
| FR5 | Cartoon story mode: pauses at emotional moments to ask feelings; levels unlock; teacher launches from web | Story Mode | S,T |
| FR6 | Mix-and-match faces↔emotion/situation; audio narration; gentle redirect on wrong, no negativity | Mix-and-Match | S,T |
| FR7 | Stress-free quiz: sound/image/audio prompts; always encouraging; no timer, no competitive score | Quiz | S,T |
| FR8 | Teacher dashboard: assigned students' progress, difficulty areas, trends | Teacher dashboard | T |
| FR9 | Parent dashboard + real-time notifications (task done, milestone, teacher update) | Parent monitoring + FCM | P |
| FR10 | In-app teacher↔parent messaging: updates, recommendations, links; parents report home observations | Messaging | T,P |
| FR11 | Rewards/levels: stars, badges, unlockables; digital only, non-food, non-competitive | Rewards | S |
| FR12 | Emotion journal: log feelings with icons (no reading/writing); visible to teacher + parent | Journal | S,T,P |
| FR13 | Visual schedule: predictable picture schedule of what's next; set by teacher/parent | Visual Schedule | S,T,P |
| FR14 | Offline: games, activities, journal, schedule work offline; auto-sync when back online | Firestore persistence | S,P |
| FR15 | Dual language **BM + English** (UI, narration, content); pick at registration, change in settings | l10n (en + ms) | All |

## Tech stack
- **Flutter** (stable, null-safe), **Riverpod** for all state.
- **Firebase**: Auth, Firestore, Cloud Messaging (FR9). Init via FlutterFire CLI (`firebase_options.dart`). **Storage excluded** — not on Blaze plan; use local assets instead.
- **Offline (FR14):** Firestore offline persistence; add `syncStatus` (`pending`/`synced`) for an offline indicator. No hand-rolled cache.
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

## Firestore model
All activity/journal records carry `syncStatus` + `timestamp`.
- `users/{uid}` — role, name, email, language, linkedStudentIds[]
- `students/{id}` — name, avatar, ageCategory, language, teacherIds[], parentIds[], sensorySettings, level, stars, badges[]
- `sessions/{id}` — studentId, activityType, emotionsShown[], responses[], correctCount, retries, durationMs, timestamp, syncStatus
- `journalEntries/{id}` — studentId, emotionIcon, contextIcon?, note?, timestamp, syncStatus
- `messages/{id}` — fromUid, toUid, studentId, text, timestamp, read
- `observationReports/{id}` — studentId, generatedText, basedOnSessionIds[], dateRange, createdBy, timestamp
- `emotionContent/{id}` — emotion, language, prompt, options[], feedback (curated, offline-capable)
- `visualSchedules/{id}` — studentId, items[], createdBy

Rules: a user reads/writes only their own record + linked students. Students can't read messages or other students' data. Lock down before real data.

## Conventions
- Riverpod everywhere; no global mutable singletons.
- Guard all AR/camera/AI-companion code behind `kIsWeb`; web build must reach zero ARCore/camera deps. Web AR = receive a stream from a connected mobile device, not native camera access.
- All UI strings via `l10n` (en + ms); companion content supports both languages.
- Respect `sensorySettings` in every activity.
- Gemini: system prompt = calm, patient, positive-only, child-safe, short sentences, emotions-only, gently redirect off-topic. Request structured JSON; parse defensively.
- Round any number shown; never raw floats. No secrets/API keys in the repo.

## Asset strategy — placeholders first
Build logic/layout now with stand-in art; swap real art later with no code change. Companion = enum-keyed expressions (`happy, sad, scared, angry, surprised, neutral`). AR = placeholder `.glb` via a config map of paths. Centralise every asset path in one constants file.

## Build order
0. Foundation: scaffold, design system + sensory theming, role routing. ✓ Firebase done.
1. Vertical slice: Emotion Journal end-to-end (student → Firestore → teacher).
2. Signature features: AR → AI Companion → Story → Mix-and-Match → Quiz.
3. Teacher portal + Parent monitoring/notifications.
4. Offline polish, accessibility, demo prep.

Don't jump ahead before Phase 0 is solid.

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

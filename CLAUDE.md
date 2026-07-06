# CLAUDE.md — MoodCraft

Persistent context for this project. Read it before writing code; keep it current.

## Project context
- **Final-year CS student project.** Graded by a **live demo on laptop + one Android phone.** Optimise for demo, not production.
- **Do NOT publish, sign, or do store/release work.** Not now. Stop and ask if a task heads that way.
- **Android (mobile) + Web only.** No iOS/macOS.
- **Dev runs on Web/Chrome** by default.
- **TEMPORARY:** the teacher-only web gate is disabled in `app/router.dart` so every role can be tested on Chrome while the UI is being finished. Re-enable it before the demo (student and parent are mobile-only in the final product; the `/mobile-only` route and `WebMobileOnlyScreen` are kept for reinstatement).
- **Firebase** is the backend — **configured** (project `moodcraft-d9930`, Auth + Firestore + AI Logic enabled, `firebase_options.dart` generated).
- **Before-the-demo checklist:** re-enable the teacher-only web gate (below), and switch the Gemini Developer API to the paid tier (see Tech stack, AI) so the companion chat cannot hit the free daily quota mid-demo.
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
**AR (FR4):** Mobile natively via **WebAR (MindAR image tracking in a WebView)** — vision-only marker tracking, **no ARCore anywhere** (never add `com.google.ar` meta-data; the app must stay installable on uncertified phones like the test Realme Note 50). On the web classroom view, teacher connects a mobile device whose camera feeds the AR experience to the projected screen — web itself has zero native camera/AR deps.

Mobile = all roles. Web = teacher's classroom + office layer only.

## Functional requirements (grading checklist)
| FR | Requirement | Feature | Roles |
|---|---|---|---|
| FR1 | ✓ Multi-role register/login; per-role UI; email-invite linking (auto-resolve + pending fallback); class code join; web teacher-only gate *(device-sharing deferred)* | Auth + role routing | S,T,P |
| FR2 | ✓ Student profiles: details, age category, language, sensory settings (music, volume, theme, animation intensity) | Profiles | T,P |
| FR3 | AI companion teaches emotion via face + body; always calm/patient/consistent; **BM + English** *(Milestone 1 ✓: calm screen with curated lessons + safe Gemini chat, typed/spoken input that auto-sends, AI Logic verified. Milestone 2 underway: full-body 3D talking avatar — TalkingHead + RPM + Mixamo + TTS lip-sync + Gemini teaching loop, see Tech stack)* | AI Companion | S |
| FR4 | AR emotion learning: camera + live 3D; **home mode** (1:1) and **classroom projection** *(Milestones 1+2 done: WebAR marker tracking with custom pose smoothing; all five emotion characters animated on the printed card, swapped via in-page picker. Teaching layer + modes next)* | AR Emotion | S,T |
| FR5 | ✓ Story mode: bundled film on a contained video page (tap film or button to play/pause, never autoplays, no full screen); pauses at configured emotional moments to ask quiz-style beneath the film (per-pause ask line naming who to think about, 3 choices, short text feedback — no TTS in story mode, gentle redirect); each story = one continuous film carved into 3 episodes by start/end timestamps, episodes unlock in order, all stories open; resumes at the exact pause point; teacher classroom launch. All three stories are fully wired: "The Present", "Watermelon", "Pip" | Story Mode | S,T |
| FR6 | ✓ Mix-and-match: drag a card (face/body/situation/short-story) onto the matching emotion bucket; 4 card types (concrete→abstract; story = read & interpret, hardest), all always open (no level gating — a calm "rounds done" count instead), 5 fixed buckets (happy/sad/scared/angry/surprised — `neutral` excluded), gentle redirect on wrong, no negativity; teacher classroom launch; text cards narrate aloud via device TTS *(rewards deferred)* | Mix-and-Match | S,T |
| FR7 | ✓ Stress-free quiz: one calm mixed round asks a feeling three ways (look at a face/scene image, listen to a sound cue, hear a short spoken story); 3 feeling choices, tap to answer; warm spoken feedback on a right tap tailored to that face/sound/story (Next cuts the narration), gentle "look again" redirect on a wrong one; no timer, no score; three daily sets (Today/Yesterday/Day before) chosen by the real date, each a fixed curated arrangement of one question per feeling with no face/sound/story reused across the three sets; resumes where the child left off; art/cues auto-discovered by filename; teacher classroom launch | Quiz | S,T |
| FR8 | Teacher dashboard: assigned students' progress, difficulty areas, trends | Teacher dashboard | T |
| FR9 | Parent dashboard + real-time notifications (task done, milestone, teacher update) | Parent monitoring + FCM | P |
| FR10 | ✓ In-app teacher↔parent messaging: updates, recommendations, links; parents report home observations | Messaging | T,P |
| FR11 | Rewards/levels: stars, badges, unlockables; digital only, non-food, non-competitive | Rewards | S |
| FR12 | ✓ Emotion journal: log feelings with icons (no reading/writing); visible to teacher + parent | Journal | S,T,P |
| FR13 | ✓ Visual schedule: predictable picture schedule of what's next; set by teacher/parent | Visual Schedule | S,T,P |
| FR14 | Offline: games, activities, journal, schedule work offline; auto-sync when back online | Firestore persistence | S,P |
| FR15 | Dual language **BM + English** (UI, narration, content); pick at registration, change in settings | l10n (en + ms) | All |

✓ = implemented and wired. Unmarked = calm placeholder or milestones still open (FR3 Milestone 2, FR4, FR8, FR9, FR11). FR14 offline persistence is on (Firestore cache) and already covers the built data features; FR15 is English-only for now (see Project context).

**Rewards are deferred (intentional).** We complete each feature first, then do the FR11 rewards/celebration pass (stars/badges/unlockables) across all of them at the end. So a built activity shows a calm "all done" moment but no stars yet — don't add per-feature reward UI until the FR11 pass.

## Tech stack
- **Flutter** (stable, null-safe), **Riverpod** for all state.
- **Firebase**: Auth, Firestore, Cloud Messaging (FR9). Init via FlutterFire CLI (`firebase_options.dart`). **Blaze is active.** Storage still unused by choice — videos and art ship as local assets (demo reliability, offline).
- **Offline (FR14):** Firestore offline persistence is **on** (`core/firebase/bootstrap.dart`); journal, schedule and messages already read/write through the local cache and sync when back online. `syncStatus` (`pending`/`synced`) is stored on records for a future offline indicator. No hand-rolled cache.
- **AI (FR3, teacher reports):** Firebase AI Logic → Gemini `gemini-2.5-flash-lite` via `firebase_ai` (**pinned `>=3.11.0 <3.12.0`** — 3.12+ needs a newer Flutter `foundation.dart` than our Flutter 3.29 SDK; a `dependency_overrides` on `firebase_core_platform_interface ^7.1.0` makes 3.11 resolve, see pubspec comments). Key stays server-side; model name lives in `AppConstants.geminiModel`. AI Logic is **enabled** in the console and live chat is verified. The Gemini Developer API currently runs on the **free tier**: a small daily quota that resets at midnight Pacific (3 to 4 PM Malaysia). When exhausted, calls return 429 and the companion falls back calmly. **Before the demo, switch to the paid tier** in Firebase console → AI Logic → Settings (Blaze covers it; fractions of a cent per chat message) so quota can never run out mid-demo. Do NOT use the Anthropic/Claude API here: a client app would have to ship the key, and Firebase AI Logic exists to avoid exactly that.
- **Voice:** `speech_to_text` + `flutter_tts` (device, free). Companion takes typed or spoken input. Mix-and-Match story/situation cards already narrate their text via `flutter_tts` (`core/services/narration_service.dart`, `narrationServiceProvider`): tap to play, tap again to restart from the start; honours `masterVolume`; works on Android + Web with no audio files.
- **3D companion (FR3 Milestone 2 — the thesis feature):** a full-body talking, moving avatar that teaches emotions with **body language + face + voice**, replacing the old Rive plan. Stack: **TalkingHead (three.js) in a `flutter_inappwebview` WebView** (all JS bundled locally in `assets/companion/`, served over its own `InAppLocalhostServer` — same pattern as AR), **Ready Player Me** full-body GLB avatar (exported with `morphTargets=ARKit,Oculus Visemes`), **Mixamo** FBX clips (one body-language pose per emotion: sad slump, happy open arms, scared flinch...), **Google Cloud TTS** for speech + word timestamps feeding TalkingHead's **built-in English lip-sync** (free tier ~1M WaveNet chars/month; Azure Speech is the deferred BM-era upgrade — its ARKit visemes are less natural on TalkingHead anyway per its docs), device `speech_to_text` for the child's voice (tap-selection stays the primary input; many students are non-verbal), and the **Gemini teaching brain** via the existing `firebase_ai` setup returning structured JSON per turn: `{isCorrect, spokenResponse, characterEmotion, bodyAnimation, observationNote}` — Dart parses it and drives voice, face, pose, and the `AISessionLog` observation note. Teaching loop: companion demonstrates (pose + face + spoken "how am I feeling?"), child answers by tap or voice, brain judges gently (never negative), character reacts with lip-synced feedback, round is logged. Camera dollies full-body → face for the "now look at the face" beat. Pre-baked Tier 1 (fixed emotion set, one clip + line each); free-form avatar chat is a Tier 2 stretch. Keep the model low-poly and test on the Realme early (NFR2: screens under 3s). Build order: (1) render avatar in WebView ✓, (2) Dart→JS bridge ✓, (3) Mixamo poses ✓, (4) Google TTS + lip-sync, (5) STT done ✓, (6) brain schema, (7) close the loop + log, (8) camera polish.
- **AR:** WebAR — **MindAR image tracking + A-Frame** (JS bundled locally in `assets/ar/` — no CDN/WiFi dependency) hosted in a `flutter_inappwebview` WebView, page served from `assets/ar/` over `InAppLocalhostServer` (http://localhost:8477 — `getUserMedia` needs a secure origin, so never `file://`; cleartext-to-localhost allowed via `res/xml/network_security_config.xml`). Two camera permission gates must both pass: `permission_handler` (OS) and the WebView's `onPermissionRequest`. 3D content = animated `.glb` characters via `a-gltf-model` (+ `aframe-extras` `animation-mixer` for their clips). No ARCore.
- **l10n (FR15):** Flutter `l10n`, arb files `en` + `ms`, covering UI, narration, content.

Visual split: **TalkingHead avatar (assets/companion) = companion, MindAR characters (assets/ar) = AR.** Separate WebView pages, separate localhost ports. Don't mix.

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
assets/  rive/  models/  images/  audio/  video/
```

## Where features live (built so far)
- **FR1 auth/linking:** `core/services/auth/` + `data/linking_service.dart`; screens in `features/auth/`; redirects in `app/router.dart`.
- **FR2 profiles + sensory:** `features/account/account_profile_screen.dart`, `features/teacher/student_profile_detail_screen.dart`, `core/widgets/sensory_settings_sheet.dart`; theming in `app/theme/`.
- **Student/child detail (teacher + parent):** `features/student_detail/student_detail_tabs.dart` — shared `StudentDetailTabs` (SegmentedButton switching Overview / Schedule / Journal panes in an IndexedStack, plus the public `studentDetailProvider`). Callers MUST key it by `ValueKey(student.id)` (the schedule editor's draft state does not reset on studentId change). Hosts: the teacher's pushed detail route (`StudentDetailPanel` in `student_profile_detail_screen.dart`, delete/remove-parent helpers there take an `onDeleted` callback), the wide two-pane Students tab (`TeacherClassroomScreen`: roster left, detail right at body width ≥ 840 — separate from the shell's 720 rail breakpoint; narrow keeps push navigation), and the parent's Progress tab. Overview carries the disabled "Progress report" button as the FR8 hook. Single-column screens cap content with `core/widgets/constrained_content.dart` (`ConstrainedContent`, 560).
- **FR10 messaging:** `features/teacher/messaging_thread_screen.dart`; conversation providers in `core/providers/repository_providers.dart`.
- **FR12 journal:** `features/journal/journal_section.dart` — `JournalLogger` (child) + `JournalHistorySection` (shared). Teacher and parent can each leave one role-labelled `JournalComment` per entry (`commentBy`/`withComment` on the model); comments render distinctly ("Teacher: …"). The child logs and reads but does not comment on their own entries. Embedded by the student tab and both detail screens, mirroring the schedule pattern.
- **FR13 schedule:** `features/schedule/schedule_section.dart` (`StudentScheduleSection`, `canEdit`).
- **FR6 mix-and-match:** `features/mix_match/` — `mix_match_screen.dart` (level select + shared `MixMatchLevelGrid`), `mix_match_play_screen.dart` (drag-to-bucket round, writes a `Session`), `mix_match_data.dart` (`buildMixMatchDeck` auto-discovers card art from the asset manifest under `assets/images/mixmatch/<type>/<emotion>_<n>.png`; stories/situation-text from `kMixMatchStories`/`kMixMatchSituations`; buckets/cards limited to `kMixMatchEmotions`). No level gating — all card types always open. Each card type's round is saved on the student (`Student.mixMatchRounds`: type→`MixMatchRound{cards, placed}`, in `core/models/mix_match_round.dart`) so play resumes the **exact same question** after navigating away or signing out (`deckFromRound`/`roundFromDeck` in `mix_match_data.dart`). `round.placed` drives the child's "X/5" tile (hidden for the teacher) and the overall "X/20 earn badges" bar; refreshed live via `activeStudentProvider` (a `StreamProvider`). A debug-only "Reset progress" button clears it. Teacher classroom launch in `TeacherProfilesScreen`.
- **FR7 quiz:** `features/quiz/` — `quiz_home_screen.dart` (`QuizDayPicker` Today/Yesterday/Day before, with `quizSetIndexForDate` mapping the **real date** to one of three daily story sets on a 3-day cycle; works on web + mobile via `DateTime.now()`), `quiz_play_screen.dart` (one calm mixed round; `studentId` null = teacher classroom mode, no session/record) and `quiz_data.dart` (`buildQuizDeck({setIndex})` builds a **fixed curated round** from `_setPlan`: each set asks every feeling once via an interleaved mix of the three ways of asking, arranged so no face, sound or story is reused across the three sets, with graceful fallback if a planned modality has no art. Content is still auto-discovered/drop-in: `look` images `assets/images/quiz/look/<emotion>_<n>.png` (a few variations per feeling), `listen` cues `assets/audio/cues/<emotion>_<n>.mp3|wav`, `story` scenarios `kQuizStorySets[setIndex]` shaped as `EmotionContent`. Replaying a day gives the same round; variety comes from the three different days). Shares nothing with Mix-and-Match: own `kQuizEmotions`, `kQuizLookRoot`, `kQuizCueFolder`, art and content. 3 choices = answer + 2 distractors; spoken feedback is tailored per question: faces use `kQuizLookFeedback`, sounds use `kQuizListenFeedback`, and each story carries its own `feedback` (`kQuizFeedback` is a bland last-resort fallback only). Sound cues play via `core/services/sound_cue_service.dart` (`soundCueServiceProvider`, audioplayers, with a per-cue gain map, e.g. scared ×1.3); story text narrates via `narrationServiceProvider`. On a right answer the short feedback is spoken; **Next** is tappable immediately and cuts the narration when used. **Resumes** the exact in-progress round like Mix-and-Match via `Student.quizRounds` (`core/models/quiz_round.dart`, keyed by set index; each answer is saved the instant it's given, so a mid-feedback quit resumes on the *next* question). The picker shows each day's `X/5` progress live (`round.answered`), with a `kDebugMode`-only "Reset progress (dev)" button that clears `quizRounds`. Writes a `Session` (`ActivityType.quiz`). Teacher classroom launch (per-day) in `TeacherProfilesScreen`.
- **FR5 story mode:** `features/story/` — `story_home_screen.dart` (student picker + shared `StoryPicker`; episodes unlock in order per story, teacher mode all open, debug-only "Reset progress (dev)" button), `story_play_screen.dart` (the film in a contained rounded frame — same video-page layout on web and mobile, NO full-screen mode — with a control strip below: play/pause + non-scrubbable segment progress; a transparent tap layer over the film also toggles play/pause, needed because on web the `<video>` platform view can swallow taps. At each configured moment the film pauses and the question appears *beneath* it: the pause's own `ask` line (names who to think about, e.g. "How does the puppy feel?"), 3 choices with deterministic distractors via `storyOptionsFor` (nothing persisted), short text `feedback` on a right tap — story mode has NO narration/TTS. Flutter content is never painted over the video: on web the `<video>` element sits above the canvas and overlays render blank white. Episode end writes a `Session` (`ActivityType.story`)), `story_data.dart` (`kStoryCatalog`: each story is one continuous film under `kStoryVideoRoot` = `assets/video/` carved into episodes by `StoryEpisode.startMs`/`endMs` (null endMs = natural end), each with its `StoryPause{atMs, ask, answer, feedback}` list — all timestamps absolute in the film. Wired: "The Present" (`the_present.mp4`, 3 episodes: 0:07.5–1:00, 1:00–1:52, 1:52–3:22 hard cut, six pauses), "Watermelon" (`watermelon.mp4`) and "Pip" (`pip.mp4`) — adding a story = one new `StoryInfo` entry with its timestamps). Resume state on `Student.storyProgress` (`core/models/story_progress.dart`, keyed by story id: `levelsDone`/`pausesDone`/`positionMs`), saved the instant a pause is answered — only the frontier (next unfinished) episode writes progress, replays never regress it. Teacher classroom launch in `TeacherProfilesScreen` (`/teacher/story/play`).
- **FR3 AI companion:** `features/student/companion/` — `companion_screen.dart` (one calm screen: big enum-keyed placeholder face — swap for the Rive state machine later — a speech bubble that speaks every line via `narrationServiceProvider` only in response to the child's own tap (greeting is text-only, nothing autoplays), five feeling tiles, and a chat input row). **Teaching is fully curated** (`companion_data.dart`: `kCompanionLessons`, four short lines per feeling — what it is, the face, the body, an example + "show me the face" invite — child taps Next through them; finishing writes a `Session` (`ActivityType.companion`) for FR8). **Chat is the only live-Gemini surface** (`companion_chat_service.dart`: multi-turn `ChatSession`, safe system prompt, structured JSON `{reply, feeling}` parsed defensively; two attempts with a 1.5s pause between them (transient "overloaded" blips), then any remaining failure — offline, quota 429 — returns null and the screen redirects calmly to the lessons; failures are debugPrinted in dev builds so the real cause is visible in the run console). Spoken input via `speech_to_text` (mic button fills the text field live and the message **auto-sends when the child stops talking** — final recognizer result, pause timeout, or a mic tap all send, guarded against double/empty sends; the mic quietly hides itself if the device can't listen; Android needs `RECORD_AUDIO` + the `RecognitionService` query, both in the manifest). Route `/student/companion`. Works on Chrome for dev; mobile-only in the final product via the re-enabled web gate. **Milestone 2 stage (step 1 done):** `stage/companion_stage_mobile.dart` (InAppWebView + `InAppLocalhostServer` port 8478 → `assets/companion/index.html`) vs `stage/companion_stage_web.dart` (the calm placeholder face; keeps web free of WebView deps) via conditional import — the screen passes `expression`/`intensity` so step 2's bridge changes no call sites. The page bundles TalkingHead 1.7 + three 0.180.0 locally in `assets/companion/libs/` (all `.mjs` renamed `.js` and the two internal `.mjs` references patched, so no server MIME table can break module loading; `three.core.js` must ship next to `three.module.js`). Placeholder avatar `assets/companion/avatar/companion.glb` is TalkingHead's test RPM-style model (readyplayer.me was unreachable from the dev sandbox); swap by overwriting that one file — export with `morphTargets=ARKit,Oculus Visemes`. **Step 2 done — the bridge:** the page calls the `stageReady` JS handler once the avatar loads; Dart then pushes every expression change via `window.mc.setEmotion('<Emotion.name>')` (`didUpdateWidget` diff, best-effort). In-page bridge: `setEmotion` (maps app emotions → TalkingHead moods: happy/sad/angry stay themselves, scared→`fear`, surprised→neutral + the 😱 wide-eye open-mouth gesture which reads as classic surprise on this avatar, neutral→neutral), plus raw `setMood`, `setView('full'|'upper'|'head')`, `gesture(emoji, dur)`. All six emotions verified headless by screenshot. **Step 3 done — body language:** Mixamo clips in `assets/companion/poses/<emotion>.fbx` (happy/sad/scared/angry/surprised, no neutral clip on purpose); `setEmotion` plays the matching clip for ~8s via `playAnimation` then settles back to the mood idle, and `window.mc.playPose(emotion, dur)` exists standalone. Face + body compose (surprised = wide-eye gesture + lean-back clip together). Poses verified full-body by screenshot: sad hangs its head, scared cowers, angry crosses arms, surprised leans back, happy opens up.
- **FR4 AR (Milestones 1+2 done):** `features/student/ar/` — `ar_screen.dart` (thin wrapper; conditional import keeps camera code out of the web build), `ar_view_mobile.dart` (OS camera permission via `permission_handler` with a calm denied state and settings fallback, then `InAppLocalhostServer` on port 8477 + `InAppWebView` with `onPermissionRequest` GRANT — both gates required or the page is black), `ar_view_web.dart` (calm "AR is on mobile" fallback). The WebAR page is `assets/ar/index.html` (A-Frame 1.6.0 + aframe-extras 7.5.4 + MindAR 1.2.5, all bundled locally in `assets/ar/`; marker `assets/ar/card.mind`, print `assets/ar/card.png` on matte paper; `maxTrack: 1`). On `targetIndex: 0` an animated character plays via `animation-mixer`; a calm in-page picker (five large buttons: Happy/Sad/Scared/Angry/Surprised) swaps the model on the card — only the chosen one is loaded on demand (a "Getting ready" chip shows while it loads; per-model transforms tuned in the `EMOTIONS` map in `index.html`). The GLBs (`happy/sad/scared/angry/shocked.glb`, shocked = Surprised) are compressed to 0.16–1.7 MB each via `gltf-transform optimize --compress quantize --texture-compress webp --texture-size 1024 --simplify-error 0.001` (originals were 3–28 MB; needs no runtime decoder — run the same pipeline on any new model, keeping render performance is part of keeping tracking smooth). Note: only `sad.glb` actually contains an animation clip; the other four are static poses. **Pose stability:** MindAR's own one-euro filter warps rotations (skew/stretch) so it is disabled via extreme filter values; the model instead rides a follower entity driven by the custom `stabilized-follow` component in `index.html` (lerp position, slerp rotation, scale locked at target-found, one-to-two-frame outlier poses rejected) — keep new AR content inside the follower, not the raw `mindar-image-target` anchor. Route `/student/ar`. Next: narration/teaching layer on the characters; classroom/home modes and progress saving come later.
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

## How to make changes (read this)
- **Don't take edits hyper-literally.** When asked to change A to B, also update everything connected to A so the whole thing actually fits B: callers, related copy/labels, model fields, persistence, docs, and tests. A change isn't done until the surrounding pieces make sense together. Example: "rename this field" means updating its readers, JSON keys, and tests too — not just the declaration.
- **Make copy read naturally, not mechanically.** If a rule means a sentence must change (e.g. removing punctuation), rewrite the sentence so it still reads well. Don't just delete the offending character and leave something awkward.
- **No dashes in user-facing copy.** Never use `—`, `–`, or a hyphen-as-pause (` - `) in any UI sentence; write proper sentences (use full stops or commas). Hyphenated compound words like "Mix-and-Match" or "low-literacy" are fine.

## Conventions
- Riverpod everywhere; no global mutable singletons.
- Data access goes through `core/services/data/repositories.dart`; every implementation is Firestore-backed. The `Stub*`/`DevSeed` path is **auth-only** (`--dart-define=USE_STUB_AUTH=true`), not a data backend.
- Guard all AR/camera/AI-companion code behind `kIsWeb` or a conditional import; web build must reach zero camera deps (the AR screen uses `ar_view_web.dart if (dart.library.io) ar_view_mobile.dart`). Web AR = receive a stream from a connected mobile device, not native camera access.
- All UI strings via `l10n`. **English is the source of truth:** add keys to `lib/l10n/app_en.arb` only, then run `flutter gen-l10n`. `ms` auto-falls back to English until the deferred BM pass — don't hand-add `ms` strings yet.
- Respect `sensorySettings` in every activity.
- Gemini: system prompt = calm, patient, positive-only, child-safe, short sentences, emotions-only, gently redirect off-topic. Request structured JSON; parse defensively.
- Round any number shown; never raw floats. No secrets/API keys in the repo.

## Asset strategy — placeholders first
Build logic/layout now with stand-in art; swap real art later with no code change. Companion = enum-keyed expressions (`happy, sad, scared, angry, surprised, neutral`). The journal + emotion pickers reuse that same set via `kEmotionIcon`/`kEmotionColor`; schedule pictures via `kScheduleIconCatalog` — all in `core/constants/app_constants.dart`. AR = animated `.glb` characters on the marker, swapped by the in-page emotion picker. Centralise every asset path in one constants file.

## Build order
0. ✓ Foundation: scaffold, design system + sensory theming, role routing, FR1 auth + linking. Firebase configured.
1. ✓ Vertical slice — Emotion Journal (FR12) end-to-end: student logs → Firestore → teacher/parent view. Also done: FR13 visual schedule, FR10 teacher↔parent messaging, FR2 profiles + sensory settings.
2. **Signature features:** Story ✓, Mix-and-Match ✓, Quiz ✓, AR Milestones 1+2 ✓, AI Companion Milestone 1 ✓. **Next: AI Companion Milestone 2** (the full-body 3D teaching avatar — the thesis feature), then AR Milestone 3 (teaching layer on the card characters).
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

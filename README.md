# MoodCraft

**Emotion recognition learning for children with Autism Spectrum Disorder (ASD).**

MoodCraft helps primary-school children with autism learn to recognise and understand emotions, and keeps their teachers and parents connected to that learning. Every screen is designed to be calm, predictable and supportive: no timers, no scores that drop, no "wrong" buzzers, only gentle redirects.

Final Year Project, Diploma in Computer Science, Kolej Profesional MARA Beranang. Developed solo.

## Platforms

| Platform | Who uses it |
|---|---|
| Android app | Students, parents and teachers |
| Web app | Teachers only, for classroom projection and the dashboard |

## Features

- **Story Mode**: short films that pause at emotional moments and ask the child how a character feels
- **Mix and Match**: drag face, body, situation and story cards onto the matching emotion
- **Stress-free Quiz**: guess a feeling from a face, a sound or a short spoken story, with no timer and no score
- **AI Companion**: a calm 3D talking avatar that teaches emotions through face, body language and voice, with typed or spoken answers
- **AR Emotions**: animated 3D emotion characters that appear on printed cards through the phone camera
- **Rewards**: participation stars, levels and badges that can never be lost
- **Emotion Journal**: children log feelings with icons, and teachers and parents can view and comment
- **Visual Schedule**: a picture schedule of what comes next, set by the teacher or parent
- **Teacher Dashboard**: class progress, badges, journal entries and task completion
- **Teacher and Parent Messaging**: updates, recommendations and home observations

## Tech stack

- **Flutter** (Android and Web), **Riverpod**, **go_router**
- **Firebase**: Authentication, Cloud Firestore (with offline persistence)
- **Gemini** through Firebase AI Logic (Vertex AI) for the AI Companion
- **TalkingHead (three.js)** avatar with text-to-speech lip-sync, in a WebView
- **MindAR + A-Frame** for marker-based WebAR, in a WebView
- **speech_to_text** and **flutter_tts** for voice input and narration

## How it was built

Requirements were gathered through an interview with a special education teacher and a classroom observation. The app was tested with real students and teachers.

## Running locally

```bash
flutter pub get
flutter run -d chrome     # teacher web app
flutter run               # Android app on a connected device
```

A Firebase project is required. Generate your own `firebase_options.dart` with the FlutterFire CLI.

## Author

**Mohamad Danish bin Mahfoz** · [github.com/AstroBoiiiii](https://github.com/AstroBoiiiii)

# Habit Agent MVP: UI Screens Guide

Nov 15, 2026 · @Dewmal Handapangoda

## How to use this guide

This guide covers the 14 screens of the MVP, with what each one shows, what the user can do, what data it reads and writes, and which safety rule it must follow. It is written so the Flutter build can start on Mon Nov 16.

The editable designs are on the [Habit Agent MVP UI canvas](https://claude.ai/artifact/98Gj7tgdKYUKfEXosUubQh). The rules and scope come from the project spec and the 2-week plan. Widget names and screen-to-screen routes in this guide are suggestions, so rename them freely.

Four things are still placeholders in the designs and need your words before the build reaches them:

- [ ] The 3 to 4 health check questions (screen 3)
- [ ] The 5 stage names of the gym template and the rule for moving on (screens 5 and 11)
- [ ] The fixed phrases for a missed day, the step-up question and the care message, in Sinhala and English (screens 7, 8, 10)
- [ ] Sinhala text for every screen. The designs show English only

## Design tokens

Put these values in one theme file on Day 1 so no screen hard-codes a colour or size. They are taken from the sunset reference image.

### Colours

| Token | Value | Used for |
| --- | --- | --- |
| bg | #1E2444 | Screen background. Also the text colour on light and coral surfaces |
| bgDeep | #171B36 | Chat header, input bar, bottom nav, segmented control track |
| surface | #2A3058 | Agent bubble, list rows, info card, icon buttons |
| surfaceRaised | #343B6B | Small buttons on a surface, empty progress bars, stage numbers |
| coral | #F2646C | User bubble, selected language, Save, Delete everything. Text on it is navy |
| coralBright | #FF7A7F | Quick-reply outline, active nav item, small labels on navy |
| blush | #FBD9DF | Interactive cards in chat (level, log, checklist, step-up) |
| blushDeep | #F6C3CC | Unselected options inside a blush card |
| labelOnBlush | #8A2C45 | Small labels inside a blush card |
| sunsetYellow | #FFC56B | Gradient start, info card outline and icon |
| sunsetOrange | #FF9A6B | Gradient middle |
| sunsetPink | #F0607A | Gradient end |
| sunsetPurple | #6B4F9E | Top of the sky in illustrations and the coach avatar |
| text | #FFFFFF | Main text on navy |
| textMuted | #B9BEDD | Secondary text on navy |

The sunset gradient runs at 135 degrees: sunsetYellow, sunsetOrange at 45%, sunsetPink. Use it only for the stage card, the step-up card header and the coach avatar. Text on the gradient is navy.

White text on coral is hard to read, so buttons use navy text on coral or navy text on white.

### Type, shape and spacing

| Token | Value |
| --- | --- |
| Font | Poppins, with Noto Sans Sinhala for Sinhala text |
| Welcome title | 34 px, weight 600 |
| Screen title | 28 px, weight 600 (24 px on Settings and My data) |
| Health question | 26 px, weight 600 |
| Card title | 17 to 20 px, weight 600 |
| Body | 14 to 15 px, weight 400, line height 1.5 |
| Small label | 12 px, weight 600 |
| Nav label | 11 px |
| Radius | 12 small buttons, 14 icon buttons, 18 rows and main buttons, 20 cards, 22 quick replies, 24 stage card |
| Screen padding | 20 px (28 px on Welcome and Health check) |
| Gaps | 8, 10, 12 and 16 px |
| Touch size | At least 44 px high. Main buttons are 56 px |

A simple starting theme file:

```dart
import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF1E2444);
  static const bgDeep = Color(0xFF171B36);
  static const surface = Color(0xFF2A3058);
  static const surfaceRaised = Color(0xFF343B6B);
  static const coral = Color(0xFFF2646C);
  static const coralBright = Color(0xFFFF7A7F);
  static const blush = Color(0xFFFBD9DF);
  static const blushDeep = Color(0xFFF6C3CC);
  static const labelOnBlush = Color(0xFF8A2C45);
  static const sunsetYellow = Color(0xFFFFC56B);
  static const sunsetOrange = Color(0xFFFF9A6B);
  static const sunsetPink = Color(0xFFF0607A);
  static const sunsetPurple = Color(0xFF6B4F9E);
  static const text = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFFB9BEDD);
}

const sunsetGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.sunsetYellow, AppColors.sunsetOrange, AppColors.sunsetPink],
  stops: [0.0, 0.45, 1.0],
);
```

## Shared components

Build these 12 parts once and reuse them. Most screens are just a different mix of them.

| Component | What it is | Used on screens |
| --- | --- | --- |
| ChatHeader | Gradient avatar, chat name "General", line "Your coach · AI" | 2, 4, 6, 7, 8, 10 |
| AgentBubble | Left side, surface colour, radius 18 with a small bottom-left corner | 2, 4, 6, 7, 8, 10 |
| UserBubble | Right side, coral with navy text, small bottom-right corner | 2, 10 |
| QuickReplies | Outlined pill buttons under the last agent message. A tap is sent as the user's answer | 2, 4, 7, 10 |
| InputBar | Rounded text field and a white round send button | 2, 4, 7, 8, 10 |
| BottomNav | Four tabs: Chat, Today, Plan, History. Hidden during onboarding (screens 1 to 4) | 5 to 8, 10 to 12 |
| BlushCard | Blush box with radius 20. The base for every interactive card | 4, 6, 7, 8 |
| ThreeChoice | Three equal buttons in a row. Selected one is navy with white text | 6 (Done / Partly / Skipped, Easy / Okay / Hard) |
| TaskTile | A row with a checkbox and the task text | 5, 7 |
| InfoCard | Surface box with a yellow outline and icon, fixed text | 4, 10 |
| MainButton | White, 56 px high, navy text. One per screen at most | 1, 5 |
| SettingRow | Surface row, label on the left, value or arrow on the right | 13, 14 |

### The card rule

Cards are a fixed set built into the app. The AI only picks which card to show and fills in the words. It never sends layout or code.

| Card in the MVP | Screen |
| --- | --- |
| Quick replies | 2, 4, 7, 10 |
| Yes / No question | 3 |
| Task checklist | 5, 7 |
| Log card | 6 |
| Level card | 4 |
| Step-up offer | 8 |
| Info card | 4, 10 |

A tap on any card writes straight to the phone database with no AI call, so cards cost nothing and work offline.

## Navigation

The app has one straight onboarding path (screens 1 to 4), then four tabs. Everything else opens from the chat or from Settings.

| From | User action or event | Goes to |
| --- | --- | --- |
| App start, first run | None | 1 Welcome |
| App start, later runs | None | 5 Today |
| 1 Welcome | Start | 2 First questions |
| 2 First questions | Last question answered | 3 Health check |
| 3 Health check | Last Yes or No | 4 Level and first plan |
| 4 Level and first plan | Looks good | 5 Today, bottom nav appears |
| Bottom nav | Chat / Today / Plan / History | Chat (screens 6, 7, 8, 10 are states of it) / 5 / 11 / 12 |
| 5 Today | Log how it went | 6 Daily log, shown in Chat |
| 5 Today | Settings icon | 13 Settings |
| Chat, after missed days | Agent message | 7 After missed days |
| Chat, after easy and steady days | Agent message | 8 Step-up offer |
| Chat, user says unwell or very low | Rules engine | 10 Hard stop |
| 9 Notification | Done / Later / Too hard | Writes the log, app stays closed |
| 13 Settings | My data | 14 My data |
| 14 My data | Delete everything, confirmed | 1 Welcome |

Screens 6, 7, 8 and 10 are not separate pages. They are the same Chat page showing a different card.

## Getting started (screens 1 to 4)

These four screens take a new user from install to tomorrow's tasks. The release target is under 3 minutes for the whole path.

### 1 Welcome

&#91;image: Screen 1 Welcome\]

The first-run screen. It says what the app is, tells the user the coach is an AI, and sets the language.

- **Shows:** sunset illustration, app name, one-line promise, the AI and privacy note, language switch (English / සිංහල), Start button.
- **Actions:** tapping a language changes all text at once. Start opens screen 2.
- **Data:** writes the language to the profile table. Reads nothing.
- **Rules:** the AI note must be visible without scrolling. This is the honesty promise and is on the never-cut list. Show this screen only on first run.

### 2 First questions

&#91;image: Screen 2 First questions\]

The General chat in onboarding mode. The agent learns the goal, then asks up to 5 short questions to place the user.

- **Shows:** ChatHeader, agent and user bubbles, a "Question 2 of 5" label inside the question bubble, quick replies, InputBar. No bottom nav yet.
- **Actions:** the user types the goal in their own words. For each question they tap a quick reply or type. After the last answer the app opens screen 3.
- **Data:** writes the goal text and each answer to the habit table. Each agent message is one request through the gateway.
- **Rules:** never more than 5 questions. Every agent message passes the no-shame blocklist before it is shown. This step needs internet, so show a plain "no connection, try again" message if the gateway cannot be reached.

### 3 Health check

&#91;image: Screen 3 Health check\]

Three or four fixed yes/no screens. This is plain app code with no AI, so it is the same every time and easy to test.

- **Shows:** back button, title, "Question 2 of 4" with a progress bar, one large question, No and Yes buttons, one reassuring line at the bottom.
- **Actions:** No or Yes saves the answer and shows the next question. Back returns to the previous question. After the last one the app opens screen 4.
- **Data:** writes the safety check result to the habit table. The answers never leave the phone. Only the result "keep very gentle" may be sent to the gateway.
- **Rules:** any Yes turns on the health lock: the project stays at the gentlest level and the "see a doctor" note is shown on screen 4. A Yes never blocks the user. The question text comes from the plugin data, not from the screen code.

### 4 Level and first plan

&#91;image: Screen 4 Level and first plan\]

Back in the chat. The agent shows the starting level and the first small steps on a level card.

- **Shows:** agent bubble, level card (Beginner / Building / Ready with one highlighted, then tomorrow's small steps), the info card only when the health lock is on, quick replies "Looks good" and "Make it smaller".
- **Actions:** "Looks good" saves the plan and opens screen 5 with the bottom nav. "Make it smaller" asks for smaller steps and shows the card again.
- **Data:** writes the level to the habit table and the stages and current stage to the plan table. Stages are loaded from the fixed gym template. The AI writes only today's and tomorrow's tasks.
- **Rules:** "smaller" is always allowed with no extra check. With the health lock on, the level is forced to the gentlest one whatever the AI suggests.

## The daily loop (screens 5 to 9)

These five screens are what a tester sees every day. All of them except the two AI-written chat messages work with the internet off.

### 5 Today

&#91;image: Screen 5 Today\]

The home screen after onboarding. It shows only today's tasks and nothing about later days.

- **Shows:** title with the project name, settings icon, offline banner (only when offline), stage card ("Stage 1 of 5", stage name, one calm line), task checklist, "Log how it went" button, BottomNav with Today active.
- **Actions:** ticking a task marks it done. "Log how it went" opens the log card (screen 6). The settings icon opens screen 13.
- **Data:** reads the current stage from the plan table and today's tasks. A tick writes to the daily log table with no AI call.
- **Rules:** must work fully offline from saved data. No streak counters, scores or tomorrow's tasks. The project name and stage name come from data, so no text on this screen says "gym".

### 6 Daily log

&#91;image: Screen 6 Daily log\]

The evening check-in, shown as a log card in the chat.

- **Shows:** agent bubble "How did today go?", then the log card: each task with Done / Partly / Skipped, a "How did it feel?" row with Easy / Okay / Hard, and Save.
- **Actions:** one choice per task and one feeling, then Save. After saving, the agent answers with a fixed phrase.
- **Data:** writes one daily log record: the date, each task's result, and the feeling. No AI call.
- **Rules:** works offline. The reply after saving uses the fixed Sinhala and English phrases, never AI text. "Skipped" gets the same calm reply as "Done".

### 7 After missed days

&#91;image: Screen 7 After missed days\]

The chat after the user has missed days. The agent makes the next day smaller and says so.

- **Shows:** the fixed missed-day phrase, a short agent message, a task card with a "Smaller" tag and a "Was: 3 steps. Now: 1 step." line, quick replies "Okay" and "Still too much".
- **Actions:** "Okay" accepts the smaller plan. "Still too much" makes it smaller again.
- **Data:** reads recent daily log records. Writes the new, smaller tasks. Uses the gateway only if the tasks need rewriting.
- **Rules:** making tasks smaller needs no permission. Missed days never reset the plan or move the stage back. After misses the plan can never get bigger. The rules test "after three misses the plan can never get bigger" covers this screen.

### 8 Step-up offer

&#91;image: Screen 8 Step-up offer\]

The chat when the user has been steady and said the tasks felt easy. The agent asks before adding anything.

- **Shows:** agent bubble with the reason, then the step-up card: the fixed question on a sunset header, "Now" and "A bit more" lines, Yes and Not yet buttons, and the line "Nothing changes unless you say yes."
- **Actions:** Yes applies the bigger task from tomorrow. Not yet changes nothing.
- **Data:** reads completion and feeling from the daily log. Writes the plan only after Yes.
- **Rules:** the rules engine blocks any bigger step without a Yes, and the step must be tiny. The question uses the fixed phrase. This card is number 4 on the cut list, so build it after screen 7.

### 9 Notifications

&#91;image: Screen 9 Notifications\]

Two Android notifications a day, one in the morning and one in the evening. These are system notifications, not an app page, so the design shows only their content.

- **Shows:** app name and time, a short title, one line of text, and three buttons: Done, Later, Too hard.
- **Actions:** each button writes to the daily log without opening the app. Tapping the notification body opens Today (morning) or the log card (evening).
- **Data:** reads today's tasks, the daily limit and quiet hours from the profile table. Writes to the daily log.
- **Rules:** scheduled on the phone, so they fire with the app closed and the internet off. Never more than the user's daily limit and never inside quiet hours. If time runs short, cut the evening one first, then the buttons.

## Safety and control (screens 10 to 14)

These screens carry the safety promises and give the user control of their data. The hard stop and the "My data" delete are on the never-cut list.

### 10 Hard stop

&#91;image: Screen 10 Hard stop\]

The chat after the user says they feel unwell or very low. All pushing stops at once.

- **Shows:** the user's message, the fixed care message, an info card "Everything is paused" with a line suggesting a doctor or a trusted person, quick replies "Keep it paused" and "I'm okay to continue".
- **Actions:** "Keep it paused" leaves everything off. "I'm okay to continue" turns tasks and reminders back on.
- **Data:** writes a paused flag for the project and cancels all scheduled notifications. The plan is not changed.
- **Rules:** the rules engine triggers this, not the AI, and it applies to every reply after the user's message. The care message is fixed text. Open question: the spec does not say how "unwell" or "very low" is detected (a word list, an AI flag, or both), so decide this before Thu Nov 26.

### 11 Plan

&#91;image: Screen 11 Plan\]

A view-only list of the five stages, with the current one highlighted.

- **Shows:** title with project name and level, five stage rows, a sunset highlight and "You are here" on the current stage with the rule for moving on, the user's goal under the last stage, a short note, BottomNav with Plan active.
- **Actions:** none. This screen has no buttons besides the nav.
- **Data:** reads the stages, current stage and move-on rule from the plan table.
- **Rules:** a stage change happens only in chat and only with the user's yes. Stage names come from the plugin template.

### 12 History

&#91;image: Screen 12 History\]

A plain list of past days, newest first.

- **Shows:** one row per day with the day name, a one-line summary in plain words ("2 done, 1 partly"), and the feeling as a small tag. BottomNav with History active.
- **Actions:** scroll only.
- **Data:** reads the daily log table.
- **Rules:** no scores, no streak numbers, no warning colours for missed days. A day with no log is shown calmly, for example "Rest day, nothing logged".

### 13 Settings

&#91;image: Screen 13 Settings\]

The shared "About you" settings: language, reminders and the way into My data.

- **Shows:** back button, language switch, "Most reminders a day" with minus and plus, morning reminder time, evening reminder time, quiet hours, a My data row, and a note that progress is lost if the phone is lost.
- **Actions:** each change saves at once. Time rows open the Android time picker.
- **Data:** reads and writes the profile table: language, daily limit, reminder times, quiet hours.
- **Rules:** any change to reminders reschedules the local notifications. The lost-phone note stays until backup is built.

### 14 My data

&#91;image: Screen 14 My data\]

Where the user can look at or delete everything the app has saved.

- **Shows:** back button, one line saying all data is on this phone, five rows (About you, The habit, The plan, Daily log, Chat history) each with View and Delete, the line "Delete means delete", and a "Delete everything" button.
- **Actions:** View opens a simple read-only list of that data. Delete asks once to confirm, then removes it. "Delete everything" confirms, wipes the database and returns to screen 1.
- **Data:** reads and deletes from every table. The Day 1 plan lists four tables (profile, habit, plan, daily log), so chat history needs a fifth table or a place in one of those.
- **Rules:** delete must really remove the rows, not hide them. Editing data is number 2 on the cut list and is not drawn. View and Delete must ship.

## Build order

Each screen is built on the day the 2-week plan builds its feature. The plan does not name a day for Welcome, Plan or Settings, so those three placements are suggestions.

| Plan goal | Screens and parts to build |
| --- | --- |
| Decide and set up | Theme file (colours, fonts), empty app shell |
| Gateway | Chat page base: ChatHeader, AgentBubble, UserBubble, InputBar |
| Getting to know you | 1 Welcome (suggested), 2 First questions with QuickReplies, 3 Health check |
| Level placement and plan | 4 Level and first plan: BlushCard, level card |
| Today screen and rules engine v1 | 5 Today with TaskTile, BottomNav, InfoCard for the health lock, 11 Plan (suggested) |
| Buffer | Fix rough edges on screens 1 to 5 |
| Logging | 6 Daily log with ThreeChoice, 12 History |
| Adaptation rules | 7 After missed days, then 8 Step-up offer |
| Notifications | 9 Notifications, 13 Settings (suggested, since it holds the limit and quiet hours) |
| Hard stop, My data, honesty | 10 Hard stop, 14 My data, check the AI note on screen 1, offline banner on screen 5 |
| Test and freeze | Sinhala text on every screen, reviewed by a native speaker |

If hours run short, the cut list removes UI in this order: the evening notification, data editing, notification buttons, the step-up card (screen 8), then full Sinhala review.

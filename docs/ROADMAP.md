# Habit Agent: Implementation Roadmap (Todo List)

Build window: **Mon Nov 16 to Sun Nov 29, 2026** · Release: Android build to 10 testers on Nov 29
Assumes one builder at about 4 focused hours a day.

Sources (this file only orders their content into tasks, it adds no new scope):

- [Habit Agent Project Spec (Final).md](<Habit Agent Project Spec (Final).md>) — "Spec"
- [mvp-1st2week.md](mvp-1st2week.md) — "Plan"
- [Habit Agent MVP UI Screens Guide.pdf](<Habit Agent MVP UI Screens Guide.pdf>) — "UI guide", screens numbered 1 to 14

How to use: tick boxes as you go. Each day ends with a **Done when** check taken from the Plan. Tasks tagged `[cut N]` are on the cut list (see [If behind](#if-the-build-falls-behind)). Tasks tagged `[never cut]` are safety promises.

---

## Before you build: inputs and open decisions

These are not code. Each one blocks a specific day, so write them before that day arrives.

### Content that is still a placeholder (UI guide, page 1)

- [ ] The 3 to 4 health check questions, English and Sinhala — **needed by Wed Nov 18** (screen 3)
- [ ] The 5 stage names of the gym template and the rule for moving on — **needed by Thu Nov 19** (screens 5, 11)
- [ ] Fixed phrase: reply after saving a log (same calm reply for Done and Skipped), English and Sinhala — **needed by Mon Nov 23** (screen 6)
- [ ] Fixed phrase: missed day, English and Sinhala — **needed by Tue Nov 24** (screen 7)
- [ ] Fixed phrase: step-up question, English and Sinhala — **needed by Tue Nov 24** (screen 8)
- [ ] Fixed phrase: hard stop care message, English and Sinhala — **needed by Thu Nov 26** (screen 10)
- [ ] Sinhala text for every screen (designs are English only) — **needed by Fri Nov 27**
- [ ] Book the native Sinhala speaker for the Fri Nov 27 review

### Decisions the documents leave open

- [ ] **Hard stop detection:** how "unwell" or "very low" is detected: a word list, an AI flag, or both. Decide **before Thu Nov 26** (UI guide, screen 10)
- [x] **Chat history storage:** the Day 1 plan lists four tables, but My data needs chat history. Add a fifth table or place it in an existing one. Decide **on Mon Nov 16** when the tables are created (UI guide, screen 14)
- [ ] **Where today's and tomorrow's tasks are stored** (inside the plan table or a table of their own). Decide **on Mon Nov 16**
- [ ] **No-shame blocklist contents:** the actual blocked words and patterns (guilt, fake urgency, streak-loss threats), English and Sinhala. Needed **by Fri Nov 20**

### Day 1 checks (Spec section 12)

- [ ] Pick the AI provider with the Sinhala test (about 10 sample messages on 1 or 2 providers)
- [ ] Check Play Store rules: a new personal developer account may need a closed test before public release
- [ ] Choose how testers get the build: direct file or the internal testing track

---

## Week 1: the agent can talk and make a plan

### Mon Nov 16 — Decide and set up

- [x] Create the Flutter project (already in the repo as `one_preccent`)
- [ ] Write the 10 Sinhala sample messages, run them on 1 or 2 providers, pick one
- [ ] Do the other two Day 1 checks above (Play Store rules, how testers get the build)
- [x] Add the theme file: `AppColors`, `sunsetGradient`, type sizes, radii, spacing (UI guide pages 1 to 3). No screen hard-codes a colour or size
- [x] Add the fonts: Poppins, and Noto Sans Sinhala for Sinhala text
- [x] Set up English and Sinhala text switching so a language tap changes all text at once
- [x] Replace the counter demo in `lib/main.dart` with an empty app shell
- [x] Add the encrypted SQLite database
- [x] Create tables: profile, habit, plan, daily log, plus chat history (see the open decision)
- [x] Define the plugin and project shape as data: name, icon, colour, description, levels and placement questions, stages and move-on rule, task-writing guide, optional safety check, cards used
- [x] Create the Fitness plugin as a data file. No screen code may say "gym"
- [ ] Run the app on a real Android phone

**Done when:** provider chosen, app runs on the phone, tables exist.

### Tue Nov 17 — Gateway

- [x] Build the gateway as one small stateless function: holds the AI key, forwards the request, returns the answer
- [x] Gateway keeps nothing: no login, no user database, no saved prompts or answers, no analytics about people
- [x] Gateway logs hold only counts and error codes
- [x] Add the per-device rate limit
- [ ] Add Android app-check
- [ ] Set the spending cap on the AI account
- [x] Phone-side gateway client. The app contains no secrets
- [x] Request builder that sends only a short summary and the last few messages of the open chat (Spec section 6)
- [x] Chat page base: `ChatHeader` ("General", "Your coach · AI"), `AgentBubble`, `UserBubble`, `InputBar`
- [x] Save chat messages to the phone
- [x] Plain "no connection, try again" message when the gateway cannot be reached

**Done when:** chat works from the phone, nothing is stored on the gateway.

### Wed Nov 18 — Getting to know you (screens 1, 2, 3)

- [x] **Screen 1 Welcome:** sunset illustration, app name, one-line promise, AI and privacy note, language switch, Start button (`MainButton`)
- [x] AI note is visible without scrolling `[never cut]`
- [ ] Welcome writes the language to the profile table and shows only on first run
- [ ] **Screen 2 First questions:** General chat in onboarding mode, no bottom nav
- [ ] User types the goal in their own words, saved to the habit table
- [x] Agent asks up to 5 questions, never more, with a "Question 2 of 5" label in the bubble
- [x] `QuickReplies` component: a tap is sent as the user's answer
- [ ] Each answer saved to the habit table
- [ ] **Screen 3 Health check:** 3 to 4 fixed yes/no screens, plain code with no AI `[never cut]`
- [x] Back button, "Question 2 of 4" with a progress bar, large question, No and Yes buttons, one reassuring line
- [x] Question text comes from the plugin data, not from screen code
- [ ] Save the safety check result to the habit table. Answers never leave the phone, only the result "keep very gentle" may be sent
- [x] A Yes never blocks the user
- [ ] Routes: Welcome → First questions → Health check → Level and first plan

**Done when:** chat asks the questions and saves answers to the phone.

### Thu Nov 19 — Level placement and plan (screen 4)

- [x] Place the user: Beginner, Building or Ready
- [ ] Load the 5 stages from the fixed gym template into the plan table, with the current stage
- [ ] AI writes only today's and tomorrow's tiny tasks for the current stage, through the gateway
- [x] `BlushCard` base component for all interactive cards
- [x] Level card: three levels with one highlighted, then tomorrow's small steps
- [x] The AI picks a card and fills the words only. It never sends layout or code
- [x] Quick replies "Looks good" and "Make it smaller"
- [ ] "Looks good" saves the plan and opens Today with the bottom nav
- [x] "Make it smaller" asks for smaller steps and shows the card again, with no extra check
- [ ] Write the level to the habit table

**Done when:** a Beginner gets a few tiny tasks, a Ready person starts near the real habit.

### Fri Nov 20 — Today screen and rules engine v1 (screens 5, 11)

- [ ] Rules engine as plain if/else code, with every AI suggestion and outgoing message passing through it `[never cut]`
- [ ] Rule: health lock. Any Yes forces the gentlest level whatever the AI suggests `[never cut]`
- [ ] Rule: no-shame blocklist on every outgoing message `[never cut]`
- [ ] Rules tests for the health lock and the blocklist
- [x] `InfoCard` with the fixed "see a doctor" note, shown on screen 4 when the health lock is on
- [ ] **Screen 5 Today:** title with project name, settings icon, stage card ("Stage 1 of 5", stage name, one calm line), task checklist, "Log how it went" button
- [x] `TaskTile`: a tick writes to the daily log with no AI call
- [x] Today works fully offline from saved data
- [x] Today shows no streak counters, no scores and no tomorrow's tasks
- [x] `BottomNav`: Chat, Today, Plan, History. Hidden on screens 1 to 4
- [x] Later app starts open on Today, not Welcome
- [x] **Screen 11 Plan** (suggested day): view-only list of five stages, "You are here" on the current one with the move-on rule, the user's goal under the last stage

**Done when:** rules tests pass, blocked wording never reaches the screen.

### Sat Nov 21 — Buffer

- [ ] Finish anything open from Mon to Fri
- [ ] Fix rough edges on screens 1 to 5
- [ ] Time the path from install to tomorrow's tasks. Target: under 3 minutes

**Done when:** Week 1 goals all met.

### Sun Nov 22 — Rest, then one demo

- [ ] Show the app to one or two friends
- [ ] Write down what confused them

**Done when:** a short list of fixes for Monday exists.

---

## Week 2: the daily loop, safety and release

### Mon Nov 23 — Logging (screens 6, 12)

- [ ] Work through Sunday's fix list
- [x] `ThreeChoice` component: three equal buttons, selected one is navy with white text
- [x] **Screen 6 Daily log:** agent bubble "How did today go?", log card with Done / Partly / Skipped per task, Easy / Okay / Hard, and Save
- [ ] Save writes one daily log record: date, each task's result, the feeling. No AI call, works offline
- [x] Reply after saving is the fixed phrase, never AI text. Skipped gets the same calm reply as Done
- [x] "Log how it went" on Today opens the log card in Chat
- [x] **Screen 12 History:** one row per day, newest first, plain-word summary ("2 done, 1 partly"), feeling as a small tag
- [x] History has no scores, no streak numbers, no warning colours. A day with no log is shown calmly

**Done when:** logs save to the phone and show in history.

### Tue Nov 24 — Adaptation rules (screens 7, 8)

- [ ] Rule: misses make tasks smaller, never bigger. Smaller needs no permission
- [ ] Rule: missed days never reset the plan or move the stage back
- [ ] Rule: a bigger step or stage change needs the user's yes, and the step must be tiny
- [ ] Night step: the agent reads progress and proposes a change, and the rules engine approves it or holds it for a yes
- [ ] Rules tests, including "after three misses the plan can never get bigger"
- [ ] **Screen 7 After missed days:** fixed missed-day phrase, short agent message, task card with a "Smaller" tag and a "Was: 3 steps. Now: 1 step." line
- [x] Quick replies "Okay" (accept) and "Still too much" (smaller again)
- [ ] Use the gateway only if the tasks need rewriting
- [x] **Screen 8 Step-up offer** `[cut 4]`, build after screen 7: fixed question on a sunset header, "Now" and "A bit more" lines, Yes and Not yet, the line "Nothing changes unless you say yes."
- [x] Yes applies the bigger task from tomorrow. Not yet changes nothing. The plan is written only after Yes

**Done when:** rules tests pass 100%.

### Wed Nov 25 — Notifications (screens 9, 13)

- [ ] Morning local notification, scheduled on the phone
- [ ] Evening local notification `[cut 1]`
- [ ] Buttons Done, Later, Too hard write to the daily log without opening the app `[cut 3]`
- [ ] Tapping the body opens Today (morning) or the log card (evening)
- [ ] Rule: never more than the user's daily limit, never inside quiet hours
- [x] Rules tests for the daily limit and quiet hours
- [ ] Morning step: pick today's tasks and nudge times, rules engine trims to the limit and removes quiet hours
- [ ] **Screen 13 Settings** (suggested day): language switch, "Most reminders a day" with minus and plus, morning and evening reminder times, quiet hours, My data row, lost-phone note
- [x] `SettingRow` component. Each change saves at once. Time rows open the Android time picker
- [ ] Any reminder change reschedules the local notifications

**Done when:** works with the app closed and internet off.

### Thu Nov 26 — Hard stop, My data, honesty (screens 10, 14)

- [ ] Hard stop detection, as decided in the open decisions `[never cut]`
- [x] Rule: hard stop is triggered by the rules engine, not the AI, and applies to every reply after the user's message `[never cut]`
- [x] **Screen 10 Hard stop:** fixed care message, info card "Everything is paused" suggesting a doctor or a trusted person, quick replies "Keep it paused" and "I'm okay to continue"
- [ ] Write a paused flag for the project and cancel all scheduled notifications. The plan is not changed
- [x] "I'm okay to continue" turns tasks and reminders back on
- [ ] Hard stop rules tests
- [ ] **Screen 14 My data:** five rows (About you, The habit, The plan, Daily log, Chat history), each with View and Delete
- [x] View opens a read-only list of that data
- [x] Delete asks once, then really removes the rows
- [ ] "Delete everything" confirms, wipes the database and returns to Welcome
- [ ] My data edit `[cut 2]`
- [ ] Check the AI note on screen 1 `[never cut]`
- [ ] Offline banner on Today, and offline fallback: saved tasks show and logs are accepted

**Done when:** hard stop tested, delete really deletes.

### Fri Nov 27 — Test and freeze

- [ ] Conversation test: total beginner
- [ ] Conversation test: busy active person
- [ ] Conversation test: keeps skipping
- [ ] Conversation test: says they feel low
- [ ] Sinhala text on every screen
- [ ] Native speaker reviews the Sinhala `[cut 5]`
- [ ] Check the gateway: no chat or log content stored, logs hold only counts and error codes
- [ ] Fix bugs
- [ ] **Feature freeze at end of day**

**Done when:** no open safety bugs, Sinhala reviewed.

### Sat Nov 28 — Build and install

- [ ] Make the release build
- [ ] Install on at least 3 real phones
- [ ] Smoke test on every phone: onboard, log, miss days, get nudged, delete data

**Done when:** smoke test passes on all phones.

### Sun Nov 29 — Release

- [ ] Write the short tester guide, including the clear note that a lost phone means lost progress
- [ ] Write the feedback form. It must ask directly about feeling shamed or pressured, and cover the measures in [After the release](#after-the-release)
- [ ] Send the build to 10 testers

**Done when:** 10 testers have it.

---

## If the build falls behind

Cut in this order:

1. Evening notification (keep only the morning one)
2. "My data" edit (keep view and delete)
3. Quick-reply buttons on notifications (open the app instead)
4. Step-up suggestion (the agent only makes things smaller for now)
5. Full Sinhala review (ship Sinhala with the fixed phrases only, marked "beta")

**Never cut:** the health check, the rules engine, the hard stop, the AI disclosure, the no-shame blocklist. If hours still run short, move the release to the next Sunday.

Anything outside the MVP scope (widget, voice, extra habits, topic chats) goes on a "later" list, not into these two weeks.

## Release gate (definition of done)

- [ ] A new user goes from install to "tomorrow's tasks" in under 3 minutes
- [ ] Rules tests pass 100%
- [ ] All 4 sample-person conversations behave as designed: no shame, no pressure, hard stop works
- [ ] No chat or log content is stored on the gateway. Gateway logs hold only counts and error codes
- [ ] Today's tasks and logging work offline
- [ ] The app works in both Sinhala and English

---

## After the release

### First two weeks: measure and fix

- [ ] Collect the feedback forms
- [ ] Beginners who finish day one — target: most of them
- [ ] Testers still logging after 7 days — target: at least half
- [ ] Nudge replies — target: more replies than ignores
- [ ] Testers who mute or turn off nudges — target: very few
- [ ] Moments a tester felt shamed or pressured — target: zero
- [ ] Fix what testers found
- [ ] Plan the public Play Store release, following the Day 1 Play Store check

### Companion phase

- [ ] **Google Drive backup — must land before the app opens beyond the first 10 testers**
  - [ ] Optional and off by default, asked once after the first week
  - [ ] Off / Daily / Weekly plus "Back up now", runs on charge or Wi-Fi
  - [ ] Encrypted on the phone with the user's backup password before upload
  - [ ] Saved in the private app folder on Drive
  - [ ] Restore: sign in, tap Restore, enter the password. Notification schedules are rebuilt
  - [ ] Clear warning that a forgotten password cannot be recovered, plus a "back up now" check that proves the password works
  - [ ] Backup tests: back up, wipe, restore. Wrong password fails safely
  - [ ] Remove the lost-phone note from Settings
- [ ] Topic chats: Exercise, Diet, Health issues. Suggest only, changes show in General
  - [ ] Topic limits in the rules engine, plus chat boundary tests
  - [ ] Pain or illness in any chat is saved to memory and the plan goes extra gentle
- [ ] More cards: Stage card, Progress card, Time picker
- [ ] Home-screen widget
- [ ] Smarter notifications: nudge timing and back-off learning
- [ ] Voice, including the choice of speech-to-text service
- [ ] On-device AI: a small open model for rewording nudges and short replies
- [ ] "Notes from chats" and "What works for you" memory, both viewable and editable by the user

### Expander phase

- [ ] More built-in plugins: reading, sleep, study
- [ ] Custom plugin builder: fixed form only, no code, scripts or links
  - [ ] Body habits always get the light health check
  - [ ] Plugin tests: a custom plugin that tries to remove a core rule fails safely
- [ ] One daily notification limit across all projects
- [ ] Optional plugin sharing file
- [ ] iOS

### Parked

- [ ] "Habit coach download center" — waits until the plugin sharing file exists

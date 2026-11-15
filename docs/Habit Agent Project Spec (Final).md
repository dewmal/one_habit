# Habit Agent: Project Spec (Final)

Nov 15, 2026 · @Dewmal Handapangoda

## 1. Summary

Habit Agent is an Android chat app where an AI coach helps one person build one habit at a time, starting with going to the gym, in Sinhala and English. The first build goes to 10 testers on Sunday Nov 29, 2026, after a two-week build that starts Monday Nov 16.

Three ideas hold the whole product together:

- **Everything lives on the phone.** There is no Habit Agent server and no Habit Agent account. The only outside parts are a small stateless LLM gateway and the user's own Google Drive for backup.
- **The AI suggests, fixed rules decide.** A rules engine written as plain code has the final say on every plan change, nudge and message.
- **Every habit is a plugin.** A habit is data, not code, so adding a new habit later does not mean rewriting the app.

This spec merges the design, the technical architecture and the 2-week MVP plan into one document. Items that were marked "recommended" or "open" in those documents are settled in section 2.

## 2. Final decisions

Every choice below is final for the MVP. The second table takes the recommended option from the architecture doc and locks it, so the build can start on Nov 16 without waiting. Change any row before Day 1 if you disagree.

### Decided earlier

| Area | Decision |
| --- | --- |
| Name | Habit Agent |
| Platforms | Android first, iOS next |
| First habit | Fitness (gym) |
| Languages | Sinhala and English at launch |
| Where it runs | Fully on the phone. No Habit Agent server, no account. LLM gateway only |
| AI and rules | A mix: the AI writes and suggests, fixed rules decide |
| Health check | Light check: 3 to 4 yes/no questions. Any "yes" keeps the plan gentle and suggests a doctor. Never blocks the user |
| Enthusiasm | Measured by both self-report (easy / okay / hard) and completion data |
| Notifications | The user sets the daily count. One limit across all projects |
| Product shape | Chat app with interactive cards. Habit = plugin. Each habit runs as a project with one General chat plus topic chats |
| Custom habits | Users can make basic custom plugins |
| Backup | WhatsApp-style, to the user's own Google Drive |

### Locked in this spec

| Area | Final choice | Why |
| --- | --- | --- |
| App framework | Flutter | One codebase for Android now and iOS next. Supports local notifications and widgets |
| Phone database | SQLite, encrypted | Simple, proven, works offline |
| Cards | A fixed set built into the app | The AI picks a card and fills the words. It never writes screen code |
| Gateway | One small stateless function | Holds the AI key, forwards the request, keeps nothing |
| Gateway protection | Android app-check, per-device rate limit, spending cap on the AI account | There are no accounts, so abuse must be stopped another way |
| Big AI | One hosted model through the gateway | Provider is picked on Day 1 by the Sinhala test (section 12) |
| On-device AI | Not in the MVP. A small open model (about 1 to 3 billion parameters) later | Biggest time sink, least learning for the first test |
| Topic chat scope | The limits in section 4. Diet chat covers simple eating habits only | Going further is a safety change, not a feature |
| Topic chats and the plan | Suggest only. Changes go through the rules engine and show in General | One place where the plan changes |
| Backup key | A password the user sets. It is the only key | Survives a lost phone. Cannot be recovered if forgotten, and the app says so |
| Custom plugins | Fixed form only. No code, no scripts, no links, no sharing for now | Keeps custom habits safe without a server |
| Speech to text | Not in the MVP. Service is chosen when voice is built | Voice is a later phase |

## 3. Product structure

The app is built from three things: plugins, projects and chats. Every project looks and behaves the same way, and only the content changes.

| Word | What it is | Example |
| --- | --- | --- |
| Plugin | The recipe for a kind of habit. Plain data, built once, used many times | "Fitness" plugin |
| Project | The user's own copy of a plugin. Holds the plan, log, memory and chats | "Improve my fitness" |
| Chat | A conversation inside a project | General, Exercise, Diet, Health issues |

### What a plugin holds

- Name, icon, color and a short description
- The levels (Beginner / Building / Ready) and the questions that place a person
- The stages and the rule for moving on
- How to write small daily tasks for this habit
- An optional safety check (Fitness has the light health check)
- Which topic chats and which cards it uses

A custom plugin is the same file, filled through a fixed form: the user describes the habit in chat, the agent fills the form, the user reviews and saves. Custom habits about the body (food, fasting, medicine, hard exercise) always get the light health check.

### Chats

| Chat | Job | Can it change the plan? |
| --- | --- | --- |
| General (always there) | The coach. Asks the starting questions, knows the plan, checks in, celebrates | Yes, through the rules engine |
| Topic chats (Exercise, Diet, Health issues) | A specialist for one subject. Can log and answer | Only by suggestion, which shows up in General |

All chats share the project's memory, so the user never repeats themselves. Each chat keeps its own history and a short running summary on the phone.

### Cards

The agent can drop a card into a message and the user taps it. A tap writes straight to memory with no AI call, so it costs nothing and works offline.

| Card | What it does | In the MVP |
| --- | --- | --- |
| Quick replies | Tap buttons instead of typing | Yes |
| Yes / No question | One question per card (health check, ask-first moments) | Yes |
| Task checklist | Today's small tasks with tick boxes | Yes |
| Log card | Done / partly / skipped, then easy / okay / hard | Yes |
| Level card | Starting level and tomorrow's tasks | Yes |
| Step-up offer | "Ready for a bit more?" with Yes / Not yet | Yes, first on the cut list |
| Info card | A short fixed note, such as "please see a doctor" | Yes |
| Stage card | Current stage and what moves the user on | Later |
| Progress card | Days done, gaps, how it felt, in plain words, no scores | Later |
| Time picker | Pick a nudge time | Later |

### Project views

Every project has three views besides its chats: **Today** (only today's tasks), **Plan** (stages, read only) and **History**.

## 4. Safety rules

The AI never changes a plan directly. Every change goes through the rules engine first, in every chat and every plugin. A promise written only in an AI prompt can be forgotten by the AI. A promise written as a fixed rule cannot.

### Core promises

No plugin, built-in or custom, can switch these off. A plugin can add a safety rule but never remove one.

1. **No shame.** No guilt, no fake urgency, no streak-loss threats in any message.
2. **Smaller after misses, never bigger.** Missed days never reset the plan.
3. **Ask first.** Bigger steps and stage changes need the user's yes, and a bigger step is always tiny.
4. **Respect quiet.** The user's daily notification limit and quiet hours always apply.
5. **Hard stop.** If the user says they feel unwell or very low, all pushing stops and a care message is sent.
6. **Health lock.** Any "yes" in the health check locks the project to the gentlest level and shows the "see a doctor" note.
7. **Honesty.** The agent says it is an AI on first run.

### AI suggests, rules decide

| AI suggests | Rules engine checks | Result |
| --- | --- | --- |
| "Make tomorrow's tasks bigger" | Did the user approve? Is the jump tiny? | Blocked unless the user said yes |
| "Make tomorrow's tasks smaller" | Always allowed | Applied, no permission needed |
| "Send a 5th nudge today" | Over the daily limit or in quiet hours? | Blocked |
| "Move to the next stage" | Did the user choose it? | Blocked until the user says yes |
| A custom plugin tries to turn off a rule | Core rules cannot be removed | Ignored |
| Any reply after "I feel unwell" | Hard-stop rule triggered | Pushing stops, care message sent |

### Topic chat limits

| Chat | Allowed | Not allowed |
| --- | --- | --- |
| Exercise | Tips, form basics, making a task easier or swapping it | Programs for medical conditions |
| Diet | Simple eating habits (water, regular meals, adding a vegetable), ideas, questions about the plan | Calorie targets, diet plans, fasting plans, anything for a medical diet |
| Health issues | Listening, noting pain or illness, making the plan gentler, helping prepare for a doctor visit | Diagnosing, treatment advice, medicine advice |

Pain or illness mentioned in any chat is saved to the project's memory, and the plan goes extra gentle until the user says they are okay. Extreme requests, such as severe fasting, are not planned. The agent stays very gentle and suggests seeing a doctor.

### Fixed wording

The most sensitive moments use fixed, approved Sinhala and English phrases instead of AI text: a missed day, the hard stop, and the step-up question.

## 5. Architecture

Six parts run on the phone and two small parts sit outside it. Most days need no outside call at all.

&#91;embedded content: architecture · 6 parts on the phone, 2 outside\]

The agent brain reads plugins and memory, and every suggestion it makes passes the rules engine before anything changes. Only two things leave the phone: a small request to the gateway and, once backup exists, one locked file to the user's Drive.

### The parts

| Part | Plain job | Lives where |
| --- | --- | --- |
| Screens | Chats, cards and project views | Phone |
| Agent brain | Runs the loop: look, think, suggest, act | Phone |
| Rules engine | Checks every suggestion against the fixed rules | Phone |
| Plugins | The recipes for each kind of habit | Phone |
| Memory | Remembers the user and each project, in encrypted SQLite | Phone only |
| Backup | Saves an encrypted copy (after the MVP) | The user's Google Drive |
| LLM gateway | Safe doorway to the big AI | Outside, stateless |

### Where the AI runs

| Job | Runs on |
| --- | --- |
| Today's tasks, tapping cards, logging | Phone, no AI at all |
| First chat to get to know the user | Big AI through the gateway |
| Writing daily tasks, rebuilding a plan | Big AI through the gateway |
| "I'm stuck" conversations and topic chats | Big AI through the gateway |
| Drafting a custom plugin (later) | Big AI through the gateway |
| Rewording a nudge, short replies (later) | Small model on the phone |
| Offline | Phone: saved plan, cards and logging still work |

### Memory

| Memory | Holds | Who can edit |
| --- | --- | --- |
| About you (shared) | Profile, language, quiet hours, notification limit | The user |
| The habit | Goal in the user's words, clear target, starting level, safety check result | The user |
| The plan | Stages, current stage, rule for moving on | The agent, through the rules. The user can view |
| Daily log | Date, each task's result, how it felt | The user logs, the agent reads |
| Chat history | Each chat's messages and a short summary | The user can delete |
| Notes from chats (later) | Things told to any chat, such as "knee hurts" | The user can view and edit |
| What works for you (later) | Best nudge times, skipped tasks, words that motivate | The agent learns, the user can view and edit |

### The LLM gateway

The gateway does three things and nothing else:

1. Holds the AI key, so the app never contains secrets.
2. Passes the request to the big AI and returns the answer.
3. Protects itself from abuse with app-check, a per-device rate limit and a spending cap.

It has no login, no user database, no saved prompts or answers, and no analytics about people. Its logs hold only counts and error codes.

### Notifications and the daily flow

Notifications are scheduled on the phone, so they work with the app closed and the internet off.

| Step | What happens | Where |
| --- | --- | --- |
| Morning | The agent reads the plan and yesterday's log, then picks today's tasks and nudge times. The rules engine trims nudges to the daily limit and removes quiet hours | Phone |
| Day | Nudges fire. The user taps \[Done\], \[Later\] or \[Too hard\], which writes straight to the log | Phone |
| Evening | The user taps the log card: results, then easy / okay / hard | Phone |
| Night | The agent reads progress and proposes a change. The rules engine approves it or holds it for the user's yes | Phone, and the gateway only if tasks are rewritten |
| Any time | The user chats in General | Phone and gateway |

## 6. Privacy and backup

The gateway gets only what the AI needs for one request and keeps nothing afterwards. There is no Habit Agent account, so the gateway cannot connect a request to a person.

| Stays on the phone, always | May be sent in a request, only when needed |
| --- | --- |
| Full daily log and chat history | A short summary and the last few messages of the open chat |
| Health-check answers | Only the result: "keep very gentle" |
| Name, contact details | Nothing |
| What-works-for-you memory | Only the one fact the message needs |
| The user's Google account | Never sent to the gateway |

A "My data" screen lets the user view and delete anything, for one project or the whole app. Delete means delete.

### Google Drive backup (after the MVP)

Backup protects against a lost phone, the same way WhatsApp does. It is built in the Companion phase, before the app opens beyond the first 10 testers.

1. **Turn on.** In Settings, choose "Back up to Google Drive" and sign in with Google.
2. **Choose how often.** Off, Daily or Weekly, plus a "Back up now" button. Backups run on charge or Wi-Fi.
3. **Encrypted on the phone first.** The file is locked with the user's backup password before it leaves the phone. Google only sees a locked file.
4. **Saved in the private app folder.** Only this app can open it. The app never sees other Drive files.
5. **Restore.** Install the app, sign in with the same Google account, tap "Restore", enter the backup password.

Rules that keep it private:

- Google sign-in is only for backup. It is not a Habit Agent account.
- Backup is optional and off by default. The app asks once, after the first week.
- The backup password is the only key. If it is forgotten, nobody can open the backup, and the app says this clearly when backup is turned on.
- The backup holds the profile, all projects, plans, logs, chat history, notes and custom plugins. Notification schedules are rebuilt after restore.

## 7. MVP scope

The MVP in one sentence: a tester opens the app, tells the agent "I want to go to the gym every day", answers a few questions, gets a tiny plan for tomorrow, logs how it went, and watches the agent make things smaller when they miss days. If a tester can do that for 7 days without confusion, the MVP worked.

| In the MVP (must ship) | Out for now |
| --- | --- |
| Android app, Sinhala and English | iOS |
| One plugin (Fitness), one project, General chat only | Topic chats, other habits, custom plugins |
| Light health check (3 to 4 yes/no screens) | Anything medical beyond the "see a doctor" note |
| Up to 5 questions, level placement (Beginner / Building / Ready) | Re-placement after months |
| Plan built in stages, only today's tasks shown | Home-screen widget |
| Daily log: done / partly / skipped, plus easy / okay / hard | "What works for you" learning memory |
| Adaptation rules: smaller after misses, tiny step up only with a yes | Smart nudge timing and back-off learning |
| Two local notifications a day with quick-reply buttons, quiet hours, daily limit | Voice notes, on-device AI model |
| Rules engine: health lock, no-shame blocklist, hard stop | Bring-your-own-key mode |
| "My data" screen: view and delete | Google Drive backup, encrypted export |
| Stateless LLM gateway | Success dashboards |

### Simplifications that save time

- **Plan stages come from a fixed gym template.** The AI only writes the small daily tasks for the current stage.
- **The health check is fixed screens, not AI.** Same questions every time, easy to test.
- **The rules engine is plain if/else code.** Small, readable, 100% tested.
- **All AI calls go through the gateway.** If offline, the app shows today's saved tasks and accepts logs.
- **Notifications are simple.** One in the morning, one in the evening, both scheduled on the phone.
- **The plugin and project shape is built properly from day one.** The habit is data and no screen says "gym", so nothing is rewritten later.

## 8. Schedule

The build runs Mon Nov 16 to Sun Nov 29, 2026, and ends with a release to 10 testers. It assumes one builder at about 4 focused hours a day. If the hours are different, keep the order and use the cut list.

### Week 1: the agent can talk and make a plan

| Day | Goal | Done when |
| --- | --- | --- |
| Mon 16 | **Decide and set up.** Run the Sinhala test (about 10 sample messages) on 1 or 2 AI providers and pick one. Create the Flutter project and the encrypted SQLite tables: profile, habit, plan, daily log | Provider chosen. App runs on the phone. Tables exist |
| Tue 17 | **Gateway.** Stateless function that holds the AI key and forwards requests. Per-device rate limit and a spending cap. Basic chat screen that talks through it | Chat works from the phone. Nothing is stored on the gateway |
| Wed 18 | **Getting to know you.** Goal understanding, up to 5 questions, then the 3 to 4 fixed health-check screens | Chat asks the questions and saves answers to the phone |
| Thu 19 | **Level placement and plan.** Place the user. Load the gym stage template. AI writes today's and tomorrow's tiny tasks | A Beginner gets a few tiny tasks. A Ready person starts near the real habit |
| Fri 20 | **Today screen and rules engine v1.** Show only today's tasks. Health lock and the no-shame blocklist on every outgoing message | Rules tests pass. Blocked wording never reaches the screen |
| Sat 21 | **Buffer.** Catch up and fix rough edges | Week 1 goals all met |
| Sun 22 | **Rest, then one demo.** Show it to one or two friends and note what confused them | A short list of fixes for Monday |

### Week 2: the daily loop, safety and release

| Day | Goal | Done when |
| --- | --- | --- |
| Mon 23 | **Logging.** Done / partly / skipped per task, then easy / okay / hard. Fixed Sinhala and English reply phrases | Logs save to the phone and show in history |
| Tue 24 | **Adaptation rules.** Misses make tasks smaller, never bigger. Consistent and easy offers a tiny step up and asks first. Never reset the plan | Rules tests pass 100%, including "after three misses the plan can never get bigger" |
| Wed 25 | **Notifications.** Morning and evening local notifications with \[Done\] \[Later\] \[Too hard\] buttons. Quiet hours and the daily limit | Works with the app closed and internet off |
| Thu 26 | **Hard stop, My data, honesty.** Hard stop and care message. "My data" view and delete. First-run AI disclosure. Offline fallback | Hard stop tested. Delete really deletes |
| Fri 27 | **Test and freeze.** Run the 4 sample-person conversation tests. Native speaker reviews the Sinhala. Fix bugs. Feature freeze at end of day | No open safety bugs. Sinhala reviewed |
| Sat 28 | **Build and install.** Release build on at least 3 real phones. Full smoke test: onboard, log, miss days, get nudged, delete data | Smoke test passes on all phones |
| Sun 29 | **Release.** Send the build to 10 testers with a short guide and a feedback form | 10 testers have it |

### If the build falls behind, cut in this order

1. Evening notification (keep only the morning one)
2. "My data" edit (keep view and delete)
3. Quick-reply buttons on notifications (open the app instead)
4. Step-up suggestion (the agent only makes things smaller for now)
5. Full Sinhala review (ship Sinhala with the fixed phrases only, marked "beta")

**Never cut:** the health check, the rules engine, the hard stop, the AI disclosure, the no-shame blocklist. If hours still run short, move the release to the next Sunday.

## 9. Testing and definition of done

The release is done when all six checks below pass.

- [ ] A new user goes from install to "tomorrow's tasks" in under 3 minutes
- [ ] Rules tests pass 100%
- [ ] All 4 sample-person conversations behave as designed: no shame, no pressure, hard stop works
- [ ] No chat or log content is stored on the gateway. Gateway logs hold only counts and error codes
- [ ] Today's tasks and logging work offline
- [ ] The app works in both Sinhala and English

### How the agent is tested

| Test | What it checks | When |
| --- | --- | --- |
| Rules tests | Fixed and exact, such as "after three missed days the plan can never get bigger". Must pass 100% | MVP |
| Conversation tests | Four sample people: total beginner, busy active person, keeps skipping, says they feel low | MVP |
| Sinhala check | A native speaker reviews replies, since AI Sinhala is weaker than English | MVP |
| Smoke test | Onboard, log, miss days, get nudged, delete data, on at least 3 real phones | MVP |
| Plugin tests | Every plugin runs the same rules tests. A custom plugin that tries to remove a rule must fail safely | With custom plugins |
| Chat boundary tests | The Diet chat declines a calorie plan and the Health issues chat declines a diagnosis, both kindly | With topic chats |
| Backup tests | Back up, wipe, restore. A wrong password fails safely and a lost password gives a clear message | With backup |

## 10. Success measures

The MVP succeeds if most beginners finish day one and at least half of the 10 testers are still logging after 7 days. These are measured in the two weeks after release, from the testers' feedback form, since no analytics about people leave the phone.

| Measure | Target for the first group |
| --- | --- |
| Beginners who finish day one | Most of them. This proves the first plan is easy enough |
| Testers still logging after 7 days | At least half |
| Nudge replies | More replies than ignores |
| Testers who mute or turn off nudges | Very few. Any mute means the agent talks too much |
| Moments a tester felt shamed or pressured | Zero. Asked directly in the feedback form |

## 11. Roadmap after the MVP

After the release, the first job is fixing what testers found. Google Drive backup must land before the app opens beyond the first group, because it is the only protection against a lost phone.

| Phase | What gets built |
| --- | --- |
| MVP (Nov 16 to 29) | One plugin (Fitness), one project, General chat, core cards, rules engine, gateway |
| Companion | Google Drive backup, topic chats (Exercise, Diet, Health issues), more cards, home-screen widget, smarter notifications, voice, on-device AI, "what works for you" memory |
| Expander | More built-in plugins (reading, sleep, study), custom plugin builder, optional plugin sharing file, iOS |

One more idea is parked for later: a simple "habit coach download center" with one coach for now and more added over time. It needs a place to host coach files, so it waits until the plugin sharing file exists.

## 12. Risks and Day 1 checks

Three things can only be settled by a test or a lookup on Mon Nov 16. Everything else in this spec is final.

- [ ] **Pick the AI provider.** Run about 10 Sinhala sample messages on 1 or 2 providers and choose the better one
- [ ] **Check Play Store rules.** A new personal developer account may need a closed test before public release. Confirm what applies
- [ ] **Choose how testers get the build.** Direct file or the internal testing track

| Risk | Plan |
| --- | --- |
| AI Sinhala quality is weak | Test on Day 1. Keep AI messages short. Use fixed approved phrases for key moments |
| Lost phone means lost progress | Accepted for the MVP and told to testers clearly. Backup lands before the group grows |
| Gateway abused with no accounts | App-check, per-device rate limit and a spending cap, set up on Day 2 |
| Scope creep (widget, voice, extra habits) | Anything outside section 7 goes on a "later" list |
| Part-time hours run short | Use the cut list in section 8, then move the release one week. Never cut safety |
| More structure slows the MVP | Build the plugin and project shape now, but ship only one plugin and one chat |
| Topic chats drift into medical or diet advice | Topic limits in the rules engine, plus boundary tests |
| A custom plugin creates an unsafe habit | Fixed form, core rules cannot be removed, body habits get the health check |
| Too many projects means too many nudges | One daily limit across all projects |
| Forgotten backup password | Clear warning when backup is turned on, plus a "back up now" check that proves the password works |

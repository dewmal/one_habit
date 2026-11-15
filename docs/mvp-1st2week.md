# Habit Agent: MVP Plan (2-Week Release)

Nov 15, 2026 · Companion to "Habit Agent Agentic Application Design" and "Habit Agent Technical Architecture"

**Window:** Mon Nov 16 to Sun Nov 29, 2026
**Release:** Android build to the first 10 real testers on Nov 29
**Assumptions:** one builder (you), about 4 focused hours a day, Flutter, fitness (gym) habit only. If your hours are different, keep the order and cut from the bottom of the "cut list" in section 5.

## 1. The MVP in one sentence

A tester opens the app, tells the agent "I want to go to the gym every day", answers a few questions, gets a tiny plan for tomorrow, logs how it went, and watches the agent make things smaller when they miss days. All on the phone.

If a tester can do that for 7 days without confusion, the MVP worked.

## 2. What is IN and what is OUT

| In the MVP (must ship) | Out for now (later phases) |
| --- | --- |
| Android app, Sinhala and English | iOS |
| Chat screen with the agent | Voice notes |
| Gym habit only | Reading, sleep, study, any other habit |
| Light health check (3 to 4 yes/no) | Anything medical beyond "see a doctor" note |
| Up to 5 questions, level placement (Beginner / Building / Ready) | Re-placement after months |
| Plan built in stages, today's tasks only shown | Home-screen widget |
| Daily log: done / partly / skipped, plus easy / okay / hard | "What works for you" learning memory |
| Adaptation rules: smaller after misses, tiny step up only with your yes | Smart nudge timing and back-off learning |
| Two local notifications a day with quick-reply buttons, quiet hours, daily limit | On-device small AI model |
| Rules engine: health lock, no-shame blocklist, hard stop | Bring-your-own-key mode |
| "My data" screen: view and delete | Encrypted export and backup file |
| Stateless LLM gateway | Success dashboards |

Why this cut: the design doc's Phase 1 (listener) alone is not enough to test the habit idea, because nothing is logged. So the MVP is **Phase 1 plus the smallest slice of Phase 2** (logging and the adaptation rules). The widget, voice, and on-device AI are the biggest time sinks and add the least to learning whether the agent idea works.

## 3. Simplifications that save time (and stay true to the design)

- **Plan stages come from a fixed gym template** (the 5 stages in the design doc). The AI only writes the small daily tasks for the current stage. It does not invent the whole plan.
- **Health check is fixed screens, not AI.** Same questions every time, easy to test.
- **Rules engine is plain if/else code.** Small, readable, 100% tested.
- **All AI calls go through the gateway.** No on-device model yet. If offline, the app shows today's saved tasks and accepts logs.
- **Notifications are simple:** one morning, one evening, both scheduled on the phone.
- **Fixed Sinhala phrases** for key moments (missed day, hard stop, step-up question) so the AI is not trusted with the most sensitive wording.
## 4. Day-by-day plan

### Week 1: the agent can talk to you and make a plan (Nov 16 to 22)

| Day | Goal | Done when |
| --- | --- | --- |
| Mon 16 | **Decide and set up.** Run a quick Sinhala test (about 10 sample messages) on 1 or 2 AI providers and pick one. Create the Flutter project. Create the encrypted SQLite tables: profile, habit, plan, daily log. | Provider chosen. App runs on your phone. Tables exist. |
| Tue 17 | **Gateway.** Small stateless function that holds the AI key, forwards the request, and returns the answer. Add a simple per-device rate limit and a spending cap on the AI account. Add a basic chat screen that talks through it. | You can chat with the AI from the phone. Nothing is stored on the gateway. |
| Wed 18 | **Getting to know you.** Goal understanding, up to 5 questions, then the 3 to 4 fixed health-check yes/no screens. | Chat asks the questions and saves answers to the phone. |
| Thu 19 | **Level placement and plan.** Place the user (Beginner / Building / Ready). Load the gym stage template. AI writes today's and tomorrow's tiny tasks for the current stage. | A Beginner gets a few tiny tasks. A Ready person starts near the real habit. |
| Fri 20 | **Today screen and rules engine v1.** Show only today's tasks. Add the health lock (any "yes" means gentlest level plus "see a doctor" note) and the no-shame blocklist on every outgoing message. | Rules tests pass. Blocked wording never reaches the screen. |
| Sat 21 | **Buffer.** Catch up on anything unfinished. Fix rough edges. | Week 1 goals all met. |
| Sun 22 | **Rest, then one demo.** Show it to one or two friends. Write down what confused them. | A short list of fixes for Monday. |

### Week 2: the daily loop, safety, and release (Nov 23 to 29)

| Day | Goal | Done when |
| --- | --- | --- |
| Mon 23 | **Logging.** Done / partly / skipped per task, then easy / okay / hard. Use the fixed Sinhala and English reply phrases. | Logs save to the phone and show in history. |
| Tue 24 | **Adaptation rules.** Misses make tasks smaller, never bigger. Consistent and easy offers a tiny step up and asks first. Never reset the plan. Write the rules tests. | Rules tests pass 100%, including "after three misses the plan can never get bigger". |
| Wed 25 | **Notifications.** Morning and evening local notifications with [Done] [Later] [Too hard] buttons writing to the log. Quiet hours and the user's daily limit setting. | Works with the app closed and internet off. |
| Thu 26 | **Hard stop, My data, honesty.** "Unwell" or "very low" stops all pushing and sends a care message. "My data" screen to view and delete. First-run line saying the agent is an AI. Offline fallback. | Hard stop tested. Delete really deletes. |
| Fri 27 | **Test and freeze.** Run the 4 sample-person conversation tests (total beginner, busy active person, keeps skipping, says they feel low). Native speaker reviews the Sinhala. Fix bugs. **Feature freeze at end of day.** | No open safety bugs. Sinhala reviewed. |
| Sat 28 | **Build and install.** Make the release build. Install on at least 3 real phones. Run a full smoke test: onboard, log, miss days, get nudged, delete data. | Smoke test passes on all phones. |
| Sun 29 | **Release.** Send the build to 10 testers with a short guide and a feedback form. | 10 testers have it. |

## 5. If you fall behind: cut in this order

1. Evening notification (keep only the morning one)
2. "My data" edit (keep view and delete)
3. Quick-reply buttons on notifications (open the app instead)
4. Step-up suggestion (agent only makes things smaller for now)
5. Full Sinhala review (ship Sinhala with the fixed phrases only, mark it "beta")
   **Never cut:** the health check, the rules engine, the hard stop, the AI disclosure, the no-shame blocklist. These are the safety promises from the design.

## 6. Definition of done for release

- A new user can go from install to "tomorrow's tasks" in under 3 minutes.
- Rules tests pass 100%.
- All 4 sample-person conversations behave as the design says (especially: no shame, no pressure, hard stop works).
- No chat or log content is stored on the gateway. Gateway logs hold only counts and error codes.
- Works offline for today's tasks and logging.
- Works in both Sinhala and English.
## 7. What to measure in the first 2 weeks after release

Taken from the design doc, trimmed to what 10 testers can tell you:

| Measure | Target for the first group |
| --- | --- |
| Beginners who finish day one | Most of them (this proves the first plan is easy enough) |
| Testers still logging after 7 days | At least half |
| Nudge replies | More replies than ignores |
| Testers who mute or turn off nudges | Very few. Any mute means the agent talks too much |
| Moments a tester felt shamed or pressured | Zero. Ask directly in the feedback form |

## 8. Risks for these two weeks

| Risk | What to do |
| --- | --- |
| Sinhala AI quality is weak | Do the Sinhala test on Day 1. Use fixed phrases for key moments. Keep AI messages short. |
| Play Store timing | A new personal Google Play developer account may need a closed test with a number of testers over a set number of days before public release. Check this on Day 1. For the MVP, share the build directly or through the internal testing track, and plan the public Play release after testers have used it. |
| Gateway abused with no accounts | Rate limit per device and a spending cap on the AI account, set up on Day 2. |
| Lost phone means lost progress | Accept this for the MVP. Tell testers clearly. Export file comes in a later phase. |
| Scope creep (widget, voice, extra habits) | Anything not in section 2 goes on a "later" list, not into these two weeks. |
| Part-time hours run short | Use section 5 to cut, and move the release to the next Sunday if needed. Do not cut safety. |

## 9. Open decisions to settle on Day 1

1. Confirm Flutter (recommended in the architecture doc) or go native Kotlin.
2. Pick the AI provider after the Sinhala test.
3. Pick the Sinhala speech service later, since voice is not in the MVP.
4. Confirm how testers get the build (direct file, or internal testing track).
## 10. After the release (next 2 weeks, preview)

Fix what testers found, then start Phase 3 in this order: widget, smarter notifications, voice, then the "what works for you" memory. Add the encrypted export file before opening to more than the first group.
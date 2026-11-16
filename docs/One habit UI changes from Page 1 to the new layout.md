# One habit: UI changes from Page 1 to the new layout

Nov 16, 2026 · @Dewmal Handapangoda

The bottom tab bar is replaced by a menu button and a left side menu that lists habits and their chats. Page 1 of the design canvas ("First layout") is the starting point, and Page 2 ("New layout") holds the result: 19 screens, 4 of them new.

## At a glance

Seven things changed. The first three are already applied to Page 1 as well, because they were made there first. The last four exist only on Page 2.

| Area | Before (original first layout) | After (new layout) | Where |
| --- | --- | --- | --- |
| Main navigation | Bottom bar with four tabs: Chat, Today, Plan, History | Menu button at the top left of every screen after onboarding. It opens a side menu from the left | Page 1 and Page 2 |
| Settings | Settings icon on the Today screen | Icon in the bar at the bottom of the side menu, next to My data | Page 1 and Page 2 |
| New chat | Not possible. One General chat only | White plus button at the right of every chat header, and on the General row in the side menu | Page 1 and Page 2 |
| Habits | One habit, never listed | "Habits" section in the side menu. Shows the first 3, then "Show 2 more habits" | Page 2 (one side menu screen on Page 1) |
| Chats | One General chat | General pinned at the top of each habit, other chats listed below it | Page 2 (one side menu screen on Page 1) |
| Chat header | "General" and "Your coach · AI" | Chat name and the habit name: "General" and "Improve my fitness · AI" | Page 2 only |
| App name | Habit Agent | One habit | Page 2 only |

Today, before (left) and after (right):

&#91;image: Today screen before with the bottom bar and after with the menu button\]

Daily log in the chat, before (left) and after (right):

&#91;image: Daily log chat before with the bottom bar and after with the menu and plus buttons\]

The design canvas with both pages is here: [Habit Agent MVP UI](https://claude.ai/artifact/98Gj7tgdKYUKfEXosUubQh).

## Screen by screen

Of the 19 screens on Page 2, 4 are new, 8 changed and 7 are the same as Page 1 apart from the app name. "Bottom bar" below means the original four-tab bar that Page 1 started with.

| Page 2 screen | Comes from Page 1 screen | What changed |
| --- | --- | --- |
| 1 Welcome | 1 Welcome | App name is "One habit". Nothing else |
| 2 First questions | 2 First questions | No change. Onboarding has no menu button |
| 3 Health check | 3 Health check | No change |
| 4 Level and first plan | 4 Level and first plan | No change |
| 5 Side menu | Side menu | Replaces the bottom bar. Habits section, pinned General with a plus button, chat list, Today / Plan / History buttons, Settings and My data icons in a bottom bar |
| 6 Side menu, all habits | New | Habit list expanded to five, another habit open |
| 7 New chat | New | Opens from the plus button |
| 8 General chat | New | Everyday state of the General chat with today's steps as a card |
| 9 Topic chat | New | A second chat inside the habit |
| 10 Today | 5 Today | Bottom bar removed. Menu button added at the top left. Settings icon removed |
| 11 Daily log | 6 Daily log | Bottom bar removed. Menu button and plus button in the header. Header shows the habit name |
| 12 After missed days | 7 After missed days | Same three header and bar changes as Daily log |
| 13 Step-up offer | 8 Step-up offer | Same three header and bar changes as Daily log |
| 14 Notifications | 9 Notifications | App name is "One habit". Nothing else |
| 15 Hard stop | 10 Hard stop | Same three header and bar changes as Daily log |
| 16 Plan | 11 Plan | Bottom bar removed. Menu button added at the top left |
| 17 History | 12 History | Bottom bar removed. Menu button added at the top left |
| 18 Settings | 13 Settings | No change to the screen. It now opens from the side menu, not from Today |
| 19 My data | 14 My data | No change to the screen. It now opens from the side menu as well as from Settings |

## New screens

Five screens carry the new layout. The side menu is the centre of it, and the other four are reached from it or from the plus button.

### Side menu

&#91;image: Side menu with three habits on the left and with all habits shown on the right\]

Slides in from the left over a dimmed screen when the menu button is tapped.

- **Top:** app icon, app name, the current habit's name, and a close button.
- **Habits section:** the first 3 habits. The open habit shows its chats: General pinned at the top with a plus button on the same row, then the other chats. Under the chats are three buttons for that habit's views: Today, Plan, History.
- **Expand:** "Show 2 more habits" opens the full list. "Show fewer habits" closes it again.
- **Bottom bar:** fixed at the bottom, horizontal, with two icon buttons: Settings and My data. A one-line AI note sits just above it.
- **Closing:** the close button or a tap on the dimmed area.

### Side menu, all habits

The same menu after "Show 2 more habits". It lists all five habits and shows a different habit open, to make clear that tapping a habit switches the whole app to that project.

### New chat

&#91;image: New chat, General chat and Topic chat screens, left to right\]

Left to right: New chat, General chat, Topic chat.

Opens from the plus button in a chat header or on the General row.

- **Shows:** back button, title "New chat" with the habit name, three topics to pick (Exercise, Diet, Health issues), a field to name your own chat, a note, and a "Start chat" button.
- **Rule shown on screen:** every chat in a habit shares the same memory, and only the General chat can change the plan.

### General chat

The everyday state of the General chat: a morning message, today's steps as a checklist card, and two quick replies ("Log how it went", "Too hard today"). The header has the menu button, the coach icon, the chat name with the habit name under it, and the plus button.

### Topic chat

An Exercise chat inside the same habit. It uses a plain chat icon in place of the coach icon, so it is easy to tell apart from General. When the chat wants to change the plan it shows a "Suggestion sent to General" card, because a topic chat can only suggest.

## What this means for the build

The new layout removes one shared component, adds five, and needs the app to store more than one project and more than one chat. Widget names are suggestions.

### Components

| Component | Change | Notes |
| --- | --- | --- |
| BottomNav | Removed | No screen uses it any more |
| MenuButton | New | 44 px rounded square, three lines. Top left on every screen after onboarding |
| SideMenu | New | A Flutter Drawer, 304 px wide, rounded on the right side |
| HabitTile | New | One row per habit in the menu. Opens to show that habit's chats and views |
| ChatRow | New | One row per chat. The General row has the coach icon and a plus button |
| NewChatButton | New | White plus button, in chat headers and on the General row |
| ChatHeader | Changed | Now has MenuButton on the left, NewChatButton on the right, and the habit name in the second line |
| Settings icon on Today | Removed | Settings moved to the menu's bottom bar |

### Navigation

| From | Action | Goes to |
| --- | --- | --- |
| Any screen after onboarding | Menu button | Side menu |
| Side menu | Tap a habit | That habit opens in the menu and becomes the current project |
| Side menu | Tap General or another chat | That chat |
| Side menu | Today / Plan / History | That view of the open habit |
| Side menu | Plus on the General row | New chat |
| Chat header | Plus button | New chat |
| New chat | Pick a topic, or type a name and Start chat | The new chat |
| Side menu bottom bar | Settings icon / My data icon | Settings / My data |
| Topic chat | "Open General" | General chat of the same habit |

### Data

- The app must store a list of projects and remember which one is current. The first layout needed only one.
- Each project needs a list of chats with a name and a flag for the pinned General chat. Messages belong to a chat, not just to the project.
- A topic chat's suggestion must be saved so it can appear in General, where the rules engine decides.

### Scope

The project spec puts one habit and the General chat in the MVP, and topic chats in the later "Companion" phase. The multi-habit menu, New chat and Topic chat go beyond that. The other four habits shown in the menu (Read more, Drink water, Sleep earlier, Study daily) are sample names, not planned plugins.

## Open decisions

Five choices are still open. The first one decides how much of Page 2 is built in the two-week window.

- [ ] MVP scope: build the multi-habit menu and extra chats now, or ship one habit with General only and hide the plus button and habit list until later
- [ ] Which page is the source for the build: Page 2 only, or keep Page 1 in step with it
- [ ] App name on Page 1: Welcome and Notifications there still say "Habit Agent"
- [ ] Custom chat names: allow any name on the New chat screen, or only the plugin's topics for now
- [ ] The UI Screens Guide still describes the bottom bar and needs updating to match

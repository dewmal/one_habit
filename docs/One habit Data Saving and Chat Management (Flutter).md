# One habit — Data Saving & Chat Management (Flutter)

Nov 16, 2026 · @Dewmal Handapangoda

Nothing is saved to the phone yet. The encrypted database is written in code, but the app never opens it, so every chat, habit and log is lost when the app closes. This doc fixes that for the Flutter app, on Android now and iOS next, with two new tables, `chat` and `chat_message`, and a small set of rules for managing chats.

## 1. Where the code is today

These are the gaps found in the `one_preccent` Flutter project on Nov 16. They match the open ROADMAP item "Save chat messages to the phone".

| Area | Today | Problem |
| --- | --- | --- |
| Database | `lib/data/app_database.dart` creates 5 tables, but no screen or controller opens it | Nothing is written to the phone |
| Chat list | `ProjectsController` keeps sample projects and chats in memory | A new chat is gone after a restart |
| Chat id | Built from the title, like `fitness-Diet` | Breaks if a chat is renamed |
| General chat messages | `ChatState.messages`, in memory | Lost on restart |
| Topic chat messages | `TopicChats` map, in memory. The whole history is sent to the gateway | Lost on restart. The gateway allows 12 messages, so a longer topic chat gets `too_large` |
| `chat_history` table | Only `chat_id`, `role`, `text`, `created_at` | No list of chats, no place for cards, no failed state |
| Step-up suggestion from a topic chat | One true/false value in memory | Lost on restart |

## 2. What is saved, and where

All user data goes in the one encrypted SQLite file. That keeps "My data", delete and the later Google Drive backup simple, because there is only one place to look.

The same Dart code runs on every platform. `sqflite_sqlcipher` holds the encrypted database, `flutter_secure_storage` holds the key, and `getDatabasesPath()` picks the right folder on each phone. No screen or controller needs platform-specific code. The only per-platform work is the backup settings in section 8.

| Data | Where | Notes |
| --- | --- | --- |
| Profile and settings | `profile` table | One row. Language, daily limit, times, quiet hours |
| Habit projects | `habit` table | One row per habit |
| Plan | `plan` table | Stage and today's tasks |
| Daily log | `daily_log` table | One row per day |
| Chats | `chat` table (new) | One row per chat |
| Messages | `chat_message` table (new) | One row per bubble |
| Database key | Secure storage | Random, made once. Never in the database, never in a backup |
| Device id for the gateway | Secure storage | Random, not tied to a person |
| Which chat is open | Memory only | The app always opens on the General chat of the first habit |

Three rules:

1. **Save first, then show.** A message is written to the database before it appears on screen. The screen reads from the database, not from a list kept in memory.
2. **No user data outside the database.** No plain files and no shared preferences for chats, logs or answers.
3. **Health answers are not saved.** Only the result goes into `habit.safety_result`, as the spec says.

## 3. The chat data structure

A habit has many chats, and a chat has many messages. The `profile` table stands alone with one row, so it is not in the picture.

```
habit                 one row per habit project (name, goal, level, safety result)
 ├── plan             one per habit (stage and daily tasks)
 ├── daily_log        one row per day (results and feeling)
 └── chat  (new)      General plus topic chats (kind, title, summary)
      └── chat_message  (new)   one row per bubble (text or card, status)
```

`chat` and `chat_message` are new in schema version 2. They replace the old `chat_history` table.

### Table: `chat`

One row per chat. Every habit gets its General chat when the habit is created.

| Column | Type | Meaning |
| --- | --- | --- |
| `id` | INTEGER, primary key | A number the database gives. Never built from the title |
| `habit_id` | INTEGER | The habit this chat belongs to |
| `kind` | TEXT | `general` or `topic`. Only one `general` per habit |
| `title` | TEXT | "General", "Diet", or a name the user typed |
| `summary` | TEXT | Short running summary of older messages. Empty for now |
| `summary_upto` | INTEGER | Id of the last message that is inside the summary. 0 for now |
| `created_at` | INTEGER | Time in milliseconds |
| `updated_at` | INTEGER | Time of the newest message. The side menu sorts topic chats by this |

### Table: `chat_message`

One row per bubble on screen.

| Column | Type | Meaning |
| --- | --- | --- |
| `id` | INTEGER, primary key | Also gives the order of messages |
| `chat_id` | INTEGER | The chat this message belongs to |
| `role` | TEXT | `user` or `assistant`. The same two words the gateway accepts |
| `kind` | TEXT | `text`, `fixed` or `card` (see below) |
| `text` | TEXT | What the user typed or what the AI wrote. Empty for `fixed` and `card` |
| `text_key` | TEXT | For `fixed` only: the phrase key, like `chat.noted` |
| `card_type` | TEXT | For `card` only: `question`, `level`, `log`, `missed_day`, `step_up`, `hard_stop`, `info` |
| `card_data` | TEXT | For `card` only: the card's values as JSON |
| `card_answer` | TEXT | What the user tapped. Empty means the card is still open |
| `status` | TEXT | `sent` or `failed`. Only user messages can be `failed` |
| `created_at` | INTEGER | Time in milliseconds |

### The three kinds of message

| Kind | What it is | Saved as | Sent to the AI? |
| --- | --- | --- | --- |
| `text` | Typed by the user or written by the AI | The words, in `text` | Yes |
| `fixed` | An approved phrase, such as the missed-day reply | Only the key, in `text_key`. The app shows it in the current language | No |
| `card` | A built-in card | `card_type` plus `card_data`, then `card_answer` after the tap | No |

Saving the key instead of the words is what lets an old chat switch between Sinhala and English. A first question in onboarding is a `question` card whose `card_data` holds the question id, and the words come from the plugin.

### Small changes to the `habit` table

| New column | Type | Why |
| --- | --- | --- |
| `name` | TEXT | The project name in the side menu, like "Improve my fitness" |
| `pending_step_up` | INTEGER, 0 or 1 | A topic chat asked for a bigger step. General shows the step-up card next time it opens, then sets this back to 0 |

## 4. The code

Everything below goes into `lib/data/app_database.dart`. It is a sketch to copy from. It is not in the project yet and has not been run.

### The tables

```sql
CREATE TABLE chat (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  habit_id INTEGER NOT NULL,
  kind TEXT NOT NULL,
  title TEXT NOT NULL,
  summary TEXT NOT NULL DEFAULT '',
  summary_upto INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE chat_message (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  chat_id INTEGER NOT NULL,
  role TEXT NOT NULL,
  kind TEXT NOT NULL DEFAULT 'text',
  text TEXT NOT NULL DEFAULT '',
  text_key TEXT,
  card_type TEXT,
  card_data TEXT,
  card_answer TEXT,
  status TEXT NOT NULL DEFAULT 'sent',
  created_at INTEGER NOT NULL
);

CREATE INDEX chat_by_habit ON chat (habit_id);
CREATE INDEX message_by_chat ON chat_message (chat_id, id);

ALTER TABLE habit ADD COLUMN name TEXT;
ALTER TABLE habit ADD COLUMN pending_step_up INTEGER NOT NULL DEFAULT 0;
```

### Moving from version 1 to version 2

Set `_schemaVersion` to 2. Put the new statements in `_schema` for new installs, and add an `onUpgrade` for phones that already have version 1. The old `chat_history` table is empty on every phone, so it is safe to drop.

```dart
onUpgrade: (db, oldVersion, _) async {
  if (oldVersion < 2) {
    await db.execute('DROP TABLE IF EXISTS chat_history');
    for (final statement in _version2) {
      await db.execute(statement);
    }
  }
},
```

`_version2` is a list holding the six statements above. Also change `tableNames` so "My data" reads `chat` and `chat_message` instead of `chat_history`.

### The chat functions

```dart
int _now() => DateTime.now().millisecondsSinceEpoch;

/// Makes a chat. kind is 'general' or 'topic'. Returns the new chat id.
Future<int> createChat(int habitId, String kind, String title) {
  final now = _now();
  return _db.insert('chat', {
    'habit_id': habitId,
    'kind': kind,
    'title': title,
    'created_at': now,
    'updated_at': now,
  });
}

/// All chats of one habit. General comes first, then the newest topic chat.
/// ('general' sorts before 'topic' by alphabet.)
Future<List<Map<String, Object?>>> chatsOf(int habitId) => _db.query(
  'chat',
  where: 'habit_id = ?',
  whereArgs: [habitId],
  orderBy: 'kind ASC, updated_at DESC',
);

/// Saves one message and returns its id.
Future<int> addMessage(
  int chatId,
  String role, {
  String kind = 'text',
  String text = '',
  String? textKey,
  String? cardType,
  String? cardData,
}) async {
  final now = _now();
  final id = await _db.insert('chat_message', {
    'chat_id': chatId,
    'role': role,
    'kind': kind,
    'text': text,
    'text_key': textKey,
    'card_type': cardType,
    'card_data': cardData,
    'created_at': now,
  });
  await _db.update(
    'chat',
    {'updated_at': now},
    where: 'id = ?',
    whereArgs: [chatId],
  );
  return id;
}

/// All messages of one chat, oldest first.
Future<List<Map<String, Object?>>> messagesOf(int chatId) => _db.query(
  'chat_message',
  where: 'chat_id = ?',
  whereArgs: [chatId],
  orderBy: 'id',
);

/// Saves what the user tapped on a card.
Future<void> answerCard(int messageId, String answer) => _db.update(
  'chat_message',
  {'card_answer': answer},
  where: 'id = ?',
  whereArgs: [messageId],
);

/// Marks a user message as 'sent' or 'failed'.
Future<void> setStatus(int messageId, String status) => _db.update(
  'chat_message',
  {'status': status},
  where: 'id = ?',
  whereArgs: [messageId],
);

/// Deletes the messages of a chat. A topic chat is removed too.
/// The General chat stays, but empty.
Future<void> deleteChat(int chatId) async {
  await _db.delete('chat_message', where: 'chat_id = ?', whereArgs: [chatId]);
  await _db.delete(
    'chat',
    where: "id = ? AND kind = 'topic'",
    whereArgs: [chatId],
  );
}
```

One more change outside this file: `ChatInfo.id` in `lib/app/projects.dart` becomes an `int`, the row id from the `chat` table.

## 5. Chat management rules

The General chat is made with the habit and can never be removed. Everything else is a topic chat that the user can add and delete.

| Action | Rule |
| --- | --- |
| Create a habit | Save the `habit` row, then call `createChat(habitId, 'general', 'General')` right away |
| New chat (plus button) | Make a `topic` chat under the open habit. If a chat with the same title already exists, ignoring capital letters, open that one instead |
| Chat title | The plugin topic name (Exercise, Diet, Health issues) or a name the user typed. Cannot be empty |
| Side menu order | General fixed on top, then topic chats, newest activity first. This is what `chatsOf` returns |
| Open a chat | Load its messages with `messagesOf(chatId)`. App start always opens General |
| Tap a card | Save the tap with `answerCard`, then write to the plan or log. No AI call. An answered card is shown but cannot be tapped again |
| Topic chat wants a bigger step | Set `habit.pending_step_up` to 1. The topic chat never changes the plan itself |
| Hard stop in any chat | Save a `hard_stop` card in that chat and set `habit.paused` to 1 |
| Delete a topic chat | `deleteChat` removes its messages and the chat row |
| Clear the General chat | `deleteChat` removes its messages only. The plan and the daily log stay |
| Delete a habit | Remove its messages, chats, plan, daily log and the habit row, together in one transaction |

### Sending one message

1. Save the user's message with `addMessage(chatId, 'user', text: ...)` and show it.
2. Build the request from the database (section 6).
3. Call the gateway.
4. If a reply comes back, run it through the rules engine. If it passes, save it with `addMessage(chatId, 'assistant', text: ...)` and show it. A blocked reply is never saved.
5. If the call fails, mark the user's message with `setStatus(id, 'failed')`. The bubble shows "Try again". No error bubble is saved.

The MVP ships only the General chat, but the two tables already cover topic chats, so nothing changes in the database when they are turned on.

## 6. What is sent to the AI

The phone keeps the full chat, but each request carries only a short context line and the last 10 text messages of the open chat. This follows the privacy rule in the spec and stays inside the gateway limits of 12 messages and 8000 characters.

| Part of the request | What goes in | What never goes in |
| --- | --- | --- |
| Context line | Goal, level, "keep very gentle" if the health lock is on, the topic chat's title, the chat's `summary` if it is not empty | Health answers, name, the daily log |
| Messages | The last 10 rows of this chat where `kind` is `text` and `status` is `sent`, oldest first | Cards, fixed phrases, failed messages, messages from other chats |

Two small clean-up steps before sending:

- The list must start with a user message, so drop assistant messages from the front.
- If the text is over 6000 characters in total, drop the oldest message and check again. This leaves room for the instructions.

```dart
/// The last text messages of a chat, oldest first. Used to build an AI request.
Future<List<Map<String, Object?>>> recentTextMessages(
  int chatId, {
  int limit = 10,
}) async {
  final rows = await _db.query(
    'chat_message',
    where: "chat_id = ? AND kind = 'text' AND status = 'sent'",
    whereArgs: [chatId],
    orderBy: 'id DESC',
    limit: limit,
  );
  return rows.reversed.toList();
}
```

General and topic chats must both use this one function. Today the topic chats send their whole history, which is why they will hit `too_large`.

### The summary (after the MVP)

For the MVP the `summary` column stays empty. The goal and level in the context line are enough for a first week of short chats.

Later, when a chat has more than 20 text messages newer than `summary_upto`, the app makes one extra gateway call that folds the older messages into a few sentences. It saves the result in `summary` and the last covered message id in `summary_upto`. That call counts toward the 30 requests an hour, so it runs at most once per chat per day.

## 7. Offline and failed messages

Reading chats, tapping cards and logging never need the internet, because they only touch the database. Only a typed message needs the gateway.

| Situation | What the app does |
| --- | --- |
| No connection when sending | The user's message stays in the chat, marked `failed`, with "Try again" |
| "Try again" tapped | Set the message back to `sent` and send the request again. No second copy of the message is made |
| Gateway says `rate_limited` | Mark `failed` and show the fixed "short break" phrase. Do not retry in a loop |
| Gateway says `too_large` | Retry once with only the last 5 messages |
| App closed while waiting for a reply | The user's message is already saved as `sent`. It goes along with the next message the user sends |
| Card tapped while offline | Saved as normal. No AI call is needed |
| Database cannot be opened (key missing) | Treat it as a fresh install: delete the file and show Welcome |

## 8. Delete, My data and backup

Delete means the rows are removed from the database, with no hidden "deleted" flag and no archive.

| "My data" action | What happens in the database |
| --- | --- |
| Chat history: View | List the chats of each habit with `chatsOf`, then the messages with `messagesOf` |
| Chat history: Delete | Run `deleteChat` on every chat. Topic chats disappear and General becomes empty |
| Delete one habit | Its messages, chats, plan, daily log and habit row go, in one transaction |
| Delete everything | Close the database, delete the database file, delete the key from secure storage, go to Welcome |

### Platform backup settings

The phone's own backup system is the one thing Flutter does not handle for us. Each platform needs one small setting, so that the only backup is the one the user turns on.

| Platform | Risk | Fix | When |
| --- | --- | --- | --- |
| Android | Automatic backup copies the database file to the user's Google account | `android:allowBackup="false"` in the manifest | Now, before the tester release |
| iOS | iCloud and computer backups include the database file. The Keychain can also keep the key after the app is removed | Mark the database file as excluded from backup. Save the key with the `first_unlock_this_device` Keychain option | Before the first iOS build |

**Android, in detail:**

`android/app/src/main/AndroidManifest.xml` does not set `android:allowBackup`. Android then treats it as on, and its automatic backup can copy the app's files to the user's Google account. That breaks the "backup is off by default" promise. It can also restore a database file on a new phone without the key that opens it.

Add `android:allowBackup="false"` to the `<application>` tag. Then check on a real Android 12 or newer phone that a phone-to-phone transfer does not carry the database across.

**iOS, in detail:** `flutter_secure_storage` takes the Keychain option through `IOSOptions`. Because the Keychain can outlive the app, a fresh install may find an old key but no database file. That is fine: the app makes a new empty database with it. Check both iOS settings on a real iPhone before release.

### Google Drive backup (later)

The chat tables need no change for backup. The backup file is a copy of all tables, locked with the user's backup password, not with the phone's database key. Restore replaces the whole database, so chat ids stay valid.

## 9. Build order and open questions

Build it in this order, so the app keeps working after each step.

- [ ] Add `chat` and `chat_message`, the two `habit` columns, and the move to schema version 2
- [ ] Open `AppDatabase` once at app start and share it through one Riverpod provider
- [ ] `ProjectsController`: read habits and chats from the database instead of the sample list
- [ ] General chat: save every message and card, and load them when the chat opens
- [ ] Topic chats: the same, and switch them to `recentTextMessages`
- [ ] Failed messages with "Try again"
- [ ] "My data": view and delete for chats, plus "Delete everything"
- [ ] Set the platform backup settings from section 8 (Android now, iOS before its first build)

Tests to add:

- [ ] Close and reopen the app: chats and messages are still there
- [ ] A topic chat with 13 or more messages still gets a reply
- [ ] An old fixed phrase changes language when the app language changes
- [ ] A failed message can be sent again and appears only once
- [ ] Deleting a topic chat removes its messages. Deleting General keeps the chat row
- [ ] "Delete everything" leaves no database file and no key

### Open questions

| # | Question | Recommended |
| --- | --- | --- |
| 1 | The app is closed halfway through the first questions. Resume or start again? | Start again. Clear the General chat and ask from the top. It is under 3 minutes and needs no extra saved state |
| 2 | Start the running summary in the MVP? | No. Add it with topic chats in the Companion phase |
| 3 | The rules engine blocks an AI reply. Today the user sees nothing. | Show a fixed phrase instead, saved as a `fixed` message |
| 4 | Can a user rename a topic chat? | Not in the MVP. The number id makes it easy to add later |
| 5 | Is there a limit on chats per habit? | No limit for now. Decide again if testers make long lists |

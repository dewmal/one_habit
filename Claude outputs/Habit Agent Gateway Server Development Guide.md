# Habit Agent: Gateway Server Development Guide

Nov 15, 2026 · Companion to "Habit Agent Project Spec (Final)" and "Habit Agent Technical Architecture"

This guide is for anyone who builds, changes, tests or deploys the LLM gateway. The gateway is **one simple Go server** in the `gateway_go/` folder. This guide describes the code as it is today, in plain words.

The repo also has an older `gateway/` folder (a Cloudflare Worker). It is not part of this guide. Delete it once the Go server is in use, so there is only one gateway to look after.

## 1. What the gateway is

The gateway is the only server-side part of Habit Agent. It is a safe doorway between the phone and the big AI. It does three things and nothing else:

1. **Holds the AI key**, so the app never contains secrets.
2. **Passes the request** to the AI provider and returns the answer.
3. **Protects itself from abuse** with simple limits.

### What it must never do

These come from the spec and are not open for change:

| Never | Why |
| --- | --- |
| Log in users or keep a user database | There is no Habit Agent account |
| Save prompts, answers, or any chat content | Privacy promise: nothing is kept |
| Log message content | Logs hold only counts and error codes |
| Collect analytics about people | A request must not be linkable to a person |
| See the user's Google account | Google sign-in is only for backup, on the phone |

If a change needs any of these, it is a product decision, not a gateway task.

## 2. Folder layout

```
gateway_go/
├── main.go         All the gateway code
├── main_test.go    7 tests, no network needed
├── Dockerfile      Two-step build, tiny final image
├── go.mod          No outside packages
└── README.md
```

The server uses **only the Go standard library**, so there is nothing to install. It is **one code file on purpose**. Keep it that way while the gateway stays this small.

The folder is **not committed to git yet** (it shows as untracked). Commit it.

## 3. Set up and run on your computer

You need Go 1.22 or newer.

```
cd gateway_go
go test ./...                       # run the tests
MODEL_API_KEY=your-key go run .     # run locally on port 8080
```

Try it:

```
curl http://localhost:8080/health

curl -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -H "X-Device-Id: test-phone" \
  -d '{"instructions":"You are a kind habit coach.","messages":[{"role":"user","content":"Hello"}]}'
```

### Settings

| Name | Meaning |
| --- | --- |
| `MODEL_API_KEY` | The AI provider key. Required. The server refuses to start without it |
| `PORT` | Port to listen on. Default `8080` |

## 4. The API

| Method | Path | Job |
| --- | --- | --- |
| POST | `/chat` | Send a chat to the AI |
| GET | `/health` | Check the gateway is running. Replies `{ "status": "ok" }` |

### Request

```
POST /chat
Content-Type: application/json
X-Device-Id: <random install id>

{
  "provider": "meta",
  "instructions": "You are a kind habit coach...",
  "messages": [
    { "role": "user", "content": "Hello" }
  ]
}
```

| Field | Required | Rules |
| --- | --- | --- |
| `provider` | No | Name of an AI provider. Unknown or missing means the default is used |
| `instructions` | Yes | The coach instructions, as text. Cannot be empty. The gateway puts this first, in the role the provider expects |
| `messages` | Yes | At least 1. Each has `role` and `content` |
| `messages[].role` | Yes | Only `user` or `assistant`. Anything else is rejected |
| `messages[].content` | Yes | Text |

`X-Device-Id` is a random id the app makes on install. It is not tied to a person. It is only used for the rate limit.

### Reply

Success:

```
{ "text": "the AI's reply" }
```

Only the reply text goes back. Nothing else from the provider is passed on.

Error:

```
{ "error": "rate_limited" }
```

| Code | Status | Meaning |
| --- | --- | --- |
| `bad_request` | 400 | Broken JSON, missing fields, or a role that is not allowed |
| `too_large` | 413 | Too many messages or too much text |
| `rate_limited` | 429 | Too many requests from one device this hour |
| `ai_unreachable` | 502 | Could not reach the AI provider |
| `ai_<status>` | 502 | The AI provider answered with an error (see section 11, item 1) |
| `ai_empty` | 502 | The AI provider answered, but with no text |

The provider's own error details are never sent to the phone.

### Limits

| Limit | Value | Name in `main.go` |
| --- | --- | --- |
| Requests per device per hour | 30 | `maxRequestsPerHour` |
| Messages in one request | 12 | `maxMessages` |
| Total text in one request | 8000 characters | `maxChars` |
| Request body size | 64 KB | `maxBodyBytes` |
| Wait for the AI | 60 seconds | `http.Client{Timeout: ...}` |

### What the phone should do with errors

| Gateway says | Phone should |
| --- | --- |
| No answer at all | Show "no connection, try again". Saved tasks and logging keep working |
| `rate_limited` | Show a kind "let's take a short break" message. Do not retry in a loop |
| `too_large` | Send a shorter summary and fewer messages |
| Any `ai_...` | Show "try again in a moment" |
| `bad_request` | This is an app bug. Fix the app |

## 5. How one request flows

```
Phone
  │  POST /chat with X-Device-Id
  ▼
1. Is this device over its limit?   yes → 429 rate_limited
2. (TODO) Is the app-check token real?
3. Is the JSON valid and small?     no → 400 or 413
4. Pick the provider (or the default)
5. Put the instructions first, then the messages
6. Call the AI with the key
7. AI failed?                       yes → 502 ai_...
8. Take only the reply text
  │
  ▼
Phone gets { "text": "..." }
```

Two things to know:

- **The rate limit is counted first**, before the body is checked. So bad requests also count toward the 30.
- **The app cannot send its own instruction message.** Only `user` and `assistant` roles are allowed in `messages`. The instructions travel in their own field. This stops a changed app from slipping in a "system" message.

## 6. Code tour

Everything is in `main.go`. Read it top to bottom in this order:

| Part | Job |
| --- | --- |
| Constants at the top | The limits |
| `Provider` | The four settings for one AI company |
| `Message`, `GatewayRequest` | The shape of what the app sends |
| `Gateway` | Holds the providers and the request counts |
| `NewGateway()` | The only place that knows about AI providers |
| `overLimit(deviceID)` | Counts the request and says if the device passed its limit |
| `checkBody(body)` | Returns an error code, or `""` when the request is fine |
| `writeJSON`, `writeError` | Send a reply. `writeError` also logs the code |
| `handleChat(w, r)` | The `/chat` endpoint. Runs the steps in section 5 |
| `askAI(provider, body)` | Calls the provider. Returns the reply text, or an error code |
| `main()` | Reads the settings, sets up the two routes, starts the server |

### Provider settings

A provider is four values:

| Value | Meaning | Today |
| --- | --- | --- |
| `URL` | Where to send the chat | `https://api.meta.ai/v1/chat/completions` |
| `Key` | The secret | From `MODEL_API_KEY` |
| `Model` | Which model to use | `muse-spark-1.3` |
| `InstructionRole` | Role name for the instructions | `developer` (most others use `system`) |

The gateway expects the provider to answer in the common "chat completions" shape, with the text at `choices[0].message.content`. Confirm the URL, model name and role against the provider's own docs when you get the key, since these are just the values written in the code.

### Rate limit

A simple map kept in memory: device id → count and start time. After one hour the count starts again. A lock (`mu`) keeps it safe when many requests arrive together. It is not saved anywhere, so it resets on restart.

## 7. Tests

Tests use a fake AI, so they need **no network and no key**.

```
cd gateway_go
go test ./...
```

| Test | What it checks |
| --- | --- |
| `TestReturnsOnlyTheReplyText` | The reply holds only `text` |
| `TestSendsKeyAndDeveloperRole` | The key, model and `developer` role are sent to the provider |
| `TestUnknownProviderUsesDefault` | An unknown provider falls back to the default |
| `TestRejectsBadRequests` | Broken JSON, missing fields, empty messages and a `system` message all give 400 |
| `TestRejectsTooLarge` | Too much text gives 413 |
| `TestAIErrorGivesCodeOnly` | An AI error gives 502 with a code only, no provider details |
| `TestRateLimitPerDevice` | 30 per hour per device, other devices not affected, clears after an hour |

Status on Nov 15: all 7 tests pass (Go 1.24).

### Rules for changing the gateway

1. Every change comes with a test.
2. Tests must never call the real AI. Use `newFakeAI` and `testGateway` from `main_test.go`.
3. Tests that depend on time replace `gateway.now`, as the rate-limit test does.

## 8. Common tasks

### Add or switch an AI provider

1. Open `NewGateway` in `main.go`.
2. Copy the `meta` block. Change the URL, key name, model and instruction role.
3. Add the new key as a secret on the host (section 9).
4. To move everyone, change `defaultProvider`.
5. Add a test like `TestSendsKeyAndDeveloperRole` for the new provider.

No app update is needed, because the app does not have to send `provider`.

This only works for providers that use the "chat completions" shape. A provider with a different request or reply shape needs its own small function for building the request and reading the text.

### Change a limit

Change the constant at the top of `main.go`. Update the tables in this guide and the README.

### Add an endpoint

Add one line in `main()` and one handler function:

```go
mux.HandleFunc("POST /something", gateway.handleSomething)
```

Speech-to-text will be the next endpoint, when voice is built. It must follow the same rule: forward, return, keep nothing.

### Add Android app-check

`handleChat` has a `TODO` marking the place: after the rate limit, before reading the body.

1. The app gets an app-check token from Android and sends it in a header.
2. The gateway checks the token with Google.
3. If the token is missing or wrong, reply 401 with a code such as `app_check_failed`.
4. Add tests: good token passes, missing token fails, bad token fails.

Until this is done, the rate limit is weak (section 11, item 2).

## 9. Deploy

```
cd gateway_go
docker build -t habit-agent-gateway .
docker run -p 8080:8080 -e MODEL_API_KEY=your-key habit-agent-gateway
```

Run it on any host that runs containers.

- Set `MODEL_API_KEY` as a secret on the host.
- Put the public URL plus `/chat` into the app's gateway client.
- Point the host's health check at `/health`.
- Run **one copy only** for now. The rate limit lives in memory, so two copies would each count on their own.

The Dockerfile copies only `go.mod` and `main.go`. If you ever split the code into more files, update the `COPY` line.

### Secrets

- The key lives only in the host's secret store.
- Never put it in code, in the Dockerfile, or in git.
- Never put it in the app.

### Release checklist

- [ ] Tests pass
- [ ] `MODEL_API_KEY` is set as a secret
- [ ] Spending cap is set in the AI provider's dashboard
- [ ] `/health` replies `ok`
- [ ] One real request from a phone works
- [ ] Logs show only `gateway_ok` and `gateway_error <code>` lines, no message text
- [ ] The app points at the right URL, ending in `/chat`

## 10. Logging and privacy rules for developers

The gateway writes only these log lines:

```
gateway listening on port 8080
gateway_ok
gateway_error <code>
```

| Do | Do not |
| --- | --- |
| Log a fixed word and an error code | Log `instructions`, `messages`, or the AI reply |
| Count requests | Log the request body "just for debugging" |
| Keep the device id only in memory, for the rate limit | Write device ids to logs or storage |
| Turn provider errors into a short code | Pass the provider's error text to the phone or logs |

Also check the host: turn off any request-body logging on the platform itself. Before each release, open the logs and confirm no message content is there. This is one of the six release checks in the spec.

## 11. Known gaps

Found while reading the code for this guide. Items 1 to 3 are worth fixing before the tester release.

| # | Issue | Suggested fix |
| --- | --- | --- |
| 1 | **AI error codes use words, not numbers.** The server returns `ai_Internal Server Error`. The README says `ai_<status>`, such as `ai_500` | Use the number (see below) and update the test |
| 2 | **The rate limit trusts `X-Device-Id`.** Anyone can send a new id on every request and skip the limit | Finish app-check. Keep the provider spending cap as the real safety net until then |
| 3 | **The fallback device id is weak.** Without the header, the server uses the caller's address with its port, so each new connection looks like a new device. Behind a proxy it is the proxy's address | Reject requests with no `X-Device-Id`, or read the host's real-client-IP header |
| 4 | A body over 64 KB returns 400 `bad_request`, not 413 `too_large` | Fine for now. Note it or map it to 413 |
| 5 | A wrong method on `/chat` returns a plain-text 405, not a JSON error | Fine for now. The app only sends POST |
| 6 | The usage map never removes old devices | Fine for 10 testers. Clean out old entries before a wider release |
| 7 | The phone-side client (`GatewayLlmClient`) named in the README is not in `lib/` yet | Build it on Tue Nov 17 with the chat screen |

Fix for item 1, in `askAI` in `main.go`:

```go
// Before
return "", "ai_" + http.StatusText(response.StatusCode)

// After (add "strconv" to the imports)
return "", "ai_" + strconv.Itoa(response.StatusCode)
```

Then change `TestAIErrorGivesCodeOnly` to expect `ai_500`.

## 12. To do before a wider release

| When | Task |
| --- | --- |
| MVP (Tue Nov 17) | Commit `gateway_go/` and delete the old `gateway/` folder |
| MVP (Tue Nov 17) | Android app-check |
| MVP (Tue Nov 17) | Spending cap on the AI account |
| MVP (Tue Nov 17) | Phone-side gateway client and "no connection, try again" message |
| MVP (Fri Nov 27) | Check the logs: counts and error codes only |
| Before opening beyond 10 testers | Rate limit in a stored counter, shared between copies |
| Before opening beyond 10 testers | Clean old entries from the usage map |
| Companion phase | Speech-to-text endpoint, same "keep nothing" rule |
| Optional, later | "Bring your own key" mode (the app calls the AI directly, no gateway change) |

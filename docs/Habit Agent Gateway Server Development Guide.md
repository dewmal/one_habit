# Habit Agent: Gateway Server Development Guide

Nov 15, 2026 · Companion to "Habit Agent Project Spec (Final)" and "Habit Agent Technical Architecture"

This guide is for anyone who builds, changes, tests or deploys the LLM gateway. It describes the code as it is in the repo today (`gateway/` and `gateway_go/`), in plain words.

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

## 2. Two versions in the repo

There are two gateways that do the same job. The app should point at **one** of them.

| | `gateway/` | `gateway_go/` |
| --- | --- | --- |
| Language | JavaScript | Go (standard library only) |
| Runs on | Cloudflare Workers | Any host that runs containers |
| Main file | `src/worker.js` | `main.go` |
| Tests | `test/worker.test.js` | `main_test.go` |
| Chat endpoint | `POST /` (any path) | `POST /chat` |
| Health check | None | `GET /health` |
| Deploy | `wrangler deploy` | Docker image |

Both folders are **not committed to git yet** (they show as untracked). Commit the one you choose, or both.

They are almost the same, but not exactly. The differences are listed in section 12. Read that section before switching the app from one to the other.

## 3. Folder layout

```
gateway/                    Cloudflare Worker version
├── src/worker.js           All the gateway code
├── test/worker.test.js     9 tests, no network needed
├── wrangler.toml           Worker name and entry file
├── package.json            Scripts: test, dev, deploy
└── README.md

gateway_go/                 Go version
├── main.go                 All the gateway code
├── main_test.go            7 tests, no network needed
├── Dockerfile              Two-step build, tiny final image
├── go.mod                  No outside packages
└── README.md
```

Each version is **one code file on purpose**. Keep it that way while the gateway stays this small.

## 4. Set up and run on your computer

### Worker version

You need Node.js (tests pass on Node 22).

```
cd gateway
npm test                    # run the tests
npm install -g wrangler     # once
wrangler dev                # run locally
```

For local runs, put the key in a file named `gateway/.dev.vars` (never commit it):

```
MODEL_API_KEY=your-key
```

### Go version

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

| Name | Used by | Meaning |
| --- | --- | --- |
| `MODEL_API_KEY` | Both | The AI provider key. Required. The Go version refuses to start without it |
| `PORT` | Go only | Port to listen on. Default `8080` |

## 5. The API

### Request

```
POST /chat          (Go)      or      POST /      (Worker)
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
| `instructions` | Yes | The coach instructions, as text. The gateway puts this first, in the role the provider expects |
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
| `ai_<status>` | 502 | The AI provider answered with an error (see section 12, item 1) |
| `ai_empty` | 502 | The AI provider answered, but with no text |

The provider's own error details are never sent to the phone.

### Limits

| Limit | Value | Name in code (JS / Go) |
| --- | --- | --- |
| Requests per device per hour | 30 | `MAX_REQUESTS_PER_HOUR` / `maxRequestsPerHour` |
| Messages in one request | 12 | `MAX_MESSAGES` / `maxMessages` |
| Total text in one request | 8000 characters | `MAX_CHARS` / `maxChars` |
| Request body size | 64 KB (Go only) | `maxBodyBytes` |
| Wait for the AI | 60 seconds (Go only) | `http.Client{Timeout: ...}` |

### What the phone should do with errors

| Gateway says | Phone should |
| --- | --- |
| No answer at all | Show "no connection, try again". Saved tasks and logging keep working |
| `rate_limited` | Show a kind "let's take a short break" message. Do not retry in a loop |
| `too_large` | Send a shorter summary and fewer messages |
| Any `ai_...` | Show "try again in a moment" |
| `bad_request` | This is an app bug. Fix the app |

## 6. How one request flows

```
Phone
  │  POST with X-Device-Id
  ▼
1. Is it a POST?                    no → error
2. Is this device over its limit?   yes → 429 rate_limited
3. (TODO) Is the app-check token real?
4. Is the JSON valid and small?     no → 400 or 413
5. Pick the provider (or the default)
6. Put the instructions first, then the messages
7. Call the AI with the key
8. AI failed?                       yes → 502 ai_...
9. Take only the reply text
  │
  ▼
Phone gets { "text": "..." }
```

Two things to know:

- **The rate limit is counted first**, before the body is checked. So bad requests also count toward the 30.
- **The app cannot send its own instruction message.** Only `user` and `assistant` roles are allowed in `messages`. The instructions travel in their own field. This stops a changed app from slipping in a "system" message.

## 7. Code tour

The two versions use the same names for the same jobs.

| Job | Worker (`worker.js`) | Go (`main.go`) |
| --- | --- | --- |
| List of AI providers | `getProviders(env)` | `NewGateway()` |
| Count requests per device | `overLimit(deviceId, now)` | `overLimit(deviceID)` |
| Check the request body | `checkBody(body)` | `checkBody(body)` |
| Send an error | `errorReply(code, status)` | `writeError(w, status, code)` |
| Handle a chat | `handleRequest(request, env, now)` | `handleChat(w, r)` |
| Call the AI | inside `handleRequest` | `askAI(provider, body)` |

### Provider settings

A provider is four values:

| Value | Meaning | Today |
| --- | --- | --- |
| URL | Where to send the chat | `https://api.meta.ai/v1/chat/completions` |
| Key | The secret | From `MODEL_API_KEY` |
| Model | Which model to use | `muse-spark-1.3` |
| Instruction role | Role name for the instructions | `developer` (most others use `system`) |

The gateway expects the provider to answer in the common "chat completions" shape, with the text at `choices[0].message.content`. Confirm the URL, model name and role against the provider's own docs when you get the key, since these are just the values written in the code.

### Rate limit

A simple map kept in memory: device id → count and start time. After one hour the count starts again. It is not saved anywhere, so it resets on restart.

## 8. Tests

Tests use a fake AI, so they need **no network and no key**.

```
cd gateway     && npm test
cd gateway_go  && go test ./...
```

| What is tested | Worker | Go |
| --- | --- | --- |
| Reply holds only the text | Yes | Yes |
| Key and `developer` role are sent to the provider | Yes | Yes |
| Unknown provider falls back to the default | Yes | Yes |
| GET is rejected | Yes | No |
| Broken JSON and missing fields give 400 | Yes | Yes |
| App cannot send a `system` message | Yes | Yes |
| Too much text gives 413 | Yes | Yes |
| AI error gives 502 with a code only | Yes | Yes |
| 30 per hour per device, other devices not affected, clears after an hour | Yes | Yes |

Status on Nov 15: all 9 Worker tests pass (Node 22) and all 7 Go tests pass (Go 1.24).

### Rules for changing the gateway

1. Every change comes with a test.
2. Tests must never call the real AI.
3. If you change one version, make the same change in the other, or delete the one you do not use.

## 9. Common tasks

### Add or switch an AI provider

1. Open `getProviders` (Worker) or `NewGateway` (Go).
2. Copy the `meta` block. Change the URL, key name, model and instruction role.
3. Add the new key as a secret (section 10).
4. To move everyone, change `DEFAULT_PROVIDER` / `defaultProvider`.
5. Add a test like "sends the key and the right role".

No app update is needed, because the app does not have to send `provider`.

This only works for providers that use the "chat completions" shape. A provider with a different request or reply shape needs its own small function for building the request and reading the text.

### Change a limit

Change the constant at the top of the file. Update the test that uses it and the tables in this guide and the README.

### Add an endpoint (Go)

Add one line in `main()` and one handler function:

```go
mux.HandleFunc("POST /something", gateway.handleSomething)
```

Speech-to-text will be the next endpoint, when voice is built. It must follow the same rule: forward, return, keep nothing.

### Add Android app-check

Both files have a `TODO` marking the place: after the rate limit, before reading the body.

1. The app gets an app-check token from Android and sends it in a header.
2. The gateway checks the token with Google.
3. If the token is missing or wrong, reply 401 with a code such as `app_check_failed`.
4. Add tests: good token passes, missing token fails, bad token fails.

Until this is done, the rate limit is weak (section 12, item 3).

## 10. Deploy

### Worker version

```
cd gateway
wrangler login
wrangler secret put MODEL_API_KEY
wrangler deploy
```

Put the URL it prints into the app's gateway client.

### Go version

```
cd gateway_go
docker build -t habit-agent-gateway .
docker run -p 8080:8080 -e MODEL_API_KEY=your-key habit-agent-gateway
```

Run it on any container host. Set `MODEL_API_KEY` as a secret on the host. Put the public URL plus `/chat` into the app's gateway client. Point the host's health check at `/health`.

Run **one copy only** for now. The rate limit lives in memory, so two copies would each count on their own.

### Secrets

- The key lives only in the host's secret store.
- Never put it in code, in `wrangler.toml`, in the Dockerfile, or in git.
- Never put it in the app.

### Release checklist

- [ ] Tests pass
- [ ] `MODEL_API_KEY` is set as a secret
- [ ] Spending cap is set in the AI provider's dashboard
- [ ] One real request from a phone works
- [ ] Logs show only `gateway_ok` and `gateway_error <code>` lines, no message text
- [ ] The app points at the right URL (and `/chat` for Go)

## 11. Logging and privacy rules for developers

The gateway writes only two kinds of log lines:

```
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

## 12. Known gaps and differences

Found while reading the code for this guide. Items 1 to 3 are worth fixing before the tester release.

| # | Issue | Where | Suggested fix |
| --- | --- | --- | --- |
| 1 | **AI error codes do not match.** Worker returns `ai_500`. Go returns `ai_Internal Server Error`. The Go README says `ai_<status>` | Go | Use the number (see below) and update the Go test |
| 2 | **Paths differ.** Worker accepts POST on any path. Go needs `/chat` | Both | Pick one. Easiest: keep `/chat` in the app URL and it works with both |
| 3 | **The rate limit trusts `X-Device-Id`.** Anyone can send a new id on every request and skip the limit | Both | Finish app-check. Keep the provider spending cap as the real safety net until then |
| 4 | **Fallback device id is weak in Go.** Without the header it uses the caller's address with its port, so each new connection looks like a new device. Behind a proxy it is the proxy's address | Go | Reject requests with no `X-Device-Id`, or read the host's real-client-IP header |
| 5 | Empty `instructions` (`""`) is accepted by the Worker and rejected by Go | Worker | Reject empty text in `checkBody` |
| 6 | A body over 64 KB returns 400 `bad_request`, not 413 `too_large` | Go | Fine for now. Note it or map it to 413 |
| 7 | A wrong method returns a JSON 404 in the Worker, and a plain-text 405 in Go | Both | Fine for now. The app only sends POST |
| 8 | If the AI returns 200 with a body that is not JSON, the Worker throws instead of returning `ai_empty` | Worker | Wrap `aiResponse.json()` in try/catch |
| 9 | The usage map never removes old devices | Both | Fine for 10 testers. Clean out old entries before a wider release |
| 10 | The Worker's in-memory count is not shared between Cloudflare's copies, so the real limit can be higher than 30 | Worker | Move to a stored counter before a wider release |
| 11 | The phone-side client (`GatewayLlmClient`) named in the READMEs is not in `lib/` yet | App | Build it on Tue Nov 17 with the chat screen |

Fix for item 1, in `askAI` in `main.go`:

```go
// Before
return "", "ai_" + http.StatusText(response.StatusCode)

// After (add "strconv" to the imports)
return "", "ai_" + strconv.Itoa(response.StatusCode)
```

Then change the test `TestAIErrorGivesCodeOnly` to expect `ai_500`.

## 13. To do before a wider release

| When | Task |
| --- | --- |
| MVP (Tue Nov 17) | Choose one gateway version and commit it |
| MVP (Tue Nov 17) | Android app-check |
| MVP (Tue Nov 17) | Spending cap on the AI account |
| MVP (Tue Nov 17) | Phone-side gateway client and "no connection, try again" message |
| MVP (Fri Nov 27) | Check the logs: counts and error codes only |
| Before opening beyond 10 testers | Rate limit in a stored counter, shared between copies |
| Before opening beyond 10 testers | Clean old entries from the usage map |
| Companion phase | Speech-to-text endpoint, same "keep nothing" rule |
| Optional, later | "Bring your own key" mode (the app calls the AI directly, no gateway change) |

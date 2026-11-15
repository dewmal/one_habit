# Habit Agent Gateway (Go)

Forwards chat requests to the AI provider and returns only the reply text. Keeps nothing.
Full guide: `../docs/Habit Agent Gateway Server Development Guide.md`.

## Run

```
go test ./...                       # tests (no network, no key needed)
MODEL_API_KEY=your-key go run .     # run on port 8080
```

Settings: `MODEL_API_KEY` (required), `PORT` (default `8080`).

## Endpoints

- `POST /chat` with header `X-Device-Id` and a JSON body (see the guide, section 5)
- `GET /health`

## Docker

```
docker build -t habit-agent-gateway .
docker run -p 8080:8080 -e MODEL_API_KEY=your-key habit-agent-gateway
```

Run one copy only: the rate limit is in memory.

## Deploy on Railway

`railway.json` already sets the Dockerfile build, the `/health` check and one replica.

1. Install the CLI and log in: `brew install railway && railway login`
2. From this folder: `railway init` (new project), then `railway up`
3. Set the key: `railway variables --set MODEL_API_KEY=your-key`
4. Make a public URL: `railway domain`
5. Check it: `curl https://<your-domain>/health`

Railway sets `PORT` itself. If you deploy from GitHub instead of the CLI, set the
service's **Root Directory** to `server`.

Then point the app at it: `GATEWAY_URL=https://<your-domain>/chat` in `.env`.

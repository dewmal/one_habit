// Habit Agent gateway (Go version).
//
// Forwards a chat request to an AI provider and returns only the reply text.
// It keeps nothing: no prompts, no answers, no user data. Logs hold only
// fixed words and error codes. See docs/Habit Agent Gateway Server Development Guide.md.
package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"
	"unicode/utf8"
)

const (
	maxRequestsPerHour  = 30
	maxMessages         = 12
	maxChars            = 8000
	maxBodyBytes        = 64 << 10
	aiTimeout           = 60 * time.Second
	maxAIResponseBytes  = 1 << 20
	defaultProviderName = "meta"
	deviceHeader        = "X-Device-Id"
)

// provider holds the four values needed to call one AI provider.
type provider struct {
	URL             string
	Key             string
	Model           string
	InstructionRole string
}

type message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type chatRequest struct {
	Provider     string    `json:"provider"`
	Instructions string    `json:"instructions"`
	Messages     []message `json:"messages"`
}

type usage struct {
	count int
	start time.Time
}

// Gateway holds the provider list and the in-memory rate limit.
type Gateway struct {
	providers       map[string]provider
	defaultProvider string
	client          *http.Client
	now             func() time.Time

	mu     sync.Mutex
	usages map[string]usage
}

// NewGateway builds the gateway with the provider list used in production.
func NewGateway(apiKey string) *Gateway {
	return &Gateway{
		providers: map[string]provider{
			"meta": {
				URL:             "https://api.meta.ai/v1/chat/completions",
				Key:             apiKey,
				Model:           "muse-spark-1.3",
				InstructionRole: "developer",
			},
		},
		defaultProvider: defaultProviderName,
		client:          &http.Client{Timeout: aiTimeout},
		now:             time.Now,
		usages:          make(map[string]usage),
	}
}

// overLimit counts one request for the device. It returns true when the
// device has already used its hourly allowance.
func (g *Gateway) overLimit(deviceID string, now time.Time) bool {
	g.mu.Lock()
	defer g.mu.Unlock()

	entry, ok := g.usages[deviceID]
	if !ok || now.Sub(entry.start) >= time.Hour {
		g.usages[deviceID] = usage{count: 1, start: now}
		return false
	}
	if entry.count >= maxRequestsPerHour {
		return true
	}
	entry.count++
	g.usages[deviceID] = entry
	return false
}

// checkBody returns an HTTP status and error code if the request is not
// allowed. It returns (0, "") when the request is fine.
func checkBody(req chatRequest) (int, string) {
	if strings.TrimSpace(req.Instructions) == "" {
		return http.StatusBadRequest, "bad_request"
	}
	if len(req.Messages) == 0 {
		return http.StatusBadRequest, "bad_request"
	}
	if len(req.Messages) > maxMessages {
		return http.StatusRequestEntityTooLarge, "too_large"
	}

	chars := utf8.RuneCountInString(req.Instructions)
	for _, m := range req.Messages {
		if m.Role != "user" && m.Role != "assistant" {
			return http.StatusBadRequest, "bad_request"
		}
		chars += utf8.RuneCountInString(m.Content)
	}
	if chars > maxChars {
		return http.StatusRequestEntityTooLarge, "too_large"
	}
	return 0, ""
}

// pickProvider returns the named provider, or the default if the name is
// missing or unknown.
func (g *Gateway) pickProvider(name string) provider {
	if p, ok := g.providers[name]; ok {
		return p
	}
	return g.providers[g.defaultProvider]
}

// askAI calls the provider. It returns the reply text, or an error code
// with no provider details.
func (g *Gateway) askAI(p provider, req chatRequest) (string, string) {
	msgs := make([]message, 0, len(req.Messages)+1)
	msgs = append(msgs, message{Role: p.InstructionRole, Content: req.Instructions})
	msgs = append(msgs, req.Messages...)

	payload, err := json.Marshal(map[string]any{"model": p.Model, "messages": msgs})
	if err != nil {
		return "", "ai_empty"
	}

	httpReq, err := http.NewRequest(http.MethodPost, p.URL, bytes.NewReader(payload))
	if err != nil {
		return "", "ai_unreachable"
	}
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+p.Key)

	resp, err := g.client.Do(httpReq)
	if err != nil {
		return "", "ai_unreachable"
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, maxAIResponseBytes))
		return "", "ai_" + strconv.Itoa(resp.StatusCode)
	}

	var out struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}
	if err := json.NewDecoder(io.LimitReader(resp.Body, maxAIResponseBytes)).Decode(&out); err != nil {
		return "", "ai_empty"
	}
	if len(out.Choices) == 0 {
		return "", "ai_empty"
	}
	text := strings.TrimSpace(out.Choices[0].Message.Content)
	if text == "" {
		return "", "ai_empty"
	}
	return text, ""
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

// writeError sends a code only and logs the code only.
func writeError(w http.ResponseWriter, status int, code string) {
	log.Printf("gateway_error %s", code)
	writeJSON(w, status, map[string]string{"error": code})
}

func (g *Gateway) handleHealth(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (g *Gateway) handleChat(w http.ResponseWriter, r *http.Request) {
	deviceID := strings.TrimSpace(r.Header.Get(deviceHeader))
	if deviceID == "" {
		writeError(w, http.StatusBadRequest, "bad_request")
		return
	}

	// The rate limit is counted before the body is read, so bad requests count too.
	if g.overLimit(deviceID, g.now()) {
		writeError(w, http.StatusTooManyRequests, "rate_limited")
		return
	}

	r.Body = http.MaxBytesReader(w, r.Body, maxBodyBytes)
	raw, err := io.ReadAll(r.Body)
	if err != nil {
		var tooBig *http.MaxBytesError
		if errors.As(err, &tooBig) {
			writeError(w, http.StatusRequestEntityTooLarge, "too_large")
			return
		}
		writeError(w, http.StatusBadRequest, "bad_request")
		return
	}

	var req chatRequest
	if err := json.Unmarshal(raw, &req); err != nil {
		writeError(w, http.StatusBadRequest, "bad_request")
		return
	}
	if status, code := checkBody(req); code != "" {
		writeError(w, status, code)
		return
	}

	p := g.pickProvider(req.Provider)
	text, code := g.askAI(p, req)
	if code != "" {
		writeError(w, http.StatusBadGateway, code)
		return
	}

	log.Print("gateway_ok")
	writeJSON(w, http.StatusOK, map[string]string{"text": text})
}

func main() {
	apiKey := os.Getenv("MODEL_API_KEY")
	if apiKey == "" {
		log.Fatal("MODEL_API_KEY is not set")
	}
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	g := NewGateway(apiKey)
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", g.handleHealth)
	mux.HandleFunc("POST /chat", g.handleChat)

	srv := &http.Server{
		Addr:              ":" + port,
		Handler:           mux,
		ReadHeaderTimeout: 10 * time.Second,
	}
	log.Printf("gateway listening on :%s", port)
	log.Fatal(srv.ListenAndServe())
}

# Installation & setup guide

This guide walks you through adding **neuron_ai_chatbot** (Neuron_AI_Chatbot) to a Rails application from scratch: dependencies, catalog, initializer, routes, environment, Ollama, verification, and production hardening.

For **architecture, component diagrams, and deep operations** (same gem), see **[NEURON_AI_CHATBOT.md](./NEURON_AI_CHATBOT.md)**.

---

## Table of contents

1. [What you get](#what-you-get)
2. [Prerequisites](#prerequisites)
3. [Step 1 — Add the gem](#step-1--add-the-gem)
4. [Step 2 — Bundle](#step-2--bundle)
5. [Step 3 — Define the API catalog](#step-3--define-the-api-catalog)
6. [Step 4 — Configure `NeuronAiChatbot`](#step-4--configure-neuronaichatbot)
7. [Step 5 — Mount the engine](#step-5--mount-the-engine)
8. [Step 6 — Environment variables](#step-6--environment-variables)
9. [Step 7 — Ollama](#step-7--ollama)
10. [Step 8 — Start Rails and smoke-test](#step-8--start-rails-and-smoke-test)
11. [Step 9 — Authentication & production](#step-9--authentication--production)
12. [Reference: `NeuronAiChatbot.setup` options](#reference-neuronaichatbotsetup-options)
13. [Reference: API catalog rows](#reference-api-catalog-rows)
14. [Reference: HTTP endpoints](#reference-http-endpoints)
15. [Troubleshooting](#troubleshooting)

---

## What you get

- **`GET /chat`** — Bundled HTML/CSS/JS chat UI.
- **`POST /chat`** — JSON for the UI: `{ "message": "..." }` (includes CSRF from the page).
- **`POST /api/v1/chat`** — JSON API for scripts and integrations (`ActionController::API`, no CSRF).

Flow: user message → **Ollama** returns one JSON “intent” (path, method, params, operation) → your **JSON API** is called → response is normalized for the client.

---

## Prerequisites

- **Rails** ≥ 6.1, **Ruby** ≥ 2.7.
- **Ollama** reachable from the Rails host (same machine or LAN URL).
- A **JSON API** (typically versioned under something like `/api/v1`) the chatbot is allowed to call.
- **HTTP Basic** (or compatible) credentials the executor can use, unless you only use in-process integration in development.

---

## Step 1 — Add the gem

**From RubyGems** (after publish):

```ruby
gem "neuron_ai_chatbot", "~> 0.1"
```

**From GitHub** (pre-publish or bleeding edge):

```ruby
gem "neuron_ai_chatbot", github: "YOUR_ORG/neuron_ai_chatbot", branch: "main"
```

**From a local path** (monorepo or checkout):

```ruby
gem "neuron_ai_chatbot", path: "public_gem/neuron_ai_chatbot"
```

---

## Step 2 — Bundle

```bash
bundle install
```

---

## Step 3 — Define the API catalog

The LLM only sees endpoints you whitelist. Define a **frozen array of hashes** (symbol keys), typically in an initializer that loads **before** `neuron_ai_chatbot.rb` (e.g. `config/initializers/api_catalog.rb`) or in the same file as `setup`.

Minimal example:

```ruby
# config/initializers/api_catalog.rb
# frozen_string_literal: true

API_CATALOG = [
  {
    name:        "list_items",
    description: "List items the current user can see.",
    endpoint:    "/items",
    method:      "GET",
    params:      %w(page per_page status)
  },
  {
    name:        "get_item",
    description: "Fetch one item by id.",
    endpoint:    "/items/{id}",
    method:      "GET",
    required:    %w(id)
  }
].freeze
```

Use **`{id}`** in `endpoint` when the path includes a numeric id; the executor substitutes the `id` param.

See [Reference: API catalog rows](#reference-api-catalog-rows) for all supported keys.

---

## Step 4 — Configure `NeuronAiChatbot`

Create **`config/initializers/neuron_ai_chatbot.rb`** (or any name **after** your catalog file alphabetically if you rely on load order).

```ruby
# frozen_string_literal: true

Rails.application.config.to_prepare do
  NeuronAiChatbot.setup do |config|
    config.api_knowledge = API_CATALOG

    # Optional — see "Reference: NeuronAiChatbot.setup options"
    # config.additional_prompt_rules = <<~RULES
    #   - ...
    # RULES
    # config.normalize_country = ->(value) { ISO3166::Country[value]&.alpha2 }
    # config.param_transform = ->(params) { params }
    # config.ollama_url = ENV.fetch("OLLAMA_URL", "http://localhost:11434/api/generate")
    # config.ollama_model = ENV.fetch("OLLAMA_MODEL", "mistral")
    # config.api_executor_base_url = ENV.fetch("API_EXECUTOR_BASE_URL", "http://localhost:3000/api/v1")
    # config.api_email = ENV["API_EMAIL"]
    # config.api_password = ENV["API_PASSWORD"]
    # config.api_executor_http_timeout = 360
    # config.max_endpoints_in_prompt = 5
    # config.integration_rails_app = Rails.application
  end
end
```

**Why `to_prepare`?** In development, code reloads re-run `to_prepare`, so `api_knowledge` and other settings stay in sync without restarting the server.

**Dotenv:** `ollama_url`, `ollama_model`, `api_executor_base_url`, timeouts, and API credentials read from **`ENV` on each access** until you assign them in `setup`. That avoids capturing defaults before `.env` is loaded.

---

## Step 5 — Mount the engine

In **`config/routes.rb`**, inside the scope where these routes should live (e.g. your main `constraints` or root application):

```ruby
mount NeuronAiChatbot::Engine, at: "/"
```

**Remove** any older routes that duplicate **`/chat`** or **`POST /api/v1/chat`** so only the engine owns them.

**Mount prefix:** `mount NeuronAiChatbot::Engine, at: "/bot"` → URLs become `/bot/chat` and `/bot/api/v1/chat`. The bundled UI uses Rails URL helpers (`chat_path`), which respect the mount path. External clients must use the prefixed URLs.

---

## Step 6 — Environment variables

| Variable | Required? | Purpose |
|----------|-----------|---------|
| `OLLAMA_URL` | Optional | Ollama generate URL. Default: `http://localhost:11434/api/generate`. |
| `OLLAMA_MODEL` | Optional | Model tag in Ollama. Default: `mistral`. |
| `API_EXECUTOR_BASE_URL` | Recommended | Base URL including API prefix, e.g. `http://localhost:3000/api/v1`. No trailing slash. |
| `API_EMAIL` | For real API calls | Basic auth username for outbound requests. |
| `API_PASSWORD` | For real API calls | Basic auth password. |
| `API_EXECUTOR_HTTP_TIMEOUT` | Optional | HTTParty timeout in seconds (default `360`). |

You can set the same values in **`NeuronAiChatbot.setup`** instead of ENV; explicit `config.*` assignments take precedence over ENV for those attributes.

**Development / localhost:** When `Rails.env.development?` **and** `api_executor_base_url` contains **`localhost`**, the executor uses **`ActionDispatch::Integration::Session`** against `Rails.application` (or `integration_rails_app`) instead of HTTParty, avoiding self-HTTP deadlocks.

---

## Step 7 — Ollama

On the machine running Ollama:

```bash
ollama serve
```

Pull the model matching `OLLAMA_MODEL` (default `mistral`):

```bash
ollama pull mistral
```

Optional check:

```bash
curl -sS http://localhost:11434/api/tags | head
```

Point `OLLAMA_URL` at another host if Ollama runs elsewhere (e.g. `http://192.168.1.10:11434/api/generate`).

---

## Step 8 — Start Rails and smoke-test

```bash
bin/rails server
```

**Web UI:** open `/chat` on your app (e.g. `http://localhost:3000/chat`).

**API** (replace credentials and host):

```bash
curl -sS -u 'API_EMAIL:API_PASSWORD' \
  -H 'Content-Type: application/json' \
  -d '{"message":"User: list items"}' \
  http://localhost:3000/api/v1/chat
```

A successful reply typically includes `success`, `message`, `data`, and `debug` (the resolved intent). On failure, inspect `message`, `data`, and Rails logs.

---

## Step 9 — Authentication & production

- The engine **does not** register Devise or other auth. Protect **`/chat`** and **`/api/v1/chat`** the same way you protect the rest of the app (before_action, route constraints, reverse proxy, VPN, etc.).
- Store **`API_EMAIL` / `API_PASSWORD`** in a secret manager in production.
- Use TLS in front of Rails and, if applicable, for Ollama on trusted networks only.

---

## Reference: `NeuronAiChatbot.setup` options

| Option | Purpose |
|--------|---------|
| **`api_knowledge`** | **Required.** Array of catalog hashes (see below). |
| **`additional_prompt_rules`** | String appended to the Ollama “Rules” section (domain hints). |
| **`normalize_country`** | `lambda { |value| ... }` — rewrite `params["country"]` before validation and HTTP. |
| **`param_transform`** | `lambda { |params| ... }` — mutate string-keyed params hash before validation and HTTP. |
| **`ollama_url`** | Override Ollama URL (else `ENV["OLLAMA_URL"]` with default). |
| **`ollama_model`** | Override model name (else `ENV["OLLAMA_MODEL"]` with default). |
| **`api_executor_base_url`** | Override API base (else `ENV["API_EXECUTOR_BASE_URL"]` with default). |
| **`api_executor_http_timeout`** | HTTParty timeout seconds. |
| **`api_email` / `api_password`** | Basic auth for outbound API calls (else `ENV`). |
| **`max_endpoints_in_prompt`** | Max catalog rows ranked into the prompt (default `5`). |
| **`integration_rails_app`** | Rails app used for in-process integration session (default `Rails.application`). |

---

## Reference: API catalog rows

Each element of `api_knowledge` is a **Hash** with symbol keys:

| Key | Purpose |
|-----|---------|
| `:name` | Short identifier; used when scoring rows for the prompt. |
| `:endpoint` | Path relative to `api_executor_base_url` (e.g. `"/items"`, `"/items/{id}"`). |
| `:method` | `GET`, `POST`, `PUT`, `PATCH`, or `DELETE`. |
| `:description` | Free text shown to the model — quality drives routing. |
| `:required` | Array of parameter names that must be present (validated before HTTP). |
| `:params` | For GET-style lists: allowed query keys (hints for the model). |
| `:optional` | For POST/PUT bodies: optional field names (hints). |

---

## Reference: HTTP endpoints

| Method | Path | Controller | Notes |
|--------|------|--------------|--------|
| GET | `/chat` | `NeuronAiChatbot::ChatController#index` | Renders bundled UI. |
| POST | `/chat` | `NeuronAiChatbot::ChatController#create` | JSON `message`; CSRF token from meta tag. |
| POST | `/api/v1/chat` | `NeuronAiChatbot::Api::V1::ChatController#create` | JSON `message`; for API clients. |

Paths are relative to the **mount** path of the engine.

---

## Troubleshooting

| Symptom | What to check |
|---------|----------------|
| Ollama connection / parse errors | `ollama serve`, `ollama pull $OLLAMA_MODEL`, `OLLAMA_URL`, firewalls. |
| `localhost` Ollama URL despite `.env` | Use `to_prepare` + lazy ENV (built into this gem); restart server after `.env` changes. |
| `401` / `403` from your API | Credentials, user roles, same auth as other API clients. |
| `Missing required parameters` | Catalog `:required` vs model output; improve descriptions and `additional_prompt_rules`. |
| Wrong endpoint | Richer `:description`, clearer `:name`, optional rules; adjust `max_endpoints_in_prompt`. |
| “Next page” ignored | Client must send **full transcript** with `User:` / `AI:` lines so the last line can contain “next”, “page”, or “more”. |

---

## Related files in this gem

| Path | Role |
|------|------|
| `lib/neuron_ai_chatbot.rb` | Configuration module and lazy ENV readers. |
| `lib/neuron_ai_chatbot/engine.rb` | Rails::Engine definition. |
| `config/routes.rb` | Engine routes. |
| `app/services/neuron_ai_chatbot/local_ai_service.rb` | Ollama + catalog + prompt. |
| `app/services/neuron_ai_chatbot/api_executor.rb` | HTTP / integration session. |
| `app/services/neuron_ai_chatbot/api_intent_validator.rb` | Required-parameter checks. |
| `app/services/neuron_ai_chatbot/response_processor.rb` | Response shaping. |

For releasing your own fork to RubyGems, see **`RELEASING.md`** in the gem root.

# neuron_ai_chatbot (Neuron_AI_Chatbot)

Mountable **Rails::Engine** that turns natural language into **one JSON HTTP call** against *your* API, using **Ollama** as a structured router.

| If you want… | Go to… |
|--------------|--------|
| **Full reference** (setup steps + architecture + operations + troubleshooting) | **[docs/NEURON_AI_CHATBOT.md](docs/NEURON_AI_CHATBOT.md)** |
| **Installation-only** walkthrough (env, Ollama, routes, `setup` reference) | **[docs/INSTALLATION.md](docs/INSTALLATION.md)** |
| One-screen checklist | [docs/SETUP.md](docs/SETUP.md) |
| Cutting a RubyGems release | [RELEASING.md](RELEASING.md) |

---

## At a glance

- **Web UI:** `GET /chat`, `POST /chat` (JSON `message`, CSRF on the page).
- **API:** `POST /api/v1/chat` (JSON `message`, `ActionController::API`).
- **Ruby module:** `NeuronAiChatbot` · **Product name:** Neuron_AI_Chatbot.

## Requirements

- Rails **≥ 6.1**, Ruby **≥ 2.7**
- Running **Ollama** + a pulled model (default `mistral`)
- A **JSON API** the chatbot may call (usually HTTP Basic)

## Add to your Gemfile

```ruby
gem "neuron_ai_chatbot"
```

```bash
bundle install
```

**Git or path** (development):

```ruby
gem "neuron_ai_chatbot", github: "neuron-ai-chatbot/neuron_ai_chatbot", branch: "main"
# gem "neuron_ai_chatbot", path: "../neuron_ai_chatbot"
```

## Configure in three lines (then read the full guide)

1. Define a frozen **`api_knowledge`** array (allowed endpoints for the LLM).  
2. **`config/initializers/neuron_ai_chatbot.rb`:** `NeuronAiChatbot.setup { |c| c.api_knowledge = YOUR_CATALOG }` inside `Rails.application.config.to_prepare`.  
3. **`config/routes.rb`:** `mount NeuronAiChatbot::Engine, at: "/"`

Set **`OLLAMA_URL`**, **`OLLAMA_MODEL`**, **`API_EXECUTOR_BASE_URL`**, **`API_EMAIL`**, **`API_PASSWORD`** in your environment (or assign them in `setup`). For the **full** narrative (architecture, sequence diagrams, file index, troubleshooting), read **[docs/NEURON_AI_CHATBOT.md](docs/NEURON_AI_CHATBOT.md)**; for install-focused steps, **[docs/INSTALLATION.md](docs/INSTALLATION.md)**.

## Security

The engine **does not** add authentication. Protect **`/chat`** and **`/api/v1/chat`** in production (Devise, Doorkeeper, reverse proxy, etc.).

## License

MIT — see [MIT-LICENSE](MIT-LICENSE).

## Maintainer note

Replace placeholder **GitHub** URLs in `neuron_ai_chatbot.gemspec` before publishing your fork.

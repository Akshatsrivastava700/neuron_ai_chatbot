# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-04-23

### Added

- Initial public packaging: mountable `NeuronAiChatbot::Engine` with `GET/POST /chat` and `POST /api/v1/chat`.
- `NeuronAiChatbot::LocalAiService` (Ollama JSON intent), `ApiIntentValidator`, `ApiExecutor`, `ResponseProcessor`.
- Configuration via `NeuronAiChatbot.setup` and environment variables, with lazy `ENV` reads so dotenv loads before first access.

[0.1.0]: https://github.com/neuron-ai-chatbot/neuron_ai_chatbot/releases/tag/v0.1.0

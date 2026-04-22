# Quick checklist

For the **full** reference (setup + architecture + operations + troubleshooting), see **[NEURON_AI_CHATBOT.md](./NEURON_AI_CHATBOT.md)**.  
For an **install-focused** walkthrough, see **[INSTALLATION.md](./INSTALLATION.md)**.

Summary:

1. `gem "neuron_ai_chatbot"` → `bundle install`
2. Define `api_knowledge` (frozen array of endpoint hashes)
3. `Rails.application.config.to_prepare { NeuronAiChatbot.setup { |c| c.api_knowledge = ... } }`
4. `mount NeuronAiChatbot::Engine, at: "/"` in `routes.rb`
5. Set `OLLAMA_*` and `API_EXECUTOR_*` / `API_EMAIL` / `API_PASSWORD`
6. Protect `/chat` and `/api/v1/chat` in production

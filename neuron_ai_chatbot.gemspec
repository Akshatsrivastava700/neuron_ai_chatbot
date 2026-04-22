# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)
require "neuron_ai_chatbot/version"

Gem::Specification.new do |spec|
  spec.name        = "neuron_ai_chatbot"
  spec.version     = NeuronAiChatbot::VERSION
  spec.authors     = ["Neuron AI Chatbot contributors"]
  spec.email       = ["opensource@example.com"]
  spec.summary     = "Neuron_AI_Chatbot — mountable Rails engine for natural-language API routing via Ollama"
  spec.description = <<~DESC.strip
    Mountable Rails::Engine: plain-language chat → Ollama (JSON intent) → your HTTP JSON API.
    Ships a small web UI (GET/POST /chat) and a machine endpoint (POST /api/v1/chat).
    Configure api_knowledge, Ollama URL/model, and API executor credentials in the host app.
  DESC
  spec.license     = "MIT"
  spec.homepage     = "https://github.com/neuron-ai-chatbot/neuron_ai_chatbot"

  spec.metadata = {
    "bug_tracker_uri"   => "https://github.com/neuron-ai-chatbot/neuron_ai_chatbot/issues",
    "changelog_uri"     => "https://github.com/neuron-ai-chatbot/neuron_ai_chatbot/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://github.com/neuron-ai-chatbot/neuron_ai_chatbot#readme",
    "source_code_uri"   => "https://github.com/neuron-ai-chatbot/neuron_ai_chatbot",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir.chdir(__dir__) do
    paths = []
    paths += Dir["app/**/*"].select { |f| File.file?(f) }
    paths += Dir["config/**/*"].select { |f| File.file?(f) }
    paths += Dir["lib/**/*"].select { |f| File.file?(f) }
    paths += Dir["docs/**/*"].select { |f| File.file?(f) }
    paths += %w[CHANGELOG.md README.md MIT-LICENSE Rakefile Gemfile]
    paths.uniq
  end

  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7"

  spec.add_dependency "rails", ">= 6.1"
  spec.add_dependency "httparty", "~> 0.21"

  spec.add_development_dependency "rake", ">= 12.0"
end

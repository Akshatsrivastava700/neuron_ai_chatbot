# frozen_string_literal: true

require "neuron_ai_chatbot/version"
require "neuron_ai_chatbot/engine"

module NeuronAiChatbot
  mattr_accessor :api_knowledge, default: []

  # Do not read ENV in `default:` at require time — dotenv often loads after the gem, so values
  # would freeze to defaults. These accessors resolve ENV on each read until explicitly set.
  mattr_accessor :normalize_country
  mattr_accessor :param_transform
  mattr_accessor :integration_rails_app

  mattr_accessor :additional_prompt_rules, default: ""

  mattr_accessor :max_endpoints_in_prompt, default: 5

  @ollama_url_configured = false
  @ollama_model_configured = false
  @api_executor_base_url_configured = false
  @api_executor_http_timeout_configured = false
  @api_email_configured = false
  @api_password_configured = false

  class << self
    def ollama_url
      return @ollama_url if @ollama_url_configured

      ENV.fetch("OLLAMA_URL", "http://localhost:11434/api/generate")
    end

    def ollama_url=(value)
      @ollama_url_configured = true
      @ollama_url = value
    end

    def ollama_model
      return @ollama_model if @ollama_model_configured

      ENV.fetch("OLLAMA_MODEL", "mistral")
    end

    def ollama_model=(value)
      @ollama_model_configured = true
      @ollama_model = value
    end

    def api_executor_base_url
      return @api_executor_base_url if @api_executor_base_url_configured

      ENV.fetch("API_EXECUTOR_BASE_URL", "http://localhost:3000/api/v1")
    end

    def api_executor_base_url=(value)
      @api_executor_base_url_configured = true
      @api_executor_base_url = value
    end

    def api_executor_http_timeout
      return @api_executor_http_timeout if @api_executor_http_timeout_configured

      Integer(ENV["API_EXECUTOR_HTTP_TIMEOUT"], exception: false) || 360
    end

    def api_executor_http_timeout=(value)
      @api_executor_http_timeout_configured = true
      @api_executor_http_timeout = value
    end

    def api_email
      return @api_email if @api_email_configured

      ENV["API_EMAIL"]
    end

    def api_email=(value)
      @api_email_configured = true
      @api_email = value
    end

    def api_password
      return @api_password if @api_password_configured

      ENV["API_PASSWORD"]
    end

    def api_password=(value)
      @api_password_configured = true
      @api_password = value
    end
  end

  def self.setup
    yield self
  end

  def self.api_knowledge_array
    Array(api_knowledge)
  end
end

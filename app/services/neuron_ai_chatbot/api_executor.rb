# frozen_string_literal: true

module NeuronAiChatbot
  class ApiExecutor
    SUPPORTED_HTTP_METHODS = %w(GET POST PUT PATCH DELETE).freeze

    def self.call(ai_output)
      endpoint = ai_output["endpoint"].to_s.sub(/\A(GET|POST|PUT|PATCH|DELETE)\s+/i, "")
      method   = ai_output["method"].to_s.upcase
      params   = (ai_output["params"] || {}).stringify_keys

      return error_response(400, "Endpoint is required.") if endpoint.strip.blank?
      return error_response(400, "Unsupported HTTP method: #{method}") unless method.in?(SUPPORTED_HTTP_METHODS)

      validation = ApiIntentValidator.validate(ai_output)
      return validation if validation

      params = apply_param_transform(params)
      params = normalize_country_param(params)

      endpoint = endpoint.gsub("{id}", params.delete("id").to_s) if endpoint.include?("{id}")

      base_url = NeuronAiChatbot.api_executor_base_url.to_s.chomp("/")
      url = "#{base_url}#{endpoint}"

      if Rails.env.development? && base_url.include?("localhost")
        return in_process_request(method, url, params)
      end

      options = {
        basic_auth: {
          username: NeuronAiChatbot.api_email || ENV.fetch("API_EMAIL"),
          password: NeuronAiChatbot.api_password || ENV.fetch("API_PASSWORD")
        },
        headers: { "Content-Type" => "application/json" },
        timeout: NeuronAiChatbot.api_executor_http_timeout.to_i
      }

      if method == "GET"
        options[:query] = params
      else
        options[:body] = params.to_json
      end

      response = HTTParty.send(method.downcase, url, options)
      { status: response.code.to_i, body: parse_json(response.body) }
    rescue Timeout::Error, Net::OpenTimeout, Net::ReadTimeout
      error_response(504, "API request timed out.")
    rescue StandardError => e
      error_response(502, "API request failed: #{e.message}")
    end

    def self.apply_param_transform(params)
      t = NeuronAiChatbot.param_transform
      return params unless t

      out = t.call(params.deep_dup)
      out.is_a?(Hash) ? out.stringify_keys : params
    end

    def self.normalize_country_param(params)
      nc = NeuronAiChatbot.normalize_country
      return params unless nc && params["country"].present?

      params = params.dup
      params["country"] = nc.call(params["country"])
      params
    end

    def self.in_process_request(method, url, params)
      require "action_dispatch/testing/integration"
      app = NeuronAiChatbot.integration_rails_app || Rails.application
      session = ActionDispatch::Integration::Session.new(app)
      email = NeuronAiChatbot.api_email || ENV.fetch("API_EMAIL")
      pass  = NeuronAiChatbot.api_password || ENV.fetch("API_PASSWORD")
      headers = {
        "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(email, pass),
        "Accept"        => "application/json"
      }

      if method == "GET"
        session.get(url, params: params, headers: headers)
      elsif method == "DELETE"
        session.delete(url, params: params, headers: headers)
      else
        session.send(method.downcase, url, params: params, headers: headers, as: :json)
      end

      { status: session.response.status, body: parse_json(session.response.body) }
    rescue Timeout::Error, Net::OpenTimeout, Net::ReadTimeout
      error_response(504, "API request timed out.")
    end

    def self.error_response(status, msg)
      { status: status, body: { "error" => msg } }
    end

    def self.parse_json(raw_body)
      return {} if raw_body.to_s.blank?

      JSON.parse(raw_body.to_s)
    rescue JSON::ParserError
      { "raw" => raw_body.to_s.truncate(1000) }
    end
  end
end

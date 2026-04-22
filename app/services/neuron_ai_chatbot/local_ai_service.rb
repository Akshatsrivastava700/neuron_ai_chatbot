# frozen_string_literal: true

module NeuronAiChatbot
  class LocalAiService
    def self.run_chat(user_input)
      ai_output = parse(user_input)
      return [ai_output, nil] if ai_output["error"].present?

      api_response = ApiExecutor.call(ai_output)
      [ai_output, api_response]
    end

    def self.parse(user_input)
      parts = user_input.to_s.split(/\nUser:\s*/)
      last_message = parts.pop.to_s.sub(/\AUser:\s*/, "").strip

      effective_input = if last_message.downcase.match?(/\b(next|page|more)\b/)
                          user_input
                        else
                          "User: #{last_message}"
                        end

      catalog = compact_api_catalog(effective_input)
      prompt = build_prompt(effective_input, catalog)

      body = {
        model:   NeuronAiChatbot.ollama_model,
        prompt:  prompt,
        stream:  false,
        format:  "json",
        options: {
          temperature: 0.0,
          num_predict: 512,
          num_ctx:     2048
        }
      }

      response = HTTParty.post(
        NeuronAiChatbot.ollama_url,
        headers:      { "Content-Type" => "application/json" },
        body:         body.to_json,
        read_timeout: 300,
        open_timeout: 10
      )

      if response.code != 200
        error_msg = response.parsed_response.is_a?(Hash) ? response.parsed_response["error"] : response.body
        return { "error" => "Ollama API Error (#{response.code})", "raw" => error_msg }
      end

      parsed = extract_json(response.parsed_response["response"].to_s)

      return parsed if parsed["error"].present?

      parsed["method"] = parsed["method"].presence || "GET"
      parsed["method"] = parsed["method"].to_s.upcase

      parts = user_input.to_s.split(/\nUser:\s*/)
      last_message = parts.pop.to_s.sub(/\AUser:\s*/, "").strip

      if last_message.downcase.match?(/\b(count|how many)\b/)
        parsed["operation"] = "count"
      else
        parsed["operation"] = parsed["operation"].presence || "list"
      end

      parsed["params"] = parsed["params"].is_a?(Hash) ? parsed["params"] : {}
      parsed
    rescue StandardError => e
      { "error" => "AI model request failed", "raw" => e.message }
    end

    def self.build_prompt(user_input, catalog)
      extra = NeuronAiChatbot.additional_prompt_rules.to_s.strip
      extra_block = extra.present? ? "\n#{extra}\n" : ""

      <<~PROMPT
        Map the user request to one API call. Reply with JSON only:
        {"endpoint":"<path>","method":"GET|POST|PUT|DELETE","params":{},"operation":"list|count"}

        Allowed APIs:
        #{catalog}

        User: #{user_input}

        Rules:
        - Use ONLY the allowed endpoints and exact parameter names.
        - "endpoint" MUST be only the path (e.g. "/resources"). DO NOT include the method in the endpoint field.
        - "method" MUST be exactly the method specified for the chosen endpoint in the Allowed APIs list. Do NOT mix endpoints and methods.
        - If the user asks to "count" or "how many", "operation" MUST be "count". Otherwise, "operation" MUST be "list".
        - Extract relevant filters from the user request and map them to the allowed parameters in "params".
        - params should only include values explicitly mentioned by the user. Do not invent empty strings.
        - If the user asks for the next page, increment the "page" parameter and ensure operation is "list".#{extra_block}
      PROMPT
    end

    def self.compact_api_catalog(user_input)
      catalog = NeuronAiChatbot.api_knowledge_array
      max_n = NeuronAiChatbot.max_endpoints_in_prompt.to_i
      max_n = 5 if max_n <= 0

      parts = user_input.to_s.split(/\nUser:\s*/)
      last_message = parts.pop.to_s.sub(/\AUser:\s*/, "").strip
      prior_history = parts.join(" ")

      stopwords = %w(find get list show me all with the a an and in from of for by)

      last_tokens = last_message.downcase.scan(/[a-z0-9_@.]+/)
      last_meaningful = last_tokens.reject { |t| stopwords.include?(t) || (t.length < 3 && t !~ /^[a-z]{2}$/) }

      prior_tokens = prior_history.downcase.scan(/[a-z0-9_@.]+/)
      prior_meaningful = prior_tokens.reject { |t| stopwords.include?(t) || (t.length < 3 && t !~ /^[a-z]{2}$/) }

      scored = catalog.map do |row|
        text = [row[:name], row[:endpoint], row[:description]].join(" ").downcase

        score = 0
        score += prior_meaningful.count { |t| text.include?(t) } * 1
        score += last_meaningful.count { |t| text.include?(t) } * 5

        score += 10 if last_meaningful.include?("create") && row[:method].to_s.upcase == "POST"
        score += 10 if last_meaningful.include?("update") && row[:method].to_s.upcase == "PUT"
        score += 10 if last_meaningful.include?("delete") && row[:method].to_s.upcase == "DELETE"

        [row, score]
      end

      top_rows = scored.sort_by { |_, score| -score }.map(&:first).first(max_n)

      top_rows.map do |row|
        req = Array(row[:required]).any? ? ", Required: [#{Array(row[:required]).join(', ')}]" : ""
        opt_params = row[:params] || row[:optional]
        opt = Array(opt_params).any? ? ", Optional: [#{Array(opt_params).join(', ')}]" : ""
        desc = row[:description].present? ? ". Description: #{row[:description]}" : ""
        "- endpoint: \"#{row[:endpoint]}\", method: \"#{row[:method].to_s.upcase}\"#{req}#{opt}#{desc}"
      end.join("\n")
    end

    def self.extract_json(text)
      clean_text = text.gsub(/\A```json\s+|\s+```\z/m, "").strip
      JSON.parse(clean_text)
    rescue JSON::ParserError
      { "error" => "Invalid AI output", "raw" => text }
    end
  end
end

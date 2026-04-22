# frozen_string_literal: true

module NeuronAiChatbot
  class ApiIntentValidator
    def self.validate(ai_output, catalog = nil)
      catalog ||= NeuronAiChatbot.api_knowledge_array
      return nil if catalog.blank?
      return nil if ai_output.is_a?(Hash) && ai_output["error"].present?

      endpoint = normalize_endpoint(ai_output["endpoint"])
      method   = ai_output["method"].to_s.upcase
      params   = (ai_output["params"] || {}).stringify_keys.dup

      match = find_catalog_row(catalog, endpoint, method)
      return nil if match.nil?

      template_path = match[:endpoint].to_s
      effective_params = merge_path_params(template_path, endpoint, params)

      required = Array(match[:required]).map(&:to_s)
      missing = required.reject { |k| present_param?(effective_params, k) }

      return nil if missing.empty?

      {
        status: 400,
        body:   {
          "error"            => "Missing required parameters for #{method} #{endpoint}.",
          "missing_required" => missing,
          "required_fields"  => required
        }
      }
    end

    def self.find_catalog_row(catalog, request_path, method)
      catalog.find do |row|
        row[:method].to_s.upcase == method && path_matches_template?(request_path, row[:endpoint].to_s)
      end
    end

    def self.path_matches_template?(request_path, template_path)
      return true if request_path == template_path

      return false unless template_path.include?("{id}")

      req_segments = request_path.split("/")
      tpl_segments = template_path.split("/")
      return false unless req_segments.length == tpl_segments.length

      req_segments.zip(tpl_segments).all? do |req_seg, tpl_seg|
        tpl_seg == "{id}" ? req_seg.match?(/\A\d+\z/) : req_seg == tpl_seg
      end
    end

    def self.merge_path_params(template_path, request_path, params)
      return params unless template_path.include?("{id}")

      out = params.dup
      return out if present_param?(out, "id")

      req_segments = request_path.split("/")
      tpl_segments = template_path.split("/")
      tpl_segments.each_with_index do |seg, i|
        if seg == "{id}" && req_segments[i].to_s.match?(/\A\d+\z/)
          out["id"] = req_segments[i]
          break
        end
      end
      out
    end

    def self.normalize_endpoint(ep)
      ep.to_s.sub(/\A(GET|POST|PUT|PATCH|DELETE)\s+/i, "").strip
    end

    def self.present_param?(params, key)
      val = params[key]
      return false if val.nil?
      return false if val.is_a?(String) && val.strip.blank?

      true
    end
  end
end

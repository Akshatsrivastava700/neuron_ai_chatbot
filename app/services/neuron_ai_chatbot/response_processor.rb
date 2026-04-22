# frozen_string_literal: true

module NeuronAiChatbot
  class ResponseProcessor
    HTML_RESPONSE_PATTERN = /<!DOCTYPE html|<html\b/i.freeze
    STATUS_ERROR_MESSAGES = {
      400 => "The API request was invalid.",
      401 => "Authentication failed for the API request.",
      403 => "The API request is not authorized.",
      404 => "The requested resource was not found.",
      408 => "The API request timed out.",
      422 => "The API could not process the request parameters.",
      429 => "The API rate limit was exceeded.",
      500 => "The API server encountered an internal error.",
      502 => "The upstream API returned an invalid response.",
      503 => "The API service is unavailable.",
      504 => "The API request timed out before completion."
    }.freeze

    def self.process(ai_output, api_response)
      api_response ||= {}
      status = api_response[:status].to_i
      body = api_response[:body]

      unless status.between?(200, 299)
        return {
          error:   true,
          status:  status,
          message: error_message(status, body),
          details: normalized_error_details(status, body)
        }
      end

      operation = ai_output["operation"] || "list"

      data = body

      case operation
      when "count"
        count = if data.is_a?(Hash) && data.dig("pagination", "total_entries")
          data["pagination"]["total_entries"]
        else
          data.is_a?(Hash) ? data["collection"]&.size : 0
        end
        { result: count || 0 }
      else
        data || {}
      end
    end

    def self.error_message(status, body)
      return body.truncate(500) if body.is_a?(String)
      return body.map(&:to_s).join(", ").truncate(500) if body.is_a?(Array)
      return status_fallback_message(status) unless body.is_a?(Hash)

      return body["error"].to_s if body["error"].present?
      return body["message"].to_s if body["message"].present?
      return format_errors_hash(body["errors"]) if body["errors"].is_a?(Hash)
      return body["errors"].to_s if body["errors"].present?
      if body["raw"].present?
        return status_fallback_message(status) if html_body?(body["raw"])

        return body["raw"].to_s.truncate(500)
      end

      status_fallback_message(status)
    end

    def self.format_errors_hash(errors)
      errors.map { |k, v| "#{k}: #{Array(v).join(', ')}" }.join("; ")
    end

    def self.status_fallback_message(status)
      STATUS_ERROR_MESSAGES[status.to_i] || "The API request did not succeed."
    end

    def self.normalized_error_details(status, body)
      return sanitized_hash_details(status, body) if body.is_a?(Hash)
      return { "raw" => body.truncate(1000) } if body.is_a?(String) && body.present?

      {
        "error"  => status_fallback_message(status),
        "status" => status.to_i
      }
    end

    def self.sanitized_hash_details(status, body)
      details = body.deep_dup

      if details["raw"].is_a?(String)
        if html_body?(details["raw"])
          details.delete("raw")
          details["non_json_body"] = true
          details["error"] ||= status_fallback_message(status)
        else
          details["raw"] = details["raw"].truncate(1000)
        end
      end

      return details if details.present?

      {
        "error"  => status_fallback_message(status),
        "status" => status.to_i
      }
    end

    def self.html_body?(text)
      text.to_s.match?(HTML_RESPONSE_PATTERN)
    end
  end
end

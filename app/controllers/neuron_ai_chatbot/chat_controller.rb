# frozen_string_literal: true

module NeuronAiChatbot
  class ChatController < ApplicationController
    layout false

    def index
      # Renders neuron_ai_chatbot/chat/index
    end

    def create
      user_input = params[:message]

      if user_input.blank?
        render json: { success: false, message: "Message cannot be blank" }
        return
      end

      ai_output, api_response = LocalAiService.run_chat(user_input)

      if ai_output.is_a?(Hash) && ai_output["error"].present?
        render json: { success: false, message: "AI Parsing Failed: #{ai_output['error']}", data: ai_output }
        return
      end

      final_response = ResponseProcessor.process(ai_output, api_response || {})

      operation = ai_output["operation"]

      message =
        case operation
        when "count"
          count = final_response[:result] || 0
          "There are #{count} matching records."
        else
          base_msg = "Action completed successfully."

          body = api_response[:body] || {}
          if body.is_a?(Hash) && body["pagination"].is_a?(Hash)
            total_pages = body["pagination"]["total_pages"].to_i
            current_page = (ai_output.dig("params", "page") || ai_output.dig("params", "page_number") || 1).to_i

            if total_pages > 1 && current_page < total_pages
              base_msg += " Showing page #{current_page} of #{total_pages}. Would you like to see the next page?"
            end
          end

          base_msg
        end

      render json: {
        success: true,
        message: message,
        data:    final_response[:details] || final_response[:result] || api_response[:body],
        debug:   ai_output
      }
    end
  end
end

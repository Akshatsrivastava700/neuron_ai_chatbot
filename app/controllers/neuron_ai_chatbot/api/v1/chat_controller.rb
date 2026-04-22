# frozen_string_literal: true

module NeuronAiChatbot
  module Api
    module V1
      class ChatController < ActionController::API
        def create
          user_input = params[:message]

          return render json: { error: "Message cannot be blank" }, status: :bad_request if user_input.blank?

          ai_output, api_response = LocalAiService.run_chat(user_input)
          return render json: format_ai_parse_failure(user_input, ai_output), status: :unprocessable_entity if ai_parse_error?(ai_output)

          final_response = ResponseProcessor.process(ai_output, api_response || {})

          render json:   format_response(user_input, ai_output, final_response, api_response),
                 status: chat_http_status(ai_output, api_response, final_response)
        end

        private

        def format_ai_parse_failure(user_input, ai_output)
          raw = ai_output.is_a?(Hash) ? (ai_output["raw"] || ai_output[:raw]) : nil

          {
            success:    false,
            user_input: user_input,
            message:    "The assistant did not return valid JSON for an API action.",
            data:       { raw: raw },
            debug:      ai_output
          }
        end

        def chat_http_status(_ai_output, _api_response, final_response)
          return :ok unless final_response[:error]

          code = final_response[:status].to_i
          return code if code.between?(400, 599)

          :bad_gateway
        end

        def format_response(user_input, ai_output, final_response, api_response)
          if final_response[:error]
            return {
              success:    false,
              user_input: user_input,
              message:    final_response[:message],
              data:       final_response[:details],
              api_status: final_response[:status],
              debug:      ai_output
            }
          end

          operation = ai_output["operation"]

          message =
            case operation
            when "count"
              count = final_response[:result] || 0
              "There are #{count} matching records."
            else
              base_msg = success_message(api_response)

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

          {
            success:    true,
            user_input: user_input,
            message:    message,
            data:       final_response,
            api_status: api_response[:status],
            debug:      ai_output
          }
        end

        def success_message(api_response)
          case api_response[:status].to_i
          when 201
            "Resource was created successfully."
          when 204
            "Request succeeded (no response body)."
          else
            "Here are the results for your query."
          end
        end

        def ai_parse_error?(ai_output)
          return false unless ai_output.is_a?(Hash)

          ai_output["error"].present? || ai_output[:error].present?
        end
      end
    end
  end
end

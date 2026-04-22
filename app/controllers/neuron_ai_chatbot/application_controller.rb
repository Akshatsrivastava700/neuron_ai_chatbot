# frozen_string_literal: true

module NeuronAiChatbot
  class ApplicationController < ActionController::Base
    include NeuronAiChatbot::Engine.routes.url_helpers

    protect_from_forgery with: :exception
  end
end

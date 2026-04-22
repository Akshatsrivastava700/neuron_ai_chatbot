# frozen_string_literal: true

NeuronAiChatbot::Engine.routes.draw do
  get  "chat", to: "chat#index"
  post "chat", to: "chat#create"

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      post "chat", to: "chat#create"
    end
  end
end

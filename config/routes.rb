# frozen_string_literal: true

Rails.application.routes.draw do
  post "exports", to: "exports#gerar_csv"
end

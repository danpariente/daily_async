Rails.application.routes.draw do
  root "pages#recorder"            # grabador (página pública para los devs)
  resources :clips,   only: %i[create]
  resources :dailies, only: %i[index]   # tablero del lead

  # Health check usado por kamal-proxy para verificar que el contenedor está vivo.
  get "up" => "rails/health#show", as: :rails_health_check
end

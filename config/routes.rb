Rails.application.routes.draw do
  root "pages#recorder"            # grabador (página pública para los devs)
  resources :clips,   only: %i[create]
  resources :dailies, only: %i[index] do  # tablero del lead
    get :week, on: :collection            # /dailies/week — últimos 5 días
  end

  # Health check usado por kamal-proxy para verificar que el contenedor está vivo.
  get "up" => "rails/health#show", as: :rails_health_check
end
